# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl` and `jq`.
- You know what a Collector receiver, processor and exporter are, how to read a Collector configuration file in YAML, and how to read pod logs with `kubectl logs`.

The lab starts a single-node kind cluster (Kubernetes 1.35) with two OpenTelemetry Collectors and a curl client. You install nothing on your own machine. The cluster pulls the images, so the machine needs access to the internet.
