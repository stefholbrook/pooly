defmodule Pooly do
  # make Pooly an OTP application
  use Application

  alias Pooly.{
    Server,
    Supervisor
  }

  # start/2 is called first when Pooly is initialized
  # predefine a pool configuration and call start_pool/1 out of convenience
  def start(_type, _args) do
    pool_config = [mfa: {SampleWorker, :start_link, []}, size: 5]
    start_pool(pool_config)
  end

  def start_pool(pool_config) do
    Supervisor.start_link(pool_config)
  end

  def checkout do
    Server.checkout()
  end

  def checkin(worker_pid) do
    Server.checkin(worker_pid)
  end

  def status do
    Server.status()
  end
end
