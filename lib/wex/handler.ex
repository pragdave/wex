defmodule Wex.Handler do

  @moduledoc """
  A library of stuff used by the eval and compile servers.
  """

  defmacro __using__(name) do
    handler_name = "handle_#{name}" |>  String.to_atom
    string_name = to_string(name)
    padded_name = String.ljust(string_name, 8)

    quote do

    end
  end


end