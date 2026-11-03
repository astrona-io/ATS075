# Question

Solve this question on: `terminal`

The platform team runs an OpenTelemetry Collector (`otel/opentelemetry-collector-contrib:0.162.0`) in the namespace `otel`. The Deployment `collector` reads its configuration from the ConfigMap `collector-config`, key `config.yaml`. The configuration has an OTLP/HTTP receiver, a `debug` exporter with `verbosity: detailed`, a `health_check` extension and three pipelines (traces, metrics, logs) with no processors. A pod named `sender` runs curl. The services send data that must not leave the Collector as it is. Add one `transform` processor named `transform/redact` to all three pipelines, so that the data reaching the exporter follows these rules:

1. In every span, the query parameter `token` in the attribute `url.full` keeps its name but its value is replaced by `REDACTED`. For the value `https://scout.starfleet.test/api?token=abc&page=1` the result is `https://scout.starfleet.test/api?token=REDACTED&page=1`.

2. The span attributes `http.request.header.authorization` and `user.email` are removed. Other span attributes stay.

3. In every log record whose body is a string, the digits after `card=` are replaced by four asterisks, so that `card=4111111111111111` becomes `card=****`.

4. The data point attribute `user.id` is removed from metric data points. The attribute `route` stays.

5. A span that has no `url.full` attribute must still arrive with all its attributes. The processor must not drop it.

Do not change the receiver, the exporter or the extension. After you change the ConfigMap, restart the Deployment: the Collector reads its configuration only at start. `kubectl` already points at the cluster. You can post test telemetry with `kubectl -n otel exec -i sender -- curl ...` to `http://collector.otel.svc.cluster.local:4318/v1/traces`, `/v1/logs` and `/v1/metrics`, and read the debug exporter output with `kubectl -n otel logs deploy/collector`.
