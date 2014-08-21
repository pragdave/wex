defmodule Wex.Web.Rest.GetHelp do

  use Wex.Web.Rest.Restful

  with_param(:term) do
    Wex.Util.Docs.h_for_string(term)
    |> Wex.Handlers.HelpSender.send_help
    "ok"
  end

end
