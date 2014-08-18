defmodule Wex.Web.Rest.Autocomplete do

  use Wex.Web.Rest.Restful

  with_param(:term) do
    case Wex.Utility.Autocomplete.expand(term) do
      %{ find: { "no", _ }, given: _ } ->
        []

      %{ find: { "yes", suggestions }, given: given} ->
        %{ given: given, suggest: suggestions }
    end
  end

end
