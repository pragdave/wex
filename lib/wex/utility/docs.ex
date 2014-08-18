# Totally ripped off from IEx.Introspection
defmodule Wex.Util.Docs do
  @moduledoc false

  require Logger
  alias Wex.Util.Text, as: T

  ########################################################
  # Documentation for a term                             #
  ########################################################

  def h_for_string(term) when is_binary(term) do
    term |> Code.string_to_quoted |> h_for_string
  end

  def h_for_string({:ok, {{:__aliases__, [alias: false], modules}}}) do
    Module.concat(modules) |> h
  end

  def h_for_string(
                   {:ok, 
                    {{:., _, [{:__aliases__, _, modules}, fun]}, _, _}}
                  ) do
    mod = Module.concat(modules)
    h(mod, fun)
  end
  
  ########################################################
  # Documentation for modules. It has a fallback clauses #
  ########################################################

  def h(module)
  when is_atom(module) do
    module
    |> ensure_loaded
    |> info_present
    |> get_module_docs
  end

  def h(arg) do
    T.error "Don't know how to get documentation for #{arg}"
  end


  defp ensure_loaded(module) do
    case Code.ensure_loaded(module) do
      {:error, reason} ->
        T.error "Could not load module #{inspect module}, got: #{reason}"
      {:module, _} ->
        module
    end
  end

  defp info_present(module) when is_atom(module) do
    if function_exported?(module, :__info__, 1) do
      module
    else
      T.error "#{inspect module} is an Erlang module and does not have Elixir-style docs"
    end
  end
  defp info_present(error), do: error

  defp get_module_docs(module) when is_atom(module) do
    handle_docs(module, Code.get_docs(module, :moduledoc))
  end
  defp get_module_docs(error), do: error

  defp handle_docs(module, { _, docs })
  when is_binary(docs) do
    Logger.info(inspect(docs))
    T.help("<h1>#{inspect(module)}</h1>\n" <> Earmark.to_html(docs))
  end

  defp handle_docs(module, { _, _ }) do
    nodocs(inspect module)
  end

  defp handle_docs(module, _) do
    T.error "#{inspect module} was not compiled with docs"
  end



  #######################################################################
  # Docs for the given function, with any arity, in any of the modules. #
  #######################################################################

  def h(modules, function) 
  when is_list(modules) and is_atom(function) do
    docs = modules
           |> Enum.flat_map(&h_mod_fun(&1, function))
           |> Enum.filter(fn doc -> doc != [] end)
           |> Enum.filter(fn %{ help: _ } -> true
                             _            -> false
                          end)

    if docs == [] do
      T.error "Unknown function #{function}"
    else
      merge_helps(docs)
    end
  end

  def h(module, function) 
  when is_atom(module) and is_atom(function) do
    case h_mod_fun(module, function) do
      [] ->
        T.error("Unknown function: #{inspect module}.#{function}")
      docs ->
        merge_helps(docs)
    end
  end

  defp h_mod_fun(mod, fun)
  when is_atom(mod) and is_atom(fun) do
    find_fun_in_module_docs(mod, fun, Code.get_docs(mod, :docs))
  end

  defp find_fun_in_module_docs(_mod, _fun, nil), do: nil
  defp find_fun_in_module_docs(mod, fun, docs) do
    for {{f, arity}, _line, _type, _args, doc} <- docs, fun == f, doc != false do
      h(mod, fun, arity)
    end
  end

  defp merge_helps(helps) do
    (for %{ help: body } <- helps, do: body)
    |> Enum.join("\n")
    |> T.help
  end

  ##########################################################################
  # Documentation for the given function and arity in the list of modules. #
  ##########################################################################

  def h(modules, function, arity) 
  when is_list(modules) and is_atom(function) and is_integer(arity) do
    docs = modules
           |> Enum.map(&h_mod_fun_arity(&1, function, arity))
           |> Enum.filter(fn doc -> doc != [] end)
           |> Enum.filter(fn %{ help: _ } -> true
                             _            -> false
                          end)

    if docs == [] do
      T.error "Unknown function #{function}/#{arity}"
    else
      merge_helps(docs)
    end

  end

  def h(module, function, arity) 
  when is_atom(module) and is_atom(function) and is_integer(arity) do
    h_mod_fun_arity(module, function, arity)
  end

  defp h_mod_fun_arity(mod, fun, arity) 
  when is_atom(mod) and is_atom(fun) and is_integer(arity) do
    if docs = Code.get_docs(mod, :docs) do
      doc = find_doc(docs, fun, arity) || find_default_doc(docs, fun, arity)
      if doc do
        format_doc(doc)
      else
        T.error("Unknown function: #{inspect mod}.#{fun}/#{arity}")
      end
    else
      T.error "#{inspect mod} was not compiled with docs"
    end
  end

  defp find_doc(docs, function, arity) do
    List.keyfind(docs, {function, arity}, 0)
  end

  defp find_default_doc(docs, function, min) do
    Enum.find docs, fn(doc) ->
      case elem(doc, 0) do
        {^function, max} when max > min ->
          defaults = Enum.count elem(doc, 3), &match?({:\\, _, _}, &1)
          min + defaults >= max
        _ ->
          false
      end
    end
  end

  defp format_doc({{fun, _}, _line, kind, args, doc}) do
    heading = format_function_header(kind, fun, args)
    Logger.warn(inspect doc)
    doc = if doc, do: Earmark.to_html(doc), else: ""
    T.help("<h1>#{heading}</h1>\n" <> doc)
  end

  defp format_function_header(kind, fun, args) do
    args    = Enum.map_join(args, ", ", &format_doc_arg(&1))
    "#{kind} #{fun}(#{args})"
  end

  defp format_doc_arg({:\\, _, [left, right]}) do
    format_doc_arg(left) <> " \\\\ " <> Macro.to_string(right)
  end

  defp format_doc_arg({var, _, _}) do
    Atom.to_string(var)
  end



  ##########################
  # Print types in module. #
  ##########################

  def t(module) 
  when is_atom(module) do
    handle_all_module_types(module,  
                            Kernel.Typespec.beam_types(module),
                            fn _type, _arity -> true end)
  end

  defp handle_all_module_types(module, nil, _filter), do: nobeam(module)
  defp handle_all_module_types(module, [],  _filter), do: notypes(inspect(module))
  defp handle_all_module_types(module, types, filter) do
    result = for {_, {t, _, args}} = typespec <- types, filter.(t, length(args)) do
      format_type(typespec)
    end

    if result == [] do
      notypes(inspect module)
    else
      result
    end
  end

  ##################################################
  # Print the given type in module with any arity. #
  ##################################################

  def t(module, type) 
  when is_atom(module) and is_atom(type) do
    handle_all_module_types(module, 
                                  Kernel.Typespec.beam_types(module),
                                  fn t, _arity -> t == type end)
  end


  ##########################################
  # Print type in module with given arity. #
  ##########################################

  def t(module, type, arity) 
  when is_atom(module) and is_atom(type) and is_integer(arity) do
    handle_all_module_types(module, 
                                  Kernel.Typespec.beam_types(module),
                                  fn t, a -> t == type && a == arity end)
  end

  
  #################################
  # Print specs for given module. #
  #################################

  def s(module) 
  when is_atom(module) do
    handle_all_specs(module, nil, beam_specs(module), fn f, _a -> f != :"__info__" end)
  end

  defp handle_all_specs(module, _,   nil,  _filter), do: nobeam(module)
  defp handle_all_specs(module, nil, [],   _filter), do: nospecs(inspect(module))
  defp handle_all_specs(module, fun, specs, filter)  do
    result = for {_kind, {{f, arity}, _spec}} = spec <- specs, filter.(f, arity) do
      format_spec(spec)
    end
    if result == [] do
      if fun do
        nospecs("#{inspect(module)}.#{fun}")
      else
        nospecs(inspect(module), "s")
      end
    else
      result
    end
  end


  ##############################################
  # Print specs for given module and function. #
  ##############################################

  def s(module, function) 
  when is_atom(module) and is_atom(function) do
    handle_all_specs(module, function, beam_specs(module), fn f, _a -> f == function end)
  end


  ###########################################
  # Print spec in given module, with arity. #
  ###########################################

  def s(module, function, arity) 
  when is_atom(module) and is_atom(function) and is_integer(arity) do
    handle_all_specs(module, 
                     "#{function}/#{arity}", 
                     beam_specs(module), 
                     fn f, a -> f == function && a == arity end)
  end

  defp beam_specs(module) do
    (specs     = beam_specs_tag(Kernel.Typespec.beam_specs(module),     :spec))     &&
    (callbacks = beam_specs_tag(Kernel.Typespec.beam_callbacks(module), :callback)) &&
    Enum.concat(specs, callbacks)
  end

  defp beam_specs_tag(nil, _),     do: nil
  defp beam_specs_tag(specs, tag), do: Enum.map(specs, &{tag, &1})

  defp format_type({kind, type}) do
    ast = Kernel.Typespec.type_to_ast(type)
    T.subhead "@#{kind} #{Macro.to_string(ast)}"
  end

  defp format_spec({kind, {{name, _arity}, specs}}) do
    Enum.map specs, fn(spec) ->
      binary = Macro.to_string Kernel.Typespec.spec_to_ast(name, spec)
      T.subhead "@#{kind} #{binary}"
    end
  end

  defp nobeam(module) do
    case Code.ensure_loaded(module) do
      {:module, _} ->
        T.error "Beam code not available for #{inspect module} or debug info is missing, cannot load typespecs"
      {:error, reason} ->
        T.error "Could not load module #{inspect module}, got: #{reason}"
    end
  end

  defp nospecs(for, suffix \\ ""), do: no(for, "specification", suffix)
  defp notypes(for), do: no(for, "type information")
  defp nodocs(for),  do: no(for, "documentation")

  defp no(for, type, suffix \\ "") do
    T.error "#{for} has no #{type}#{suffix}"
  end
end
