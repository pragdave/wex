defmodule Wex.Utility.Autocomplete do
  @moduledoc false

  require Logger


  @doc """
  Given a string, look at the token at its end to see if it can
  be expanded into a module or module.function.

  We return a map that looks like this:

      %{ given: token, find: { result } }

  where `token` is the thing found at the end of the string.

  The result will either be

      { "no", [] }    # for no matches

  or

      { "yes", [ %{ ... } ] }

  In the latter case, the maps in the list will always have a `kind:` 
  key and a `name:` key.

  `kind:` will be either `"module"` or `"function`".

  The `name:` will be a possible expansion of the token.

  In addition, the map may include a `type: "erlang"` or `type: "elixir"`
  to indicate the provenance of the match.

  ## Example

      iex> expand(":user")
      %{given: ":user",
        find: {"yes",
               [
                %{kind: "module", name: ":user_sup", type: "erlang"},
                %{kind: "module", name: ":user",     type: "erlang"},
              ]}
       }

      iex> expand("defstru")
      %{given: "defstru",
        find: {"yes",
                [%{kind: "function", mod: "Kernel", name: "defstruct"}]
              }
        }

  """

  def expand(string) do
    Logger.warn("expand #{inspect string}")
    rev = String.reverse(string)

    cond do
      match = Regex.run(~r{^[A-Za-z0-9]*[A-Z](\.[A-Za-z0-9]*[A-Z])*}, rev) ->
        [token|_] = match
        String.reverse(token) |> expand_elixir_module

      match = Regex.run(~r{^[A-Za-z0-9_]*[a-z]:}, rev) ->
        [token] = match
        String.reverse(token) |> expand_erlang_module

      match = Regex.run(~r{^([A-Za-z0-9_]*)(\.[a-zA-Z0-9_]+):}, rev) ->
        [token, fun, mod|_] = match
        reverse({token, fun, mod}) |> expand_functions_in_erlang_module

      match = Regex.run(~r{^([?!]?[A-Za-z0-9_]*)(\.[a-zA-Z0-9_]+[A-Z])+}, rev) ->
        [token, fun, mod|_] = match
        reverse({token, fun, mod}) |> expand_functions_in_elixir_module

      match = Regex.run(~r{^[A-Za-z0-9_]*[a-z_]}, rev) ->
        [token] = match
        fun = String.reverse(token)                            
        expand_functions_imported_into_top_level(fun)

      match = Regex.run(~r{(^:$)|(^:\b)}, rev) ->
        expand_erlang_module(":")                              
                            
      true ->
        %{ given: "", find: no()}
    end
  end

  def expand("") do
    # expand_import("")
     no()
  end

  ######################################################################

  defp expand_erlang_module(token) do
    %{ given: token, find: erlang_modules(token) }
  end

  defp expand_elixir_module(token) do
    %{ given: token, find: elixir_modules(token) }
  end

  defp expand_functions_in_elixir_module({token, fun, mod}) do
    %{given: token, find: expand_elixir_functions(mod, fun)}
  end

  defp expand_functions_in_erlang_module({token, fun, mod}) do
    %{given: token, find: expand_erlang_functions(mod, fun)}
  end

  defp expand_functions_imported_into_top_level(fun) do
    %{given: fun, find: expand_imports(fun)}
  end


  ################
  # Root Modules #
  ################
  
  defp root_modules do
    Enum.reduce :code.all_loaded, [], fn {mod, _}, acc ->
      module_info(to_string(mod), acc)
    end
  end

  defp module_info(mod = ("Elixir" <> _), acc) do
    elixir_module_info(String.split(mod, "."), acc)
  end

  defp module_info(mod, acc) do
    [ %{kind: "module", name: ":#{mod}", type: "erlang"} | acc]
  end

  defp elixir_module_info([_, actual_mod], acc) do                            
    [%{kind: "module", name: actual_mod, type: "elixir"} | acc]
  end

  defp elixir_module_info(_, acc) do                            
    acc
  end

  

  ##################
  # Erlang modules #
  ##################
  
  defp erlang_modules(starting) do
    root_modules
    |> Enum.filter(erlang_module_filter_function(starting))
    |> format_expansion 
  end
  
  defp erlang_module_filter_function("") do
    fn m -> m.type === :erlang end
  end

  defp erlang_module_filter_function(starting) do
    fn m -> String.starts_with?(m.name, starting) end
  end
  
  
  ##################
  # Elixir modules #
  ##################
  
  defp elixir_modules(token) do
    root = !String.contains?(token, ".")
    elixir_submodules(token, root)
    |> format_expansion 
  end
  
  defp elixir_submodules(basename, root) do
    depth = basename |> String.split(".") |> length

    modules_as_strings(root)
    |> Enum.map(&(look_for_elixir_submodule(&1, basename, depth)))
    |> Enum.filter(&(&1))
  end

  def look_for_elixir_submodule(mod, basename, depth) do
    if String.starts_with?(mod, basename) do
      tokens = String.split(mod, ".")
      if length(tokens) == depth do
        %{kind: "module", type: "elixir", name: List.last(tokens) }
      end
    end
  end
  
  defp modules_as_strings(true) do
    ["Elixir" | modules_as_strings(false) ]
  end
  
  defp modules_as_strings(false) do
    Enum.map(:code.all_loaded, fn({m, _}) -> strip_elixir(Atom.to_string(m)) end)
  end

  defp strip_elixir("Elixir." <> mod), do: mod
  defp strip_elixir(mod), do: mod

  #################################
  # Functions in an Elixir module #
  #################################

  defp expand_elixir_functions(mod, fun) do
    mod = mod
          |> String.rstrip(?.)
          |> String.split(".")
          |> Module.concat

    module_funs(mod, fun) |> format_expansion
  end

  #################################
  # Functions in an Erlang module #
  #################################

  defp expand_erlang_functions(mod, fun) do
    mod = mod |> String.rstrip(?.) |> String.to_atom
    matching_functions_in(mod, fun) 
    |> expand_function_list(mod, "erlang", ":") 
    |> format_expansion
  end


  #####################################
  # Functions imported into top level #
  #####################################
                                
  defp expand_imports(name) do
    (
      module_funs(Wex.Helpers, name) ++
      module_funs(Kernel, name)      ++
      module_funs(Kernel.SpecialForms, name)
    )
    |> remove_module_names
    |> format_expansion
  end

  defp remove_module_names(list) do
    Enum.map(list, &remove_module_name_in_entry/1)
  end

  defp remove_module_name_in_entry(entry) do
    update_in(entry.name, &remove_module_name/1)
  end

  defp remove_module_name(name) do
    name
    |> String.split(".")
    |> List.last
  end
  
  
  ###########
  # Helpers #
  ###########
  
  defp module_funs(mod, fun) do
    mod 
    |> ensure_loaded
    |> matching_functions_if_module_loaded(mod, fun)
    |> expand_function_list(mod, "elixir")
  end

  defp matching_functions_if_module_loaded({:module, _}, mod, fun) do
    matching_functions_in(mod, fun)
  end

  defp matching_functions_if_module_loaded(_, _mod, _fun) do
    []
  end
  
  defp matching_functions_in(mod, fun) do
    get_funs(mod)
    |> Enum.map(fn {f,_a} -> Atom.to_string(f) end)
    |> Enum.uniq
    |> Enum.filter(&match_name(&1, fun))
  end

  defp match_name(_fun, ""),  do: true
  defp match_name(fun, partial_name), do: String.starts_with?(fun, partial_name)
  
  defp expand_function_list(list, mod, type, prefix \\ "") do
    mod = mod |> to_string |> strip_elixir
    mod = "#{prefix}#{mod}"
    for fun <- list do
      
      %{
        kind:    "function", 
        mod:     mod, 
        name:    "#{mod}.#{fun}", 
        type:    type
      }
    end
  end
                       
  defp get_funs(mod) do
    get_funs(mod, is_elixir_module(mod))
  end

  defp get_funs(mod, _is_elixir = true) do
    get_elixir_funs(mod, Code.get_docs(mod, :docs))
  end

  defp get_funs(mod, _is_not_elixir) do
    mod.module_info(:exports)
  end

  defp get_elixir_funs(_mod, docs) when is_list(docs) do
    for {tuple, _line, _kind, _sign, doc} <- docs, doc != false, do: tuple
  end

  defp get_elixir_funs(mod, _docs) do
    (mod.__info__(:functions) -- [__info__: 1]) ++ mod.__info__(:macros)
  end

  defp is_elixir_module(mod), do: function_exported?(mod, :__info__, 1)

                  

  ##############
  # Formatting #
  ##############
  
  defp format_expansion([]) do
    no()
  end
  
  defp format_expansion(entries) do
    entries
    |> Enum.sort_by(&(&1.name))
    |> yes
  end
  
  defp reverse({s1, s2}) do
    { String.reverse(s1), String.reverse(s2) }
  end
  defp reverse({s1, s2, s3}) do
    { String.reverse(s1), String.reverse(s2), String.reverse(s3) }
  end

  defp yes(entries) do
    {"yes", entries}
  end
  
  defp no do
    {:no, []}
  end

  defp ensure_loaded(Elixir), do: {:error, :nofile}
  defp ensure_loaded(mod),    do: Code.ensure_compiled(mod)


end
