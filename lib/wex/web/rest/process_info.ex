defmodule Wex.Web.Rest.ProcessInfo do

  use Wex.Web.Rest.Restful
  import Util.Type.AddTypes, only: [add_types: 1]

  with_param(:pid) do
    pid = parse_pid(pid)
    pid
    |> Process.info
    |> get_state(pid)
    |> translate_initial_call
    |> add_types
  end

  defp parse_pid(pid) do
    pid
    |> strip_elixir_inspect_prefix
    |> String.to_char_list
    |> :erlang.list_to_pid
  end

  defp strip_elixir_inspect_prefix("#PID" <> pid), do: pid
  defp strip_elixir_inspect_prefix(pid),           do: pid

  defp get_state(nil, _pid), do: nil

  defp get_state(info, pid) do
    case Keyword.fetch!(info, :initial_call) do
      {:proc_lib, :init_p, _} -> get_state(pid) ++ info
      _other                  -> info
    end
  end

  defp get_state(pid) do
    # Use another process so that timed out replies aren't sent to our message
    # queue.
    Task.async(fn() -> do_get_state(pid) end)
    |> Task.await()
  end

  defp do_get_state(pid) do
    try do
      # Short timeout so don't wait too long for a busy process or process that
      # can not handle :sys messages. The process was started by :proc_lib so it
      # is likely that it can handle :sys messages.
      :sys.get_state(pid, 100)
    else
      state ->
        [state: state]
    catch
      # Process may exit before or during call
      :exit, {_reason, {:sys, :get_state, [^pid, 100]}} ->
        []
    end
  end

  defp translate_initial_call(nil), do: nil

  defp translate_initial_call(info) do
    Keyword.update!(info, :initial_call,
      fn({:proc_lib, :init_p, _}) -> :proc_lib.translate_initial_call(info)
        (mfa)                     -> mfa
      end)
  end

end
