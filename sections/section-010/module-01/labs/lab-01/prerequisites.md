# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl`.
- You know how to read a ConfigMap and a Deployment, and how to read a pod log with `kubectl logs`.
- You know what a receiver, a processor, an exporter and a pipeline are in a Collector configuration.
The lab starts a single-node kind cluster (Kubernetes 1.35) with a gateway Collector in `outpost`, a `shuttle` sender pod and an agent Collector in `starfleet`.
