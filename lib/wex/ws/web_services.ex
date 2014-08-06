defmodule Wex.WS.WebServices do

  @behaviour :cowboy_http_handler
  @behaviour :cowboy_websocket_handler

  use Jazz

  require Logger


  # HTTP side

  def init(_type, _req, _opts) do
    Logger.info "ws init"
    { :upgrade, :protocol, :cowboy_websocket }
  end

  def handle(req, _state) do
    { :ok, req } = :cowboy_req.reply(501, [], [], req)
    { :shutdown, req, :undefined }
  end

  def terminate(_reason, _req, _state), do: :ok


  # WS side

  @protocol_header "sec-websocket-protocol"

  def websocket_init(_any, req, dispatcher) do
    Logger.metadata in: "ws      "
    Logger.info "ws secondary init"
    req = case :cowboy_req.parse_header(@protocol_header, req) do
            {:ok, :undefined, req} ->
              req
            {:ok, [protocol|_], req} ->
              :cowboy_req.set_resp_header("@protocol_header", protocol, req)
          end

    # now we have a session, start up the handlers
    { :ok, _    } = Wex.Handlers.HelpSender.start_link(self)
    { :ok, eval } = Wex.Handlers.Eval.start_link(self)

    { :ok, req, %{dispatcher: dispatcher, eval: eval} }
  end

  # Dispatch generic message to the handler
  def websocket_handle({:text, msg}, req, state = %{ dispatcher: dispatcher } ) do
    Logger.info "Received #{inspect msg}"
    { :ok, object } = JSON.decode(msg, keys: :atoms)
    Wex.Dispatcher.dispatch(dispatcher, %{msg: object})
    { :ok, req, state }
  end

  # Here's the server sending to the browser...
  def websocket_info(info = %{type: type, text: text}, req, state) do
    Logger.info "Received info #{inspect info}"
    msg = JSON.encode! %{ type: Atom.to_string(type), text: text }
    { :reply, {:text, msg}, req, state }
  end

  def websocket_info(info = %{type: type}, req, state) do
    Logger.info "Received info #{inspect info}"
    msg = JSON.encode! %{ type: Atom.to_string(type) }
    { :reply, {:text, msg}, req, state }
  end

  def websocket_terminate(_reason, _req, _state) do
    Logger.info "Received terminate"
    :ok
  end


end