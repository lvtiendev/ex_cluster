defmodule ExCluster do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("ExCluster application started: DSC")

    topologies = Application.get_env(:libcluster, :topologies)

    children = [
      { Cluster.Supervisor, [topologies, [name: ExCluster.ClusterSupervisor]] },
      { ExCluster.StateHandoff, [] },
      { Horde.Registry, [name: ExCluster.Registry, keys: :unique, members: registry_members()] },
      { Horde.DynamicSupervisor, [name: ExCluster.OrderSupervisor, strategy: :one_for_one, members: supervisor_members()] },
      %{
        id: ExCluster.HordeConnector,
        restart: :transient,
        start: {
          Task, :start_link, [
            fn ->
              Node.list()
              |> Enum.each(fn node ->
                :ok = ExCluster.StateHandoff.join(node)
              end)
            end
          ]
        }
      }
    ]

    Supervisor.start_link(children, [strategy: :one_for_one, name: ExCluster.Supervisor])
  end

  defp registry_members do
    [
      {ExCluster.Registry, :"count1@127.0.0.1"},
      {ExCluster.Registry, :"count2@127.0.0.1"},
      # {ExCluster.Registry, :"count3@127.0.0.1"}
    ]
  end

  defp supervisor_members do
    [
      {ExCluster.OrderSupervisor, :"count1@127.0.0.1"},
      {ExCluster.OrderSupervisor, :"count2@127.0.0.1"},
      # {ExCluster.OrderSupervisor, :"count3@127.0.0.1"}
    ]
  end
end
