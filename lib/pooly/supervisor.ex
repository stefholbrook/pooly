defmodule Pooly.Supervisor do
  use Supervisor

  def start_link(pools_config) do
    Supervisor.start_link(__MODULE__, pools_config, name: __MODULE__)
  end

  def init(pools_config) do
    # only passing the server as child since the server starts the worker Supervisor
    children = [
      supervisor(Pooly.PoolsSupervisor, []),
      # can remove `self()` because name is being set to __MODULE__ and we can reference module name instead of PID
      # worker(Pooly.Server, [self(), pools_config])
      worker(Pooly.Server, [self(), pools_config])
    ]
    # if the server goes down take the worker Supervisor with it
    opts = [strategy: :one_for_all]

    supervise(children, opts)
  end
end
