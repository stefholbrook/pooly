defmodule Pooly.PoolsSupervisor do
  use Supervisor

  def start_link do
    # start the supervisor and give it the same name as the module
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    # specify restart strategy
    opts = [strategy: :one_for_one]

    supervise([], opts)
  end
end
