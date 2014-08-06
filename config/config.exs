use Mix.Config

config :logger, :console,
   format: "$date $time [$level] $pad$metadata$message\n",
   metadata: [:in]

