defmodule Wex.Handlers.Eval do

  @moduledoc """
  Handle an incoming eval request from the browser.
  """

  use     GenServer
  alias   Wex.State
  
  @name :handle_eval

  require Logger

  def start_link(ws) do
    result = GenServer.start_link(__MODULE__, ws, name: @name)
    Wex.Dispatcher.register_handler("eval",    __MODULE__)
    Wex.Dispatcher.register_handler("compile", __MODULE__)
    result
  end


  @doc """
  This is the dispatcher callback
  """
  def handle(%{msgtype: "eval", text: text_to_eval}) do
    GenServer.cast(@name, {:eval, text_to_eval})
  end

  def handle(%{msgtype: "compile", text: code}) do
    GenServer.cast(@name, {:compile, code})
  end


  ##################
  # Implementation #
  ##################


  # We arrange for STDOUT/STDERR to be sent on to the browser
  def init(ws) do
    
    Logger.metadata in: "eval    "
    Logger.info "starting"
    
    {old_stdout, old_stderr} = start_io_interceptors(ws)
    {:ok, create_state(ws, old_stdout, old_stderr)}
  end

  def handle_cast({:eval, msg}, state) do
    Logger.info("received cast #{inspect msg}")
    Logger.info "calling eval"
    result = eval(msg, state)
    Logger.info("back from eval")
    result
  end


  def handle_cast({:compile, msg}, state) do
    Logger.info("received cast #{inspect msg}")
    Logger.info "calling compiling"
    result = compile(msg, state)
    Logger.info("back from compile")
    result
  end

  def terminate(_reason, %{stderr: stderr, stdout: stdout}) do
    Logger.info "terminate eval"
    IO.close(:stdout)
    :erlang.group_leader(stdout)
    
    IO.close(stderr)
    try do
      Process.unregister(:standard_error)
    rescue
      ArgumentError -> nil
    end
    Process.register(stderr, :standard_error)
  end


  defp create_state(ws, old_stdout, old_stderr) do
    env = :elixir.env_for_eval(file: "wex sandbox", delegate_locals_to: Wex.Helpers)
    binding = []
    {_, _, env, scope} = :elixir.eval('require Wex.Helpers', [], env)
    %Wex.State{binding: binding, 
               scope:   scope, 
               env:     env, 
               ws:      ws, 
               stdout:  old_stdout, 
               stderr:  old_stderr}
  end



  def eval(code, state = %State{ws: ws}) do
    code = state.partial_input <> code
    Logger.info "evaluate #{inspect code}"
    case Code.string_to_quoted(code, [line: 1, file: "wex"]) do
      {:ok, forms} ->
        Logger.info "Parsed OK. Evaling..."
        try do
          {result, new_binding, env, scope} =
            :elixir.eval_forms(forms, state.binding, state.env, state.scope)
        
          Logger.info("result = #{inspect result}")
          eval_ok_response(ws, result)

          { :noreply, %{state | env:           env,
                                scope:         scope, 
                                binding:       new_binding, 
                                partial_input: "" }}

        catch kind, error ->
          eval_error_response(ws, format_exception(kind, error, System.stacktrace))
          { :noreply, %{state | partial_input: "" } }
        end


      # Update config.cache so that IEx continues to add new input to
      # the unfinished expression in `code`
      # %{config | cache: code} # 
      {:error, {_line, _error, ""}} ->
        Logger.info "Continuation line"
        eval_partial_response(ws)
        { :noreply, %{state | partial_input: code} }

      # Encountered malformed expression

      {:error, {line, error, token}} ->
        Logger.info "error: #{inspect [line, error, token]}"
        eval_error_response(ws, "#{error} #{token}")
        { :noreply, %{state | partial_input: "" } }

    end
  end


  def compile(code, state = %State{ws: ws}) do
    Logger.info "compile #{inspect code}"

    old_options = Code.compiler_options
    Code.compiler_options([ignore_module_conflict: true, docs: true])

    Wex.InterceptIO.compiling(:standard_output, true)
    Wex.InterceptIO.compiling(:standard_error, true)

    file_name = "wex sandbox"

    response = case Code.string_to_quoted(code, [line: 1, file: file_name]) do
      {:ok, forms} ->
        Logger.info "Parsed OK. Evaling..."
        try do
          {result, new_binding, env, scope} =
            :elixir.eval_forms(forms, state.binding, state.env, state.scope)
        
          Logger.info("result = #{inspect result}")
          eval_ok_response(ws, compile_massage(result))

          { :noreply, %{state | env:           env,
                                scope:         scope, 
                                binding:       new_binding, 
                                partial_input: "" }}

        catch kind, error ->
          Logger.warn("#{inspect kind}: #{inspect error}")
          Logger.warn(inspect System.stacktrace)
          compile_error_response(ws, [
               format_compile_exception(kind, error, System.stacktrace, file_name, 0)])
          { :noreply, %{state | partial_input: "" } }
        end


      {:error, {line, error, token}} ->
        Logger.info "error: #{inspect [line, error, token]}"
        compile_error_response(ws, [ %{error: error_with_token(error, token),
                                       file:  file_name, 
                                       line:  line}
                              ])

        { :noreply, %{state | partial_input: "" } }

    end

    Wex.InterceptIO.compiling(:stdout, false)
    Wex.InterceptIO.compiling(:stderr, false)

    Code.compiler_options(old_options)

    response
  end


  # help responses contain formatting...
  defp eval_ok_response(ws,  %{ help: body }) do
    send ws, %{type: :help, text: body }
    Logger.info "help response"
  end

  defp eval_ok_response(ws, %{ stderr: body }) do
    send ws, %{type: :stderr, text: body }
    Logger.info "stderr response"
  end

  defp eval_ok_response(ws, result) do
    send ws, %{ type: :eval_ok, text: ValueTree.ToTree.to_tree(result)}
    Logger.info "OK response"
  end

  defp eval_partial_response(ws) do
    send ws, %{type: :eval_partial}
    Logger.info "partial response"
  end

  defp eval_error_response(ws, error) do
    send ws, %{type: :stderr, text: error}
    Logger.info "error response"
  end

  defp compile_error_response(ws, error) do
    send ws, %{type: :compile_stderr, text: error}
    Logger.info "compile error response"
  end


  defp format_exception(kind, reason, stacktrace) do
    {reason, stacktrace} = normalize_exception(kind, reason, stacktrace)

    Exception.format_banner(kind, reason, stacktrace)
  end

  defp normalize_exception(:error, :undef, [{Wex.Helpers, fun, arity, _}|t]) do
    {%RuntimeError{message: "undefined function: #{format_function(fun, arity)}"}, t}
  end

  defp normalize_exception(_kind, reason, stacktrace) do
    {reason, stacktrace}
  end


  defp format_compile_exception(kind, reason, stacktrace, file, line) do
    {reason, stacktrace, token} = normalize_compile_exception(kind, reason, stacktrace)

    text = Exception.format_banner(kind, reason, stacktrace)
    %{ line: line, file: file, error: text, token: token }
  end

  defp normalize_compile_exception(:error, :undef, [{Wex.Helpers, fun, arity, _}|t]) do
    func = format_function(fun, arity)
    {%RuntimeError{message: "undefined function: #{func}"}, t, func}
  end

  defp normalize_compile_exception(_kind, reason, stacktrace) do
    {reason, stacktrace, ""}
  end

  defp format_function(fun, arity) do
    cond do
      is_list(arity) ->
        "#{fun}/#{length(arity)}"
      true ->
        "#{fun}/#{arity}"
    end
  end

  defp error_with_token(error, ""),    do: error
  defp error_with_token(error, token), do: "#{error} “#{token}”"

  defp compile_massage({:module, name, code, value})
  when is_binary(code)
  do
    "defmodule #{name} → #{inspect value}"
  end

  defp compile_massage(anything_else), do: anything_else

  ###################
  # IO Interception #
  ###################

  defp start_io_interceptors(ws) do
    import Supervisor.Spec
    Logger.debug "intercepting"
    old_stdout = :erlang.group_leader()

    Logger.debug "old stdout = #{inspect old_stdout}"

    unless old_stderr = Process.whereis(:standard_error) do
      Logger.debug "raising"
#      raise "could not find standard error"
      old_stderr = :standard_error
    end

    Logger.debug "old stderr = #{inspect old_stderr}"

    children = [
      worker(Wex.InterceptIO, [{:stdout, ws}], id: :stdout),
      worker(Wex.InterceptIO, [{:stderr, ws}], id: :stderr),
    ]

    Logger.debug "starting supervisor"

    {:ok, sup} = Supervisor.start_link(children, 
                                       strategy: :one_for_one, 
                                       name: :interceptors)

    Logger.debug inspect(Supervisor.which_children(sup))

    for child <- Supervisor.which_children(sup) do
      capture(child)
    end

    Logger.debug "done intercepting"

    { old_stdout, old_stderr }
  end

  def capture({:stdout, pid, :worker, _}) do
    :erlang.group_leader(pid, self)
  end
    
    # and standard error
  def capture({:stderr, pid, :worker, _}) do
    try do
      Process.unregister(:standard_error)
    rescue
      ArgumentError -> nil
    end
    Process.register(pid, :standard_error)
  end
end
