# Question

Solve this question on: `terminal`

The `scout` workloads send OpenTelemetry traces, metrics and logs to the agent Collector `otelcol` in the namespace `starfleet`. The agent must forward all three signals to the gateway Collector in the namespace `outpost`. Today nothing reaches the gateway. The agent reads its configuration from the key `config.yaml` of the ConfigMap `otelcol-config`, mounted at `/conf`.

Fix the agent so that all of these are true:

1. The OTLP/HTTP receiver `otlp` accepts requests from other pods on port 4318 through the Service `otelcol`.
2. The `traces` pipeline uses the processors `memory_limiter` and `batch`, in this order, and exports to both `debug` and `otlphttp/gateway`.
3. A `metrics` pipeline and a `logs` pipeline exist. Each uses `otlp`, then `memory_limiter` and `batch` in this order, and exports to `otlphttp/gateway`.
4. The `health_check` extension stays enabled, and the Deployment `otelcol` keeps its image.

Do not change the gateway in `outpost` or the `shuttle` pod. The Collector reads its configuration only at start, so restart the Deployment after you change the ConfigMap. `kubectl` already points at the cluster.
