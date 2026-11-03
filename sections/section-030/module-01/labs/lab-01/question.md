# Question

Solve this question on: `terminal`

The `gateway` Collector in `starfleet` receives traces on ports 4317 and 4318 and forwards them to the `backend` Collector, which prints them with the debug exporter. The `drifter` pod in `outpost` runs `curl`. The gateway configuration is the ConfigMap `gateway-config`, key `config.yaml`. The gateway is hard to operate: spans never arrive, and the team cannot see why. `kubectl` points at the cluster as the cluster administrator.

1. Make the gateway expose its own metrics on port 8888, so that `http://gateway.starfleet.svc.cluster.local:8888/metrics` answers from the `drifter` pod.

2. Fix the gateway so that a span sent with OTLP over HTTP to port 4318 reaches the `backend` Collector. Read the gateway log to find the fault. Do not change the `backend` Collector.

3. Protect the gateway. In the traces pipeline, `memory_limiter` must be the first processor and `batch` must follow it. Set a memory limit on the gateway container, and set `limit_mib` in `memory_limiter` to a value below that limit.

4. Make the exporter queue larger: the running gateway must report `otelcol_exporter_queue_capacity` of at least 5000.

Keep the processors in the flow style that the file already uses for lists (`processors: [memory_limiter, batch]`). Do not delete the gateway Deployment or the Service.
