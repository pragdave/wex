defmodule Util.DocsTest do
  use ExUnit.Case

#  alias Wex.Util.Text, as: T
  alias Wex.Util.Docs, as: D

  alias Wex.Test.Module, as: TM

  ###############
  # Module docs #
  ###############

  test "h(not_a_module) returns an error" do
    assert [ error: msg ] = D.h(123)
    assert "Don't know how to get documentation for 123" == msg
  end

  test "h(AtomNotAModule) says it isn't a module" do
    assert [ error: msg ] = D.h(NotAModule)
    assert "Could not load module" <> _ = msg
  end

  test "h(:io) says it's an Erlang module" do
    assert [ error: msg ] = D.h(:io)
    assert ":io is an Erlang module" <> _ = msg
  end

  test "h(ModWithNoDocs) returns no docs" do
    assert [ error: msg ] = D.h(TM.WithNoDocs)
    assert "Wex.Test.Module.WithNoDocs has no documentation" == msg
  end

  test "h(ModWithModDocs) returns docs" do
    assert [ help: [[heading: heading], body ]] = D.h(TM.WithDocs)
    assert "Wex.Test.Module.WithDocs" == heading
    assert "docs" == body
  end

  #########################
  # Module, function docs #
  #########################

  test "h(Module, non-existent-function)" do
    assert [error: msg] = D.h(TM.WithDocs, :doesnt_exist)
    assert "Unknown function: Wex.Test.Module.WithDocs.doesnt_exist" ==  msg
  end

  test "h(Module, fn_no_docs)" do
    result = D.h(TM.WithDocs, :fn_no_doc)
    assert [[help: [[heading: "def fn_no_doc(a, b)"], nil]]] = result
  end

  test "h(Module, fn_with_docs)" do
    result = D.h(TM.WithDocs, :fn_with_doc)
    assert [[help: [[heading: "def fn_with_doc(c, d \\\\ 1)"], "<p>fn docs</p>\n"]]] = result
  end

  test "h(Module, fn with multiple arities)" do
    result = D.h(TM.WithDocs, :fn_with_arities)
    expect = [[help: [[heading: "def fn_with_arities()"],     "<p>arity 0</p>\n"]],
              [help: [[heading: "def fn_with_arities(a)"],    nil]],
              [help: [[heading: "def fn_with_arities(a, b)"], "<p>arity 2</p>\n"]]]

    assert expect == result
  end

  ###########################
  # Module, function, arity #
  ###########################

  test "MFA with unknown function" do
    assert [ error: msg ] = D.h(TM.WithDocs, :wibble, 1)
    assert "Unknown function: Wex.Test.Module.WithDocs.wibble/1" == msg
  end

  test "MFA for function with no docs" do
    result = D.h(TM.WithDocs, :fn_no_doc, 2)
    assert [help: [[heading: "def fn_no_doc(a, b)"], nil]] = result
  end

  test "MFA for function with docs" do
    result = D.h(TM.WithDocs, :fn_with_doc, 2)
    assert [help: [[heading: "def fn_with_doc(c, d \\\\ 1)"], "<p>fn docs</p>\n"]] = result
  end

  ################
  # Module types #
  ################

  test "Module with no types" do
    assert [error: msg] = D.t(TM.WithNoTypes)
    assert msg == "Wex.Test.Module.WithNoTypes has no type information"
  end

  test "Module with types" do
    result = D.t(TM.WithTypes)
    expect = [[subhead: "@type intlist() :: [integer()]"],
              [subhead: "@type t() :: Wex.Test.Module.WithTypes"]]

    assert result == expect
  end


  #############
  # And specs #
  #############

  test "Module with no specs" do
    assert [error: msg] = D.s(TM.WithNoSpecs)
    assert msg == "Wex.Test.Module.WithNoSpecs has no specifications"
  end

  test "Module with specs" do
    result = D.s(TM.WithSpecs)
    expect = [[[subhead: "@spec f2({T, T}) :: T"]],
              [[subhead: "@spec f1(t()) :: integer()"]]]

    assert result == expect
  end

  test "Specs for a function" do
    result = D.s(TM.WithSpecs, :f1)
    expect = [[[subhead: "@spec f1(t()) :: integer()"]]]

    assert result == expect
  end

  test "Specs for a function that doesn't exist" do
    result = D.s(TM.WithSpecs, :f9)
    expect = [error: "Wex.Test.Module.WithSpecs.f9 has no specification"]

    assert result == expect
  end

  test "Specs for a function with arity that doesn't exist" do
    result = D.s(TM.WithSpecs, :f1, 9)
    expect = [error: "Wex.Test.Module.WithSpecs.f1/9 has no specification"]

    assert result == expect
  end

end

