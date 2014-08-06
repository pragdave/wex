defmodule Wex.Dispatcher do
  use GenServer
  require Logger

  @name :dispatcher

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: @name)
  end

  @doc """
  Return our pid
  """
  def pid do
    Process.whereis(@name) || raise("Can't find pid of dispatcher")
  end

  @doc """
  Add `handler` to the list of handlers for `msg_type`
  """
  def register_handler(msg_type, handler) do
    GenServer.call(@name, {:register_handler, msg_type, handler})
  end

  @doc """
  Dispatch a message received from the client to the registered
  handlers.
  """
  def dispatch(pid, incoming) do
    GenServer.call(pid, {:dispatch, incoming})
  end

  ##################
  # Implementation #
  ##################

  def init(_args) do
    Logger.metadata in: "dispatch"
    { :ok, _handlers = %{} }
  end

  def handle_call({:register_handler, msg_type, handler}, _from, handlers) do
    handlers = Dict.update(handlers, msg_type, [handler], &[handler|&1])
    {:reply, :ok, handlers}
  end

  def handle_call({:dispatch, %{msg: msg}}, _, handlers) do
    Logger.info "dispatch #{inspect msg}"
    Logger.info inspect(handlers)
    dispatch_to(handlers[msg[:msgtype]], msg)
    {:reply, :ok, handlers }
  end


  ###########
  # Helpers #
  ###########

  defp dispatch_to(nil, msg) do
    Logger.error("Unknown message type from browser: #{inspect msg[:msgtype]}")
  end

  defp dispatch_to(handlers, msg) do
    for handler <- handlers do
      apply(handler, :handle, [ msg ])
    end
  end

end