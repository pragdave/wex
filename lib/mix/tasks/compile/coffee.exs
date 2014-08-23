defmodule Mix.Tasks.Compile.Coffee do
  use Mix.Task

  @shortdoc "Compiles my Coffeescript"

  @moduledoc """
  Compiles the coffeescript files in scripts/, putting the
  result in priv/scripts/ours
  """

  def run(_) do
    IO.puts :os.cmd('coffee -c -o priv/scripts/ours/ scripts/ 2>&1')
  end
end
