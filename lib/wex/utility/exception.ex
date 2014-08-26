defmodule Wex.Util.Exception do

  require Logger

  def tidy({reason, stack_frames}) do
    { reason, Enum.reverse(tidy_stack(stack_frames, [])) }
  end

  def tidy_stack([], result), do: result

  # There are 3 Elixir/Erlang frames on top of us...
  def tidy_stack([_, _, _, { Wex.Handlers.Eval, _, _, _} | _rest], result) do
    result
  end


  def tidy_stack([frame|rest], result) do
    tidy_stack(rest, [ format(frame) | result ])
  end


  defp format(frame) do
    frame
    |> replace_charlist
    |> to_map
    |> add_mfa
    |> add_location
  end

   defp replace_charlist({m, f, a, [file: file, line: line]}) when is_list(file) do
     { m, f, a, [ file: List.to_string(file), line: line ] }
   end

  defp replace_charlist(frame) do
    frame
  end


  defp to_map(frame) do
    %{ frame: frame, mfa: "", location: "" }
  end

  def add_mfa(frame = %{ frame: {:erlang, fun, [a,b], []}}) do
    if Regex.match?(~r/[a-zA-Z]/, Atom.to_string(fun)) do
      %{ frame | mfa: Elixir.Exception.format_mfa(:erlang, fun, [a,b]) }
    else
      %{ frame | mfa: "“#{a} #{fun} #{b}”"  }
    end
  end

  def add_mfa(frame = %{ frame: {m, f, a, _} }) do
    %{ frame | mfa: Elixir.Exception.format_mfa(m, f, a) }
  end

  def add_location(frame = %{ frame: { _, _, _, [file: file, line: line]} }) do
    location = Elixir.Exception.format_file_line(file, line)
    %{ frame | location: String.rstrip(location, ?:)}
  end

  def add_location(frame = %{ frame: { _, _, _, []} }) do
    frame
  end

end
