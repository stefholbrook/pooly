defmodule Pooly.WorkerSupervisor do
  use Supervisor

  #######
  # API #
  #######

  # pattern match the args to make sure they're a tuple containing three elements
  # m = module, f = function, a = list of args
  def start_link(pool_server, {_, _, _} = mfa) do
    Supervisor.start_link(__MODULE__, [pool_server, mfa])
  end

  ######################
  # CALLBACK FUNCTIONS #
  ######################

  # pattern match the individual elements from the three-element tuple
  def init([pool_server, {m, f, a}]) do
    Process.link(pool_server)
    # specify that the worker is always to be restarted
    worker_opts = [
      restart: :temporary,
      shutdown: 5000,
      function: f
    ]
    # specify the function to start the worker
    # worker/3 is the child specification (recipe for supervisor to spawn children)
    children = [worker(m, a, worker_opts)]
    # specify the options for the supervisor
    opts = [strategy: :simple_one_for_one, max_restarts: 5, max_seconds: 5]

    # helper function to create the child specification
    supervise(children, opts)
  end
end
