# Question

Solve this question on: `terminal`

The Starfleet gateway is an OpenTelemetry Collector (`otel/opentelemetry-collector-contrib:0.162.0`) in the namespace `otel`. The Deployment `collector` reads its configuration from the ConfigMap `collector-config`, key `config.yaml`. The configuration has an OTLP/HTTP receiver, a `debug` exporter with `verbosity: detailed`, a `health_check` extension and three pipelines (traces, metrics, logs) with no processors. A pod named `sender` runs curl. The security team wants the data to follow this policy before it reaches the exporter. All rules apply to all three pipelines unless a rule names a signal.

1. Resource: set the resource attribute `deployment.environment.name` to `starfleet-prod` and remove the resource attribute `host.name`. Keep the other resource attributes.

2. Privacy: remove the span attribute `http.request.header.authorization`. Replace the value of the span attribute `user.email` by a hash.

3. Redaction: in the span attribute `url.full`, replace the value of the query parameter `token` by `REDACTED` and keep the rest of the URL. In the span attribute `http.target`, remove the query string, so that `/orders?id=42` becomes `/orders`. In every string log body, replace the digits after `card=` by `****`. Remove the data point attribute `user.id` from metrics.

4. Noise: drop every span whose `http.target` is `/healthz`. Health checks send `/healthz` and also `/healthz?probe=...`. Both must be dropped. Drop log records below INFO (severity number 9). Drop the metric named `scout.debug.counter`.

5. Ordinary spans, log records and metrics must still arrive.

Choose the processors, write them with distinct names, and decide the order in each `processors` list. Do not change the receiver, the exporter or the extension. After you change the ConfigMap, restart the Deployment: the Collector reads its configuration only at start. `kubectl` already points at the cluster. You can post test telemetry with `kubectl -n otel exec -i sender -- curl ...` to `http://collector.otel.svc.cluster.local:4318/v1/traces`, `/v1/logs` and `/v1/metrics`, and read the debug exporter output with `kubectl -n otel logs deploy/collector`.
