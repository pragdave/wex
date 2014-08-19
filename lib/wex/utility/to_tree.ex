defmodule ValueTree do

  defmodule Leaf do
    defstruct class: "leaf", value: nil, type: ""
  end

  defmodule Container do
    defstruct class:    "container",
              children: [],
              type:     "",
              value:    nil,
              open_bracket: "",
              close_bracket: ""
  end

  defmodule Pair do
    defstruct class: "pair", left: nil, right: nil
  end

  defprotocol ToTree do
    @fallback_to_any true
    
    @doc """
    Return an arbitrary value as a nested tree. 
    """
    def to_tree(value)
  end

end

alias ValueTree.ToTree
alias ValueTree.Leaf
alias ValueTree.Pair
alias ValueTree.Container

defimpl ToTree, for: List do

  def to_tree(list) do
    cond do
      printable?(list) ->
        %Container{
          type: "CharList",
          value: "'#{Inspect.BitString.escape(IO.chardata_to_string(list), ?')}'",
          open_bracket:  "[",
          close_bracket: "]",
          children: (for child <- list, do: ToTree.to_tree(child))
        }

      keyword?(list) ->
        %Container{
          type: "KW list",
          value: inspect(list),
          open_bracket:  "[",
          close_bracket: "]",
          children: (for child <- list, do: keyword(child))
        }

      true ->
        %Container{
          type: "List",
          value: inspect(list),
          open_bracket:  "[",
          close_bracket: "]",
          children: (for child <- list, do: ToTree.to_tree(child))
        }
    end
  end

  def keyword({key, value}) do
    %Pair{
      left:  ToTree.to_tree(key_to_binary(key)),
      right: ToTree.to_tree(value)
    }
  end

  def keyword?([{key, _value} | rest]) when is_atom(key) do
    case Atom.to_string(key) do
      "Elixir." <> _ -> false
      _              -> keyword?(rest)
    end
  end

  def keyword?([]),     do: true
  def keyword?(_other), do: false

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




defimpl ToTree, for: HashDict do
  def to_tree(dict) do
    %Container{
               type: "HashDict",
               value: inspect(dict),
               open_bracket:  "[",
               close_bracket: "]",
               children: (for child <- Dict.to_list(dict), do: ToTree.to_tree(child))
              }
  end
end

defimpl ToTree, for: HashSet do
  def to_tree(set) do
    %Container{
               type: "HashSet",
               value: inspect(set),
               open_bracket:  "[",
               close_bracket: "]",
               children: (for child <- Set.to_list(set), do: ToTree.to_tree(child))
              }
  end
end



defimpl ToTree, for: Map  do
  def to_tree(map) do
    %Container{
               type: "Map",
               value: inspect(map),
               open_bracket:  "%{",
               close_bracket: "}",
               children: (for child <- Map.to_list(map), do: ToTree.to_tree(child))
              }
  end
end

defimpl ToTree, for: Tuple  do
  def to_tree(tuple) do
    %Container{
               type: "Tuple",
               value: inspect(tuple),
               open_bracket:  "{",
               close_bracket: "}",
               children: (for child <- Tuple.to_list(tuple), do: ToTree.to_tree(child))
              }
  end
end


defimpl ToTree, for: Atom  do
  def to_tree(value) do
    %Leaf{value: ":" <> Atom.to_string(value), type: "Atom"}
  end
end

defimpl ToTree, for: BitString  do
  def to_tree(value) do
    %Leaf{value: value, type: "String"}
  end
end

defimpl ToTree, for: Any  do
  def to_tree(value) do
    %Leaf{value: inspect(value), type: typeof(value)}
  end

  defp typeof(value) when is_integer(value),   do: "Integer"
  defp typeof(value) when is_float(value),     do: "Float"
  defp typeof(value) when is_function(value),  do: "Function"
  defp typeof(value) when is_pid(value),       do: "PID"
  defp typeof(value) when is_port(value),      do: "Port"
  defp typeof(value) when is_reference(value), do: "Reference"
  defp typeof(_),                              do: "unknown type"

end
