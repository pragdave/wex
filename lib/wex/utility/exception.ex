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


  def format(frame = {:erlang, fun, [a,b], []}) do
    if Regex.match?(~r/[a-zA-Z]/, Atom.to_string(fun)) do
      frame
    else
      %{ override: "evaluating “#{a} #{fun} #{b}”", frame: frame }
    end
  end

  def format(frame), do: frame
end
