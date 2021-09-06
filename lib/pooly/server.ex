defmodule Pooly.Server do
  use GenServer

  import Supervisor.Spec

  #######
  # API #
  #######

  def start_link(pools_config) do
    GenServer.start_link(__MODULE__, [pools_config], name: __MODULE__)
  end

  def checkout(pool_name) do
    GenServer.call(:"#{pool_name}Server", :checkout)
  end

  def checkin(pool_name, worker_pid) do
    GenServer.cast(:"#{pool_name}Server", {:checkin, worker_pid})
  end

  def status(pool_name) do
    GenServer.call(:"#{pool_name}Server", :status)
  end

  ######################
  # CALLBACK FUNCTIONS #
  ######################

  def init(pools_config) do
    # iterate through the configuration and send the :start_pool message to itself
    pools_config |> Enum.each(fn (pool_config) ->
      send(self(), {:start_pool, pool_config})
    end)
    {:ok, pools_config}
  end

  def handle_info({:start_pool, pool_config}, state) do
    # on receiving the message, pass pool_config to PoolsSupervisor
    {:ok, _pool_sup} = Supervisor.start_child(Pooly.PoolsSupervisor, supervisor_spec(pool_config))

    {:noreply, state}
  end

  #####################
  # PRIVATE FUNCTIONS #
  #####################

  defp supervisor_spec(pool_config) do
    # generate a unique Supervisor spec (due to the "id" option)
    opts = [id: :"#{pool_config[:name]}Supervisor"]

    supervisor(Pooly.PoolSupervisor, [pool_config], opts)
  end
end
