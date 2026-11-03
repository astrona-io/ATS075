# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You know the Collector configuration sections (`receivers`, `processors`, `exporters`, `service.pipelines`) and how a ClusterRole and a ClusterRoleBinding work.

The lab starts a single-node kind cluster (Kubernetes 1.35) with a Collector agent DaemonSet and a `shuttle` client pod in the `starfleet` namespace. The commands for the lab are in the README of this folder.
