Code.require_file "support/mix_tasks/coffee.exs"

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
      { :applications, [ :logger, :cowboy ] }
    |
      module(Mix.env)
    ]
  end

  def module(:test), do: []
  def module(_),     do: [ mod: { Wex, [] } ]

  defp deps do
    [
     { :earmark, ">  0.0.0" },
     { :json,    "~> 0.3.0" },
     { :cowboy,  "~> 1.0.0", github: "extend/cowboy" },
    ]
  end
end

