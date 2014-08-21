defmodule Util.Type do


  defprotocol AddTypes do
    @fallback_to_any true
    
    @doc """
    Return an arbitrary value as a nested tree where each value
    is turned into a map of %{t: .., s: ..., v: ...}, where t: is the type
    and s: is the fallback string representation.
    """
    def add_types(value)
  end

  alias Util.Type.AddTypes

  def of(value) when is_atom(value),      do: :atom
  def of(value) when is_binary(value),    do: :binary
  def of(value) when is_float(value),     do: :float
  def of(value) when is_function(value),  do: :function
  def of(value) when is_integer(value),   do: :integer
  def of(value) when is_list(value),      do: :list
  def of(value) when is_map(value),       do: :map
  def of(value) when is_pid(value),       do: :pid
  def of(value) when is_port(value),      do: :port
  def of(value) when is_reference(value), do: :reference
  def of(value) when is_tuple(value),     do: :tuple

  def maybe_keyword_collection(collection, inspected, typename, known_keyword \\ false) do
    value = if known_keyword || keyword_list?(collection) do
              (for {key, val} <- collection, into: %{}, do: { key, AddTypes.add_types(val) } )
            else
              (for child <- collection, do: AddTypes.add_types(child))
            end
    %{
      t: typename,
      s: inspected,
      v: value
    }
  end

  def keyword_list?([{key, _value} | rest]) when is_atom(key) do
    case Atom.to_string(key) do
      "Elixir." <> _ -> false
      _              -> keyword_list?(rest)
    end
  end

  def keyword_list?([]),     do: true
  def keyword_list?(_other), do: false

end
      
alias Util.Type.AddTypes

defimpl AddTypes, for: List do

  def add_types(list) do
    cond do
      length(list) == 0 ->
        %{
          t: "List",
          s: "[]",
          v: []
        }

      printable?(list) ->
        %{
          t: "CharList",
          s: "'#{Inspect.BitString.escape(IO.chardata_to_string(list), ?')}'",
          v: (for child <- list, do: AddTypes.add_types(child))
        }

      Util.Type.keyword_list?(list) ->
        Util.Type.maybe_keyword_collection(list, inspect(list), "KW list", true)

      true ->
        %{
          t: "List",
          s: inspect(list),
          v: (for child <- list, do: AddTypes.add_types(child))
        }
    end
  end

  def keyword({key, value}) do
    { key_to_binary(key), AddTypes.add_types(value) }
  end


  ## Private

  defp key_to_binary(key) do
    Atom.to_string(key) <> ":"
  end

  defp printable?([c|cs]) when is_integer(c) and c in 32..126, do: printable?(cs)
  defp printable?([?\n|cs]), do: printable?(cs)
  defp printable?([?\r|cs]), do: printable?(cs)
  defp printable?([?\t|cs]), do: printable?(cs)
  defp printable?([?\v|cs]), do: printable?(cs)
  defp printable?([?\b|cs]), do: printable?(cs)
  defp printable?([?\f|cs]), do: printable?(cs)
  defp printable?([?\e|cs]), do: printable?(cs)
  defp printable?([?\a|cs]), do: printable?(cs)
  defp printable?([]), do: true
  defp printable?(_), do: false
end




defimpl AddTypes, for: HashDict do
  def add_types(dict) do
    %{
      t: "HashDict",
      s: inspect(dict),
      v: (for child <- Dict.to_list(dict), do: AddTypes.add_types(child))
    }
  end
end

defimpl AddTypes, for: HashSet do
  def add_types(set) do
    %{
      t: "HashSet",
      s: inspect(set),
      v: (for child <- Set.to_list(set), do: ToTree.add_types(child))
    }
  end
end



defimpl AddTypes, for: Map  do
  def add_types(map) do
    Util.Type.maybe_keyword_collection(Map.to_list(map), inspect(map), "Map")
  end
end

defimpl AddTypes, for: Tuple  do
  def add_types(tuple) do
    %{
      t: "Tuple",
      s: inspect(tuple),
      v: (for child <- Tuple.to_list(tuple), do: AddTypes.add_types(child))
    }
  end
end


defimpl AddTypes, for: Atom  do
  def add_types(value) do
    representation = ":" <> Atom.to_string(value)
    %{ t: :atom, s: representation, v: representation }
  end
end

defimpl AddTypes, for: BitString  do
  def add_types(value) do
    value = Inspect.BitString.inspect(value, %Inspect.Opts{})
    %{ t: "String", s: value, v: value }
  end
end

defimpl AddTypes, for: Any  do
  def add_types(value) do
    %{ t: Util.Type.of(value), s: inspect(value), v: inspect(value) }
  end


end
