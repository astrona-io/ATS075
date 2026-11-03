# Question

Solve this question on: `terminal`

The Collector `gateway` in the namespace `starfleet` is the single entry point for OpenTelemetry data from the `scout` service. Its configuration is the key `config.yaml` of the ConfigMap `collector-config`. A second Collector named `backend` receives data from the `gateway` and prints it. `kubectl` already points at the cluster as the cluster administrator.

After the last change, the `gateway` pod does not start. Behind that fault, the configuration has more faults. The team needs one `gateway` that serves all three signals. The `gateway` reads its configuration only at start, so restart it after every change with `kubectl -n starfleet rollout restart deployment/gateway`. The Service `archive` does not exist yet, and the team keeps the archive exporter for later.

Paste these helpers once. Each one posts one OTLP/HTTP JSON request from the `shuttle` pod to the `gateway` and prints the HTTP status code. The argument is a marker that you can search for in the logs. `send_trace` always adds the attribute `user.email` with the value `pilot@example.com`.

```sh
send_trace() {
  now="$(date +%s)000000000"
  kubectl -n starfleet exec deploy/shuttle -- curl -s -m 15 -w '\nHTTP %{http_code}\n' -X POST -H 'Content-Type: application/json' \
    -d "{\"resourceSpans\":[{\"resource\":{\"attributes\":[{\"key\":\"service.name\",\"value\":{\"stringValue\":\"scout\"}}]},\"scopeSpans\":[{\"scope\":{\"name\":\"lab\"},\"spans\":[{\"traceId\":\"5b8efff798038103d269b633813fc60c\",\"spanId\":\"eee19b7ec3c1b174\",\"name\":\"$1\",\"kind\":1,\"startTimeUnixNano\":\"$now\",\"endTimeUnixNano\":\"$now\",\"attributes\":[{\"key\":\"user.email\",\"value\":{\"stringValue\":\"pilot@example.com\"}}]}]}]}]}" \
    http://gateway.starfleet.svc.cluster.local:4318/v1/traces
}

send_log() {
  now="$(date +%s)000000000"
  kubectl -n starfleet exec deploy/shuttle -- curl -s -m 15 -w '\nHTTP %{http_code}\n' -X POST -H 'Content-Type: application/json' \
    -d "{\"resourceLogs\":[{\"resource\":{\"attributes\":[{\"key\":\"service.name\",\"value\":{\"stringValue\":\"scout\"}}]},\"scopeLogs\":[{\"scope\":{\"name\":\"lab\"},\"logRecords\":[{\"timeUnixNano\":\"$now\",\"severityText\":\"INFO\",\"body\":{\"stringValue\":\"$1\"}}]}]}]}" \
    http://gateway.starfleet.svc.cluster.local:4318/v1/logs
}

send_metric() {
  now="$(date +%s)000000000"
  kubectl -n starfleet exec deploy/shuttle -- curl -s -m 15 -w '\nHTTP %{http_code}\n' -X POST -H 'Content-Type: application/json' \
    -d "{\"resourceMetrics\":[{\"resource\":{\"attributes\":[{\"key\":\"service.name\",\"value\":{\"stringValue\":\"scout\"}}]},\"scopeMetrics\":[{\"scope\":{\"name\":\"lab\"},\"metrics\":[{\"name\":\"$1\",\"sum\":{\"aggregationTemporality\":2,\"isMonotonic\":true,\"dataPoints\":[{\"asInt\":\"1\",\"timeUnixNano\":\"$now\"}]}}]}]}]}" \
    http://gateway.starfleet.svc.cluster.local:4318/v1/metrics
}
```

Repair the configuration so that all of the following are true:

1. The `gateway` Deployment is available and its health check on port 13133 answers `200`.

2. The `traces` pipeline removes the attribute `user.email` first. Neither the `gateway` log nor the `backend` log may contain `pilot@example.com`. The pipeline exports to `otlphttp/archive`, `otlphttp/backend` and `debug`.

3. A sender that posts a trace gets HTTP `200` in under 10 seconds even though the archive address does not exist. Keep `otlphttp/archive` in the pipeline and give it a sending queue. The gateway metrics on port 8888 must list `otelcol_exporter_queue_capacity` for it.

4. A pipeline named `logs` receives from the receiver `otlp` and exports to `otlphttp/backend`.

5. The pipeline named `metrics` receives metrics from `otlp` and counts from the connector `count`, and exports to `otlphttp/backend`. A metric posted over OTLP must appear in the `backend` log.

6. The connector `count` counts the spans of the `traces` pipeline, and the metric `trace.span.count` reaches the `backend`.

Use only one receiver `otlp` for all three signals. Do not change the `backend` Collector, the `shuttle` pod or the Services.
