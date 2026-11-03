# Question

Solve this question on: `terminal`

The `scout` service in `starfleet` sends OpenTelemetry data to the `gateway` Collector. The `gateway` runs in the namespace `starfleet` with the configuration in the ConfigMap `collector-config` (key `config.yaml`). A second Collector named `backend` receives data from the `gateway` and prints it. `kubectl` already points at the cluster as the cluster administrator.

At the start, the `gateway` has one pipeline named `traces` that exports spans only to its own `debug` exporter. The exporter `otlphttp/backend` and the processor `attributes/redact` are defined in the file, but no pipeline uses them. The `gateway` reads its configuration only at start, so restart it after every change with `kubectl -n starfleet rollout restart deployment/gateway`.

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

Change the `gateway` configuration so that all of the following are true:

1. The `traces` pipeline exports every span to both `debug` and `otlphttp/backend`. The span names must appear in the logs of both Collectors (`kubectl -n starfleet logs deploy/gateway` and `kubectl -n starfleet logs deploy/backend`).

2. The attribute `user.email` is removed before any exporter of the `traces` pipeline sees it. Neither the `gateway` log nor the `backend` log may contain `pilot@example.com`. Keep the `batch` processor, and put the processors in an order that works.

3. A new pipeline named `logs` receives data from the same receiver `otlp` that the `traces` pipeline uses (do not define a second receiver) and exports to `otlphttp/backend`. A log record posted to the `gateway` must appear in the `backend` log.

4. The `gateway` Deployment stays available and its health check on port 13133 answers `200`.

Do not change the `backend` Collector, the `shuttle` pod or the Services.
