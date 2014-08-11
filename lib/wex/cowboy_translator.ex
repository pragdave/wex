# From James Fish
defmodule CowboyTranslator do
  def translate(min_level, :error, :format,
                {'Ranch listener' ++ _, [ref, :cowboy_protocol, pid, reason]}) do
    {:ok, translate_cowboy(min_level, ref, pid, reason)}
  end
 
  def translate(_min_level, _level, _kind, _data) do
    :none
  end
 
  defp translate_cowboy(min_level, ref, pid,
                        {[{:reason, reason}, {:mfa, _} = mfa,
                          {:stacktrace, stack} | info], _internal_stack}) do
    translate_cowboy(min_level, ref, pid, :error, reason, stack, [mfa | info])
  end
 
  defp translate_cowboy(min_level, ref, pid,
                        {{:nocatch, [{:reason, reason}, {:mfa, _} = mfa,
                                     {:stacktrace, stack} | info]},
                         _internal_stack}) do
    translate_cowboy(min_level, ref, pid, :throw, reason, stack, [mfa | info])
 end
 
 defp translate_cowboy(min_level, ref, pid, [{:reason, reason}, {:mfa, _} = mfa,
                                             {:stacktrace, stack} | info]) do
    translate_cowboy(min_level, ref, pid, :exit, reason, stack, [mfa | info])
 end
 
 defp translate_cowboy(min_level, ref, pid, reason) do
   translate_cowboy(min_level, ref, pid, :exit, reason, [], [])
 end
 
 defp translate_cowboy(min_level, ref, pid, kind, reason, stack, info) do
   ["Cowboy Protocol ", inspect(pid), " of Listener ", inspect(ref),
     " terminated\n",
    cowboy_info(min_level, info) |
    Exception.format(kind, reason, stack)]
 end
 
 defp cowboy_info(min_level, [{:mfa, {mod, fun, arity}} | debug]) do
   ["Handler Call: ", Exception.format_mfa(mod, fun, arity), ?\n |
     cowboy_debug(min_level, debug)]
 end
 
 defp cowboy_info(min_level, debug) do
   cowboy_debug(min_level, debug)
 end
 
 defp cowboy_debug(:debug, [{:req, req} | debug]) do
   [cowboy_debug(:debug, debug) |
     cowboy_req(req)]
 end
 
 defp cowboy_debug(:debug, [{:opts, options} | debug]) do
   ["Handler Options: ", inspect(options), ?\n |
     cowboy_debug(:debug, debug)]
 end
 
 defp cowboy_debug(:debug, [{:state, state} | extra]) do
   ["Handler State: ", inspect(state), ?\n |
     cowboy_debug(:debug, extra)]
 end
 
 defp cowboy_debug(:debug, [{:terminate_reason, reason} | extra]) do
   ["Terminate Reason: ", inspect(reason), ?\n |
     cowboy_debug(:debug, extra)]
 end
 
 defp cowboy_debug(_min_level, _debug) do
   []
 end
 
 defp cowboy_req(req) do
   prefix = "    "
   Enum.reduce(req, ["Request:\n"], fn({key, value}, acc) ->
     [acc, prefix, Atom.to_string(key), ": ", inspect(value), ?\n]
   end)
 end
end
