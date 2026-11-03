# Overview: Capacity Signals And Protecting The Collector (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a gateway Collector and a backend Collector, and then waits. There is no task, no `astrona submit` and no pass or fail. Edit the gateway, break it, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator.

  | Namespace | What is in it |
  | --- | --- |
  | `starfleet` | `gateway` (receives OTLP, runs `memory_limiter` and `batch`, exports to `backend`, exposes metrics on 8888) and `backend` (prints spans with the debug exporter) |
  | `outpost` | `drifter`, a pod with `curl` that you use to send spans and read metrics |

- The gateway reads its configuration from the ConfigMap `gateway-config` (key `config.yaml`), mounted at `/conf`. Edit the ConfigMap and run `kubectl -n starfleet rollout restart deployment/gateway`.

## Helpers

Paste these once in each new terminal. `gateway_metrics` reads the gateway self-telemetry through the Service. `send_span` sends one span to the gateway with OTLP over HTTP and prints the HTTP status.

```sh
gateway_metrics() {
  kubectl -n outpost exec deploy/drifter -- curl -s http://gateway.starfleet.svc.cluster.local:8888/metrics
}
send_span() {
  kubectl -n outpost exec deploy/drifter -- curl -s -o /dev/null -w '%{http_code}\n' \
    -X POST -H 'Content-Type: application/json' \
    -d "{\"resourceSpans\":[{\"resource\":{\"attributes\":[{\"key\":\"service.name\",\"value\":{\"stringValue\":\"scout\"}}]},\"scopeSpans\":[{\"spans\":[{\"traceId\":\"5b8efff798038103d269b633813fc60c\",\"spanId\":\"eee19b7ec3c1b174\",\"name\":\"$1\",\"kind\":1,\"startTimeUnixNano\":\"1700000000000000000\",\"endTimeUnixNano\":\"1700000001000000000\"}]}]}]}" \
    http://gateway.starfleet.svc.cluster.local:4318/v1/traces
}
```

Use them like this: `send_span first-span` and `gateway_metrics | grep queue`.

## Practice tasks

- Send a span and find its name in `kubectl -n starfleet logs deployment/backend`. Then read `otelcol_receiver_accepted_spans` and `otelcol_exporter_sent_spans` on port 8888.
- Scale the backend to zero with `kubectl -n starfleet scale deployment/backend --replicas=0`, send ten spans, and watch `otelcol_exporter_queue_size` and `otelcol_exporter_send_failed_spans` change. Scale it back to one and watch the queue drain.
- Lower `limit_mib` in the gateway ConfigMap to a very small value, restart the gateway, send spans, and read `otelcol_processor_refused_spans` and the HTTP status of `send_span`.
- Scale the gateway to two replicas and compare the metrics of each pod. Which pod did the Service send your span to?
