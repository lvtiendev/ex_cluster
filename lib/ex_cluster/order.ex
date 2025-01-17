defmodule ExCluster.Order do
  use GenServer
  require Logger

  def child_spec(customer), do: %{ id: customer,
                                   start: { __MODULE__, :start_link, [customer] } }

  def start_link(customer) do
    Logger.info("Starting Order for #{customer}")
    # note the change here in providing a name: instead of [] as the 3rd param
    GenServer.start_link(__MODULE__, customer, name: via_tuple(customer))
  end

  # add contents to the customers order
  def add(customer, new_order_contents) do
    GenServer.cast(via_tuple(customer), { :add, new_order_contents })
  end

  # fetch current contents of the customers order
  def contents(customer) do
    GenServer.call(via_tuple(customer), { :contents })
  end

  def stop(customer) do
    GenServer.cast(via_tuple(customer), { :stop })
  end

  defp via_tuple(customer) do
    { :via, Horde.Registry, { ExCluster.Registry, customer } }
  end

  def init(customer) do
    Process.flag(:trap_exit, true)
    order_contents = ExCluster.StateHandoff.pickup(customer)
    { :ok, { customer, order_contents } }
  end

  def handle_cast({ :add, new_order_contents }, { customer, order_contents }) do
    { :noreply, { customer, order_contents ++ new_order_contents } }
  end

  def handle_call({ :contents }, _from, state = { _, order_contents }) do
    { :reply, order_contents, state }
  end

  def handle_cast({ :stop }, state) do
    {:stop, :normal, state}
  end

  def terminate(reason, { customer, order_contents }) do
    Logger.warn("Terminating #{customer} reason #{reason}")
    case reason do
      :normal -> Horde.DynamicSupervisor.terminate_child(ExCluster.OrderSupervisor, self())
      _ -> ExCluster.StateHandoff.handoff(customer, order_contents)
    end
    :ok
  end
end
