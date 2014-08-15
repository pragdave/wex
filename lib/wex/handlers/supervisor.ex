defmodule Wex.Handlers.Supervisor do

  use Supervisor
  require Logger

  def start_link(ws) do
    Supervisor.start_link(__MODULE__, ws)
  end

  def init(ws) do
    children = [
      worker(Wex.Handlers.Eval,       [ws]),
      worker(Wex.Handlers.HelpSender, [ws])
    ]
    supervise(children, strategy: :one_for_one, name: :handlers_supervisor)
  end
end
