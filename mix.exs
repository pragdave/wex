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



defmodule Wex.Mixfile do
  use Mix.Project

  def project do
    [
     app:       :wex,
     version:   "0.0.1",
     elixir:    "~> 0.15.0-dev",
     deps:      deps,
     compilers: [:elixir, :erlang, :coffee, :app ]
    ]
  end

  def application do
    [
     applications: [ :logger, :cowboy ]
    ]
  end

  defp deps do
    [
     { :earmark, ">  0.0.0" },
     { :jazz,    "~> 0.1" },
     { :cowboy,  "~> 1.0.0", github: "extend/cowboy" },
    ]
  end
end

