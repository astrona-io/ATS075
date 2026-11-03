# Question

Solve this question on: `terminal`

The `gateway` Collector in the namespace `starfleet` receives OpenTelemetry data from the `scout` service and forwards it. Its configuration is the key `config.yaml` of the ConfigMap `collector-config`. A second Collector named `backend` receives data from the `gateway` and prints it. `kubectl` already points at the cluster as the cluster administrator. The `gateway` reads its configuration only at start, so restart it after every change with `kubectl -n starfleet rollout restart deployment/gateway`.

The `traces` pipeline of the `gateway` exports to three exporters: `otlphttp/archive`, `otlphttp/backend` and `debug`. The `archive` Service does not exist yet, so every export to `otlphttp/archive` fails. The exporter has its sending queue switched off (`sending_queue.enabled: false`). The team wants to keep the archive exporter, because the archive will be created later.

Paste these helpers once. Each one posts one OTLP/HTTP JSON request from the `shuttle` pod to the `gateway` and prints the HTTP status code. The argument is a marker that you can search for in the logs.

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

Change the `gateway` configuration so that all of the following are true:

1. A sender that posts a trace gets HTTP `200` in under 10 seconds, and the span reaches the `backend` and the `debug` output of the `gateway`, even though the archive address does not exist. Do not remove `otlphttp/archive` from the `traces` pipeline.

2. The exporter `otlphttp/archive` runs with a sending queue. The gateway metrics on port 8888 must list `otelcol_exporter_queue_capacity` for it.

3. A connector named `count` counts the spans of the `traces` pipeline. The metric `trace.span.count` must reach the `backend`. Use a pipeline named `metrics` that has `count` as its receiver and `otlphttp/backend` as its exporter.

4. The `gateway` Deployment stays available and its health check on port 13133 answers `200`.

Do not change the `backend` Collector, the `shuttle` pod or the Services.
