defmodule Wex.Web.Rest.ProcessInfo do

  use Wex.Web.Rest.Restful
  import Util.Type.AddTypes, only: [add_types: 1]

  with_param(:pid) do
    pid
    |> strip_elixir_inspect_prefix
    |> String.to_char_list
    |> :erlang.list_to_pid
    |> Process.info
    |> add_types
  end

  defp strip_elixir_inspect_prefix("#PID" <> pid), do: pid
  defp strip_elixir_inspect_prefix(pid),           do: pid

end
