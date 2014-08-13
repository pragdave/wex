defmodule Wex.State do

  defstruct binding: [], 
            env: nil, 
            scope: nil, 
            partial_input: "", 
            ws: nil, 
            stdout: nil,
            stderr: nil

end