defmodule Wex.WS.Rest do

#  @behaviour :cowboy_http_handler
#  @behaviour :cowboy_rest_handler

  use Jazz

  require Logger


  # HTTP side

  def init(_type, _req, _opts) do
    Logger.info "rest init"
    { :upgrade, :protocol, :cowboy_rest }
  end

  def terminate(_reason, _req, _state), do: :ok


  # Rest side

  def content_types_provided(req, state) do
	  {[
		  {"application/json", :autocomplete}
   	], 
    req, 
    state}
  end

  def autocomplete(req, state) do
    { a, _b } = :cowboy_req.qs_vals(req)
    { [ {"term", term} ], req } = :cowboy_req.qs_vals(req)
    result = Wex.Utility.Autocomplete.expand(term)
    Logger.info "#{inspect(a)} -> #{inspect result}"
    result = case Wex.Utility.Autocomplete.expand(term) do
      { :no, _, _ } ->
        []
      {:yes, "", {:send_doc, mod, fun}} ->
        docs = Wex.Util.Docs.h(mod, String.to_atom(fun))
        Wex.Handlers.HelpSender.send_help(docs)
        []
      { :yes, word, [] } when is_binary(word) ->
        [ word ]
      { :yes, "", words } when is_list(words) ->
        words
    end
    { Jazz.encode!(result), req, state }
  end


end