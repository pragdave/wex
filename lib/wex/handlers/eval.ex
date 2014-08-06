defmodule Wex.Handlers.Eval do

  @moduledoc """
  Handle an incoming eval request from the browser. We can respond with:


  """

  use     GenServer
  alias   Wex.State

  require Logger
  
  @name :handlers_eval

  def start_link(ws) do
    result = GenServer.start_link(__MODULE__, ws, name: @name)
    Wex.Dispatcher.register_handler("eval", __MODULE__)
    result
  end


  @doc """
  This is the dispatcher callback
  """
  def handle(%{msgtype: "eval", text: text_to_eval}) do
    GenServer.cast(@name, {:eval, text_to_eval})
  end


  ##################
  # Implementation #
  ##################

  # We arrange for STDOUT/STDERR to be sent on to the browser
  def init(ws) do
    
    Logger.metadata in: "eval    "

    # capture stdout
    { :ok, interceptor } = Wex.InterceptIO.start_link({:stdout, ws})
    :erlang.group_leader(interceptor, self)
   
    # and standard error
    unless Process.whereis(:standard_error) do
      raise "could not find standard error"
    end
    
    { :ok, interceptor } = Wex.InterceptIO.start_link({:stderr, ws})
    Process.unregister(:standard_error)
    Process.register(interceptor, :standard_error)

    {:ok, create_state(ws)}
  end
  

  def handle_cast({:eval, msg}, state) do
    Logger.info("received cast #{inspect msg}")
    Logger.info "calling eval"
    result = eval(msg, state)
    Logger.info("back from eval")
    result
  end




  defp create_state(ws) do
    env = :elixir.env_for_eval(file: "wex", delegate_locals_to: Wex.Helpers)
    binding = []
    {_, _, env, scope} = :elixir.eval('require Wex.Helpers', [], env)
    %Wex.State{binding: binding, scope: scope, env: env, ws: ws}
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
    send ws, %{ type: :eval_ok, text: inspect(result)}
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

  defp format_function(fun, arity) do
    cond do
      is_list(arity) ->
        "#{fun}/#{length(arity)}"
      true ->
        "#{fun}/#{arity}"
    end
  end

end