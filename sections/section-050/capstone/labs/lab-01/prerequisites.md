# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl`. The lab start pulls two small images (the Collector and curl), so the machine needs internet access unless they are already cached.
- You know what an OpenTelemetry Collector pipeline is (receivers, processors, exporters) and you can edit a Kubernetes ConfigMap.

The lab starts a single-node kind cluster (Kubernetes 1.35) with the Collector in the namespace `otel`. The start takes a few minutes.
