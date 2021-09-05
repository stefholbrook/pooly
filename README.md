# Pooly

Supervisor excercise from Elixir & OTP book

## v1

* Support a single pool of fixed workers.
* no recovery handling when either the consumer or the worker process fails
* Consists of a top-level Supervisor `Pooly.Supervisor` that supervises two other processes:
  * A Genserver `Process.Server`
  * A worker Supervisor `Pooly.WorkerSupervisor`

### Design

* The top-level supervisor `Pooly.Supervisor` supervises a `Pooly.Server` and a `PoolsSupervisor`
* The `PoolsSupervisor` in turn supervises many `PoolSupervisors`
* Each `PoolSupervisor` supervises its own `PoolServer` and `WorkerSupervisor`

```
                              +----------------+
                              |Pooly.Supervisor|
                              +----------------+
                                  /       \
                        +------------+  +----------------+
                        |Pooly.Server|  |Pooly.Supervisor|
                        +------------+  +----------------+
                                          /              \
                        +----------------+               +----------------+
                        |Pooly.Supervisor|               |Pooly.Supervisor|
                        +----------------+               +----------------+
                         /       \                              /       \
            +------------+  +------------------------+        +------------+  +------------------------+
            |Pooly.Server|  | Pooly.WorkerSupervisor |        |Pooly.Server|  | Pooly.WorkerSupervisor |
            +------------+  +------------------------+        +------------+  +------------------------+
                                /      |     \                                      /      |     \
                          +------+ +---|--+ +------+                          +------+ +---|--+ +------+
                          |Worker| |Worker| |Worker|                          |Worker| |Worker| |Worker|
                          +------+ +------+ +------+                          +------+ +------+ +------+
```
https://textik.com/
