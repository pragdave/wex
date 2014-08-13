defmodule Wex.Web.Rest.GetHelp do

  use Wex.Web.Rest.Restful

  with_param(:term) do
    case Wex.Utility.Autocomplete.expand(term) do
      {:yes, "", {:send_doc, mod, fun}} ->
        docs = Wex.Util.Docs.h(mod, String.to_atom(fun))
        Wex.Handlers.HelpSender.send_help(docs)
        "ok"

      _other ->
        "error"
    end
  end

end