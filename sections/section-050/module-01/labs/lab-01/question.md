# Question

Solve this question on: `terminal`

The platform team runs an OpenTelemetry Collector (`otel/opentelemetry-collector-contrib:0.162.0`) in the namespace `otel`. The Deployment `collector` reads its configuration from the ConfigMap `collector-config`, key `config.yaml`, mounted at `/conf`. The configuration has an OTLP/HTTP receiver, a `debug` exporter with `verbosity: detailed`, a `health_check` extension and three pipelines (traces, metrics, logs) with no processors. A pod named `sender` runs curl. Services `scout` and `shuttle` send spans and logs that carry too much. Change the Collector so that the data leaving it follows these rules:

1. Every trace and log resource gets the resource attribute `deployment.environment.name` with the value `training`, and the resource attribute `host.name` is removed. All other resource attributes, such as `service.name`, stay.

2. The span attribute `http.request.header.authorization` is removed from traces and logs. The span attribute `user.email` stays, but its value is replaced by a hash. Other attributes stay unchanged.

3. Spans whose `http.route` attribute is `/healthz` are dropped. Spans with any other route are kept.

4. Log records with a severity number below INFO (the number 9) are dropped. Records at INFO and above are kept.

Use processors from the contrib distribution and add them to the pipelines in the `service` section. Do not change the receiver, the exporter or the extension. After you change the ConfigMap, restart the Deployment: the Collector reads its configuration only at start. `kubectl` already points at the cluster. You can post test telemetry with `kubectl -n otel exec -i sender -- curl ...` to `http://collector.otel.svc.cluster.local:4318/v1/traces` and `/v1/logs`, and read the debug exporter output with `kubectl -n otel logs deploy/collector`.
