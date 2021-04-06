use Mix.Config

# config :libcluster,
#   topologies: [
#     example: [
#       strategy: LibCluster.LocalStrategy
#     ]
#   ]

config :libcluster,
  topologies: [
    example: [
      strategy: Elixir.Cluster.Strategy.Epmd,
      config: [
        hosts: [:"count1@127.0.0.1", :"count2@127.0.0.1"]
      ]
    ]
  ]
