defmodule SampleWorker do
@doc """
  A simple GenServer that has functions that control its lifecycle

  ## Examples

      iex> {:ok, worker_sup} = Pooly.WorkerSupervisor.start_link({SampleWorker, :start_link, []})
      iex> Supervisor.start_child(worker_sup, [[]])
      {:ok, #PID<0.132.0>}

      iex> Supervisor.which_children(worker_sup)
      [{:undefined, #PID<0.98.0>, :worker, [SampleWorker]}, {:undefined, #PID<0.101.0>, :worker, [SampleWorker]}]

      iex> Supervisor.count_children(worker_sup)
      %{active: 2, specs: 1, supervisors: 0, workers: 2}

  """
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end
end
