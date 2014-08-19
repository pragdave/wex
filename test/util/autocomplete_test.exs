Code.require_file "../test_helper.exs", __DIR__

defmodule IEx.AutocompleteTest do
  use ExUnit.Case, async: true

  import Wex.Utility.Autocomplete, only: [expand: 1]

  test :erlang_module_simple_completion do
    expected = 
    %{ given: ":z",
       find: { "yes", [ %{kind: "module", name: ":zlib", type: "erlang"} ]}}

    assert expand(":z") ==  expected
  end

  test :erlang_module_no_completion do
    assert expand(":x")    == %{ given: ":x", find: {"no", []}}
  end
  
  
  test :erlang_module_multiple_values_completion do
    expected = 
    %{given: ":user",
      find: {"yes",
             [
              %{kind: "module", name: ":user",     type: "erlang"},
              %{kind: "module", name: ":user_sup", type: "erlang"},
            ]}
     }
    assert expand(":user") == expected
  end

  test :elixir_simple_completion do
    expected = 
    %{given: "En",
      find: {"yes",
              [%{kind: "module", name: "Enum",       type: "elixir"},
               %{kind: "module", name: "Enumerable", type: "elixir"}
              ]
            }, 
     }
    
    assert expand("En") == expected

  end
  
  test :elixir_auto_completion_with_self do
    expected =
    %{given: "Enumerable",
      find: {"yes", [%{kind: "module", name: "Enumerable", type: "elixir"}] }
     }
    assert expand("Enumerable") == expected
  end
  
  test :elixir_no_completion do
    assert expand(".")   == %{find: {"no", []}, given: ""}  # . is not a valid pattern
    assert expand("Xyz") == %{find: {"no", []}, given: "Xyz"}
  end
  
  test :elixir_root_submodule_completion do
    _ = [foo: 1][:foo]
    expected =
    %{given: "Acce",
      find: {"yes",
              [
               %{kind: "module", name: "Access", type: "elixir"}
              ]
            }
     }

    assert expand("Acce") == expected
  end
  
  test :elixir_submodule_completion do
    expected =
    %{given: "String.Cha",
      find: {"yes",
              [%{kind: "module", name: "Chars", type: "elixir"}]
            },
     }

    assert expand("String.Cha") == expected
  end
  
  test :elixir_submodule_no_completion do
    assert expand("IEx.Xyz") == %{find: {"no", []}, given: "IEx.Xyz"}
  end
  
  test :elixir_function_completion do
    expected =
    %{given: "System.ve",
      find: yes("System", "System.version")
     }
    assert expand("System.ve") == expected
  end

  test :erlang_function_completion do
    expected =
    %{given: ":ets.fun2",
      find: {"yes", [%{kind: "function", mod: ":ets", name: ":ets.fun2ms", type: "erlang"}]}
      }
    assert expand(":ets.fun2") == expected
  end
  
  test :elixir_function_completion_when_name_is_unique do
    expected =
    %{given: "String.printable?", find: yes("String", "String.printable?") }
    assert expand("String.printable?")  == expected
  end
  
  test :elixir_macro_completion do
    expected = 
    %{given: "Kernel.is_p",
      find: {"yes",
              [ elf("Kernel", "Kernel.is_pid"), elf("Kernel", "Kernel.is_port") ]
            }
     }
    assert expand("Kernel.is_p") == expected
  end
  
  test :elixir_kernel_macro_completion do
    expected = %{given: "defstru", find: yes("Kernel", "defstruct") }
    assert expand("defstru") == expected
  end
  
  test :elixir_kernel_function_completion do
    expected = %{given: "to_str", find: yes("Kernel", "to_string") }
    assert expand("to_str") == expected
  end
  
  test :elixir_special_form_completion do
    expected =
    %{given: "unquote_spl", find: yes("Kernel.SpecialForms", "unquote_splicing") }
    assert expand("unquote_spl") == expected
  end
  
  test :elixir_proxy do
    assert %{ given: "E", find: {"yes", list} } = expand("E")
    assert Enum.find(list, &(&1.name == "Elixir"))
  end

  test :elixir_erlang_module_root_completion do
    assert %{ given: ":", find: {"yes", list} } = expand(":")
    assert Enum.find(list, &(&1.name == ":lists"))
  end
  
  test :completion_inside_expression_1 do
    expected =
    %{given: "Strin",
      find: {"yes",
              [%{kind: "module", name: "String", type: "elixir"}]
     } }
    assert expand("1+Strin") == expected
  end

  test :completion_inside_expression_2 do
    expected =
    %{given: "Strin",
      find: {"yes",
              [%{kind: "module", name: "String", type: "elixir"}]
     } }
    assert expand("Test(Strin") == expected
  end

  test :completion_inside_expression_3 do
    expected =
    %{given: ":z",
      find: {"yes",
              [%{kind: "module", name: ":zlib", type: "erlang"}]
     } }
    assert expand("Test :z") == expected
  end

  test :completion_inside_expression_4 do
    expected =
    %{given: ":z",
      find: {"yes",
              [%{kind: "module", name: ":zlib", type: "erlang"}]
     } }
    assert expand("[:z") == expected
  end

  ###########
  # Helpers #
  ###########

  def elf(mod, fun) do
      %{kind: "function", type: "elixir", mod: mod, name: fun}
  end

  def yes(mod, fun) do
    {"yes", [ elf(mod, fun) ] }
  end
end
