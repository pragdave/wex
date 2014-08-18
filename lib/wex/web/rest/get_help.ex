defmodule Wex.Web.Rest.GetHelp do

  use Wex.Web.Rest.Restful

  with_param(:term) do
    # case Wex.Utility.Autocomplete.expand(term) do
    #   %{ find: { "yes", [ %{ name: name } ] }, given: name} ->
    #     name
    #     |> String.split(".") 
    #     |> Enum.reverse
    #     |> get_help
    #     |> Wex.Handlers.HelpSender.send_help
    #     "ok"
    # 
    #   _other ->
    #     "error"
    # end
    Wex.Util.Docs.h_for_string(term)
    |> Wex.Handlers.HelpSender.send_help
    "ok"
  end

  # defp get_help([mod]) do
  #   Wex.Util.Docs.h(String.to_atom(mod))
  # end
  # 
  # defp get_help([ fun | mods ]) do
  #   mod = mods |> Enum.reverse |> Enum.join(".") |> String.to_atom
  #   Wex.Util.Docs.h(mod, String.to_atom(fun))
  # end

end
