# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 4 GiB of free memory.
- `kubectl` and `jq`.
- You know what a headless Service is, what the `tail_sampling` processor needs from its input, and how the `load_balancing` exporter picks a backend.

The lab starts a single-node kind cluster (Kubernetes 1.35) and applies plain manifests. The cluster pulls `otel/opentelemetry-collector-contrib:0.162.0` and `curlimages/curl:8.22.0`, so the machine needs access to the internet. Starting the lab takes a few minutes.
