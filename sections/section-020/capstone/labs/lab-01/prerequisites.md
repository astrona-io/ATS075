# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl` and `jq`.
- You know how a Collector agent enriches telemetry with the `k8sattributes` and `resourcedetection` processors, and how a gateway Deployment holds credentials and exports to a backend.

The lab starts a single-node kind cluster (Kubernetes 1.35) with a backend Collector, an agent DaemonSet and a `shuttle` client pod in the `starfleet` namespace. The commands for the lab are in the README of this folder.
