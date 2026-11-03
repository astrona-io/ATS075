# Overview: Connectors, Backpressure And Failure Behavior (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with two OpenTelemetry Collectors and a curl client, and then waits. There is no task, no `astrona submit` and no pass or fail. Edit the configuration, send data, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator. Everything runs in the namespace `starfleet`.

  | Workload | What it does |
  | --- | --- |
  | `gateway` | The Collector you edit (image `otel/opentelemetry-collector-contrib:0.162.0`). Its configuration is the key `config.yaml` of the ConfigMap `collector-config`, mounted at `/conf`. It listens for OTLP over HTTP on port 4318, serves its own metrics on port 8888 and a health check on port 13133 |
  | `backend` | A second Collector that receives OTLP over HTTP on port 4318 and prints every trace, metric and log with the `debug` exporter at `detailed` verbosity |
  | `shuttle` | A pod that runs `sleep` and has `curl`. You send telemetry from it |

- The `gateway` has one pipeline, `traces`. It removes the attribute `user.email` and then exports to three exporters: `otlphttp/archive`, `otlphttp/backend` and `debug`. The Service `archive` does not exist, so every export to `otlphttp/archive` fails. The exporter keeps its default queue and retry settings. No connector is defined.

## Change the gateway configuration

Edit the ConfigMap and restart the Deployment, because the Collector reads its file once at start:

```sh
kubectl -n starfleet edit configmap collector-config
kubectl -n starfleet rollout restart deployment/gateway
kubectl -n starfleet rollout status deployment/gateway
```

If the new file is wrong, the new pod exits and the old pod keeps running until the new one is ready. Read the error with `kubectl -n starfleet logs deploy/gateway`.

## Helpers

Paste these once in each new terminal. Each helper posts one OTLP/HTTP JSON request from the `shuttle` pod to the `gateway` Service and prints the HTTP status code. The argument is a marker (the span name, the log text or the metric name) that you search for later. The trace helper always adds the attribute `user.email` with the value `pilot@example.com`, so you can see which Collector output still holds it.

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

Search for a marker in the signals that the `backend` Collector received with `kubectl -n starfleet logs deploy/backend --since=5m | grep <marker>`. The `gateway` Collector prints what it processed with its own `debug` exporter, so `kubectl -n starfleet logs deploy/gateway --since=5m` shows that side.

Read the gateway's own metrics with a request to port 8888:

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s http://gateway.starfleet.svc.cluster.local:8888/metrics | grep -E 'otelcol_exporter_(queue|send_failed|enqueue_failed)'
```

## Practice tasks

- Send a trace with `send_trace first-span` and check the status code. Find the span in the `backend` log even though `otlphttp/archive` fails.
- Add `sending_queue: {enabled: false}` to `otlphttp/archive`, restart, and send again. Note the status code and how long the request takes.
- Define the connector `count` (`connectors: {count: {}}`), add it to the exporters of `traces`, add a pipeline `metrics` with `count` as the receiver and `otlphttp/backend` as the exporter, and look for `trace.span.count` in the `backend` log.
- Remove `count` from the traces exporters only, restart, and read the startup error in the gateway log.
- Read the queue metrics for `otlphttp/archive` and watch `otelcol_exporter_queue_size` while you send ten traces.
