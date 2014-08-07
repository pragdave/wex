defmodule Wex.Web.Rest.Autocomplete do

  use Wex.Web.Rest.Restful

  def handler(req, state) do
    { [ {"term", term} ], req } = :cowboy_req.qs_vals(req)
    result = Wex.Utility.Autocomplete.expand(term)
    Logger.info "#{inspect(term)} -> #{inspect result}"
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