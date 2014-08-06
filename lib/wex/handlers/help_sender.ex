defmodule Wex.Handlers.HelpSender do

  @moduledoc """
  We exist because we need to keep the pid of the web socket interface.
  """

  use     GenServer
  require Logger
  
  @name :handlers_help_sender

  def start_link(ws) do
    Logger.info "START HelpSender"
    GenServer.start_link(__MODULE__, ws, name: @name)
  end

  @doc """
  Send some help text to the client
  """
  def send_help(help_text) do
    Logger.info "send help"
    GenServer.cast(@name, {:send_help, help_text})
  end


  ##################
  # Implementation #
  ##################

  def init(ws) do
    {:ok, ws }
  end
  

  def handle_cast({:send_help, %{help: help_text}}, ws) do
    Logger.info "sending it"
    send ws, %{type: :help, text: help_text }
    {:noreply, ws}
  end

end