Code.require_file "../test_helper.exs", __DIR__

defmodule IEx.TypeTest do
  use ExUnit.Case, async: true
  alias Util.Type
  import Util.Type.AddTypes, only: [add_types: 1]
                 
  test "Basic type identification" do
    ref = :erlang.make_ref()
    assert Type.of(:ok)     == :atom
    assert Type.of("ok")    == :binary
    assert Type.of(1.2)     == :float
    assert Type.of(&(&1))   == :function
    assert Type.of(1)       == :integer
    assert Type.of([1, 2])  == :list
    assert Type.of(%{a: 1}) == :map
    assert Type.of(self)    == :pid
    assert Type.of(ref)     == :reference
    assert Type.of({1, 2})  == :tuple
  end

  test "Adding basic types" do
    assert add_types(1)    == %{ t: :integer, s: "1",           v: "1" }
    assert add_types(self) == %{ t: :pid,     s: inspect(self), v: inspect(self) }
  end

  test "Adding types to special atoms" do
    assert add_types(true)  == %{ t: :atom, s: "true",   v: "true"  }
    assert add_types(false) == %{ t: :atom, s: "false",  v: "false" }
    assert add_types(nil)   == %{ t: :atom, s: "nil",    v: "nil"   }
  end

  test "Adding types to lists" do
    expected = %{ t: "List", 
                  v: [
                          %{ t: :integer, s: "1", v: "1" },
                          %{ t: :integer, s: "2", v: "2" }
                  ],
                  s: "[1, 2]"
                }

    assert add_types([1,2]) == expected
  end

  test "Adding types to tuples" do
    expected = %{ t: "Tuple", 
                  v: [
                          %{ t: :atom,    s: ":a", v: ":a" },
                          %{ t: :integer, s: "1",  v: "1" }
                  ],
                  s: "{:a, 1}"
                }

    assert add_types({:a,1}) == expected
  end

  test "Adding types to maps" do
    expected = %{ t: "Map", 
                  v: %{
                       a: %{t: :integer, s: "1", v: "1"}, 
                       b: %{t: :integer, s: "2", v: "2"}
                  },
                  s: "%{a: 1, b: 2}"
                }

    assert add_types(%{a: 1, b: 2}) == expected
  end

  test "add types to a struct" do
    expected =
    %{
      t: "Struct",
      str: "RuntimeError", 
      s: "%RuntimeError{message: \"hello\"}", 
      v: %{
           __exception__: %{s: "true", t: :atom, v: "true"},
           __struct__: %{s: "RuntimeError", t: :atom, v: "RuntimeError"},
           message: %{s: "\"hello\"", t: "String", v: "\"hello\""}
      }
    }
    assert add_types(%RuntimeError{message: "hello"}) == expected
  end

  test "Adding types to maps with nonatom keys" do
    expected = %{ t: "Map", 
                  v: [
                      %{
                        s: "{:b, 2}", 
                        t: "Tuple",
                        v: [%{s: ":b", t: :atom, v: ":b"},
                            %{s: "2", t: :integer, v: "2"}]
                      },
                      %{
                        s: "{\"a\", 1}", 
                        t: "Tuple",
                        v: [%{s: "\"a\"", t: "String", v: "\"a\""},
                            %{s: "1", t: :integer, v: "1"}]
                        }
                  ],
                  s: "%{:b => 2, \"a\" => 1}"
                }

    assert add_types(%{"a" => 1, :b => 2}) == expected
  end


  test "Adding types to keyword lists" do
    expected = %{ t: "KW list", 
                  v: %{
                       a: %{t: :integer, s: "1", v: "1"}, 
                       b: %{t: :integer, s: "2", v: "2"}
                  },
                  s: "[a: 1, b: 2]"
                }

    assert add_types([a: 1, b: 2]) == expected
  end

end
