defmodule Wex do
  use Application
  require Logger

  def start, do: start([], [])

  def start(_,_) do
    Logger.add_translator {CowboyTranslator, :translate}    
    Logger.info "Starting"

    { :ok, dispatcher_pid } = Wex.Dispatcher.start_link()

    Wex.WSInterface.start_web_server(dispatcher_pid)

    Supervisor.start_link([], strategy: :one_for_one)
  end

end
