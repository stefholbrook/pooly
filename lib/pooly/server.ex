defmodule Pooly.Server do
  use GenServer

  import Supervisor.Spec

  defmodule State do
    # struct that maintains the state of the server
    defstruct sup: nil, worker_sup: nil, size: nil, mfa: nil, workers: nil, monitors: nil
  end

  #######
  # API #
  #######

  # A valid pool configuration looks like this: [mfa: {SampleWorker, :start_link, []}, size: 5]
  def start_link(sup, pool_config) do
    GenServer.start_link(__MODULE__, [sup, pool_config], name: __MODULE__)
  end

  def checkout do
    GenServer.call(__MODULE__, :checkout)
  end

  def checkin(worker_pid) do
    GenServer.call(__MODULE__, {:checkin, worker_pid})
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  ######################
  # CALLBACK FUNCTIONS #
  ######################

  # validate the pool config and initialize the state
  def init([sup, pool_config]) when is_pid(sup) do
    # set the server process to trap exits (can now handle :EXIT message from workers)
    Process.flag(:trap_exit, true)
    # update init to create monitors field in ets table
    monitors = :ets.new(:monitors, [:private])
    # init(pool_config, %State{sup: sup})
    # update state to store the monitors table
    init(pool_config, %State{sup: sup, monitors: monitors})
  end

  # pattern-match for the mfa config option and store in server's state
  def init([{:mfa, mfa} | rest], state) do
    init(rest, %{state | mfa: mfa})
  end

  # pattern-match for the size config option and store in server's state
  def init([{:size, size} | rest], state) do
    init(rest, %{state | size: size})
  end

  # ignore all other options
  def init([_ | rest], state) do
    init(rest, state)
  end

  # base case when the options list is empty
  def init([], state) do
    # send message to start the worker supervisor
    send(self(), :start_worker_supervisor)
    {:ok, state}
  end

  # handle send() message
  def handle_info(:start_worker_supervisor, state = %{sup: sup, mfa: mfa, size: size}) do
    # start the worker Supervisor process via the top-level Supervisor
    {:ok, worker_sup} = Supervisor.start_child(sup, supervisor_spec(mfa))
    # create "size" number of workers that are supervised with the newly created Supervisor
    workers = prepopulate(size, worker_sup)
    # update the state with the worker Supervisor pid and its supervised workers
    {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  end

  # monitor the :DOWN message of a consumer process (when a consumer process crashes, it shouldn't crash the server process)
  def handle_info({:DOWN, ref, _, _, _}, state = %{monitors: monitors, workers: workers}) do
    # when a consumer process goes down, match the reference in the monitors ETS table
    case :ets.match(monitors, {:"$1", ref}) do
      [[pid]] ->
        # delete the monitor
        true = :ets.delete(monitors, pid)
        # and add the worker back into the state and return the worker to the pool
        new_state = %{state | workers: [pid | workers]}
        {:noreply, new_state}

      [[]] ->
        {:noreply, state}
    end
  end

  def handle_info({:EXIT, pid, _reason}, state = %{monitors: monitors, workers: workers, worker_sup: worker_sup}) do
    # when a worker process exits unexpectedly, lookup the entry in the monitors ETS table
    case :ets.lookup(monitors, pid) do
      # if a process is found
      [{pid, ref}] ->
        # stop monitoring it
        true = Process.demonitor(ref)
        # remove it from the table
        true = :ets.delete(monitors, pid)

        # create a new worker and add it to the server state
        new_state = %{state | workers: [new_worker(worker_sup) | workers]}

        {:noreply, new_state}
      [[]] ->
        {:noreply, state}
    end
  end

  # pattern-match the pid of the client, workers, and monitors
  def handle_call(:checkout, {from_pid, _ref}, %{workers: workers, monitors: monitors} = state) do
    # handles the case when there are workers left to checkout
    case workers do
      [worker | rest] ->
        # get the server process to monitor the client process
        ref = Process.monitor(from_pid)
        # updates the monitors in the ets table
        true = :ets.insert(monitors, {worker, ref})

        {:reply, worker, %{state | workers: rest}}

      [] ->
        {:reply, :noproc, state}
    end
  end

  def handle_call(:status, _from, %{workers: workers, monitors: monitors} = state) do
    # information about the number of workers available and the number of checked out (busy) workers
    {:reply, {length(workers), :ets.info(monitors, :size)}, state}
  end

  def handle_cast({:checkin, worker}, %{workers: workers, monitors: monitors} = state) do
    case :ets.lookup(monitors, worker) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)

        {:noreply, %{state | workers: [pid | workers]}}

      [] ->
        {:noreply, state}
    end
  end

  #####################
  # PRIVATE FUNCTIONS #
  #####################

  defp supervisor_spec(mfa) do
    # top-level supervisor won't automatically restart the worker Supervisor so we can pass customer recovery rules
    opts = [restart: :temporary]
    # specify that the process to be specified is a Supervisor, instead fo a worker
    supervisor(Pooly.WorkerSupervisor, [mfa], opts)
  end

  # build a list of `size` number of workers
  defp prepopulate(size, sup) do
    prepopulate(size, sup, [])
  end

  defp prepopulate(size, _sup, workers) when size < 1, do: workers

  defp prepopulate(size, sup, workers) do
    # create a list of workers attached to the worker Supervisor
    prepopulate(size-1, sup, [new_worker(sup) | workers])
  end

  defp new_worker(sup) do
    # dynamically create a worker process and attach it to the Supervisor
    {:ok, worker} = Supervisor.start_child(sup, [[]])
    worker
  end
end
