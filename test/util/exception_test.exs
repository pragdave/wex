defmodule Util.ExceptionTest do
  use ExUnit.Case

  alias Wex.Util.Exception, as: E

  test "reason with no stack" do
    assert E.tidy({"reason", []}) == { "reason", [] }
  end

  test "stack with conventional location and function" do
    frame1 = { String, :split, 2, [ file: "dave.ex", line: 123 ] }

    expected = { "reason",
                 [
                  %{ frame:    frame1,
                     mfa:      "String.split/2",
                     location: "dave.ex:123"
                   }
                 ]
               }
    assert E.tidy({ "reason", [frame1]}) == expected
                 
  end

  test "stack with built-in operator" do
    frame1 = { :erlang, :/, [1,0], [ ] }

    expected = { "reason",
                 [
                  %{ frame:    frame1,
                     mfa:      "“1 / 0”",
                     location: ""
                   }
                 ]
               }
    assert E.tidy({ "reason", [frame1]}) == expected
  end

  test "strips internal frames" do
    frame1 = {Wex.Helpers,       :boom1,       2, [file: 'lib/wex/helpers.ex', line: 83]}
    frame2 = {Wex.Helpers,       :boom,        2, [file: 'lib/wex/helpers.ex', line: 79]}
    frame3 = {:erl_eval,         :do_apply,    6, [file: 'erl_eval.erl', line: 657]}
    frame4 = {:elixir,           :erl_eval,    3, [file: 'src/elixir.erl', line: 175]}
    frame5 = {:elixir,           :eval_forms,  4, [file: 'src/elixir.erl', line: 163]}
    frame6 = {Wex.Handlers.Eval, :eval,        2, [file: 'lib/wex/handlers/eval.ex', line: 102]}
    frame7 = {Wex.Handlers.Eval, :handle_cast, 2, [file: 'lib/wex/handlers/eval.ex', line: 51]}
    frame8 = {:gen_server,       :handle_msg,  5, [file: 'gen_server.erl', line: 599]}

    new_frame1 = {Wex.Helpers,   :boom1,       2, [file: "lib/wex/helpers.ex", line: 83]}
    new_frame2 = {Wex.Helpers,   :boom,        2, [file: "lib/wex/helpers.ex", line: 79]}

    expected =  {"reason",
            [%{frame:    new_frame1,
               location: "lib/wex/helpers.ex:83", 
               mfa:      "Wex.Helpers.boom1/2"},
             %{frame:    new_frame2,
               location: "lib/wex/helpers.ex:79", 
               mfa:      "Wex.Helpers.boom/2"}]}
    input = { "reason", [ frame1, frame2, frame3, frame4, frame5, frame6, frame7, frame8]}

    assert E.tidy(input) == expected
  end

end
