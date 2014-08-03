defmodule Wex.Handlers.Eval do

  @moduledoc """
  Handle an incoming eval request from the browser. We can respond with:


  """

  use     GenServer
  require Logger
  alias   Wex.State

  
  @name :handlers_eval

  def start_link(ws) do
    Logger.info "START EVAL"
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

    # capture stdout
    { :ok, interceptor } = Wex.InterceptIO.start_link({:stdout, ws})
    :erlang.group_leader(interceptor, self)

    # and standard error
    unless stderr = Process.whereis(:standard_error) do
      raise "could not find standard error"
    end

    Process.unregister(:standard_error)
    { :ok, interceptor } = Wex.InterceptIO.start_link({:stderr, ws})
    Process.register(interceptor, :standard_error)

    {:ok, create_state(ws) }
  end
  

  def handle_cast({:eval, msg}, state) do
    eval(msg, state)
  end




  defp create_state(ws) do
    env = :elixir.env_for_eval(file: "wex", delegate_locals_to: Wex.Helpers)
    binding = []
    {_, _, env, scope} = :elixir.eval('require Wex.Helpers', [], env)
    %Wex.State{binding: binding, scope: scope, env: env, ws: ws}
  end

  def eval(code, state = %State{ws: ws}) do
    code = state.partial_input <> code
    case Code.string_to_quoted(code, [line: 99, file: "wex"]) do
      {:ok, forms} ->
        {result, new_binding, env, scope} =
          :elixir.eval_forms(forms, state.binding, state.env, state.scope)
        
         eval_ok_response(ws, inspect(result))

        { :noreply, %{state | env:           env,
                              scope:         scope, 
                              binding:       new_binding, 
                              partial_input: "" }}


      # Update config.cache so that IEx continues to add new input to
      # the unfinished expression in `code`
      # %{config | cache: code} # 
      {:error, {_line, _error, ""}} ->
        eval_partial_response(ws)
        { :noreply, %{state | partial_input: code} }

      # Encountered malformed expression

      {:error, {line, error, token}} ->
        eval_error_response(ws, line, error, token)
        { :noreply, state }
    end
  end

  defp eval_ok_response(ws, result) do
    send ws, {:eval_ok, result}
    Logger.info "OK response"
  end

  defp eval_partial_response(ws) do
    send ws, {:eval_partial}
    Logger.info "partial response"
  end

  defp eval_error_response(ws, line, error, token) do
    send ws, {:eval_error, line, error, token}
    Logger.info "error response"
  end

end