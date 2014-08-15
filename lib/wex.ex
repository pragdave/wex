defmodule Wex do
  use Application
  require Logger

  def start, do: start([], [])

  def start(_,_) do
    Logger.add_translator {CowboyTranslator, :translate}
    Logger.info "Starting"
    import Supervisor.Spec

    children = [
      worker(Wex.Dispatcher, []),
      Wex.WSInterface.child_spec
    ]

    Supervisor.start_link(children, strategy: :one_for_all)
  end

end
