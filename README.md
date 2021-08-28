# Pooly

Supervisor excercise from Elixir & OTP book

## v1

* Support a single pool of fixed workers.
* no recovery handling when either the consumer or the worker process fails
* Consists of a top-level Supervisor `Pooly.Supervisor` that supervises two other processes:
  * A Genserver `Process.Server`
  * A worker Supervisor `Pooly.WorkerSupervisor`

### Design

* When is starts, only Pooly.Server is attached to Pooly.Supervisor
* When the pool is started with a pool configuration, Pooly, Server first verifies that the pool configuration is valid.
* Then it sends a :start_worker_supervisor to Pooly.Supervisor. This message instructs Pooly.Spervisor to start Pooly.WorkerSupervisor.
* Pooly.WorkerSupervisor is told to start a number of worker processes based on the size specified in the pool configuration.

```
      +----------------+
      |Pooly.Supervisor|
      +----------------+
          /       \
  +------------+ +------------------------+
  |Pooly.Server| | Pooly.WorkerSupervisor |
  +------------+ +------------------------+
                      /      |     \
                +------+ +---|--+ +------+
                |Worker| |Worker| |Worker|
                +------+ +------+ +------+
```
https://textik.com/
