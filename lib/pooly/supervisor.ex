defmodule Pooly.Supervisor do
  use Supervisor

  def start_link(pool_config) do
    Supervisor.start_link(__MODULE__, pool_config)
  end

  def init(pool_config) do
    # only passing the server as child since the server starts the worker Supervisor
    children = [worker(Pooly.Server, [self(), pool_config])]
    # if the server goes down take the worker Supervisor with it
    opts = [strategy: :one_for_all]

    supervise(children, opts)
  end
end
