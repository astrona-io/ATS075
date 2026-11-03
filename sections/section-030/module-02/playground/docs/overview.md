# Overview: Sharding And Stateful Processing (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a gateway layer, a sampler layer and a scraper StatefulSet, and then waits. There is no task, no `astrona submit` and no pass or fail. Change the configuration, break it, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator.

  | Namespace | What is in it |
  | --- | --- |
  | `starfleet` | `gateway` (OTLP in, `load_balancing` exporter out, routed by `traceID`), `sampler` (two pods with `tail_sampling`, behind the Services `sampler` and `sampler-headless`) and `scraper` (a StatefulSet with two pods and the `prometheus` receiver) |
  | `outpost` | `drifter`, a pod with `curl` that you use to send spans |

- Each Collector reads its configuration from a ConfigMap (`gateway-config`, `sampler-config`, `scraper-config`, key `config.yaml`). Edit the ConfigMap and run `kubectl rollout restart` on the workload. Each scraper pod has the environment variable `SHARD` set to its pod index (0 or 1), ready for sharding.
- The `tail_sampling` policy on the samplers keeps a trace only when one of its spans has status ERROR. The samplers print kept spans with the debug exporter.

## Helpers

Paste these once in each new terminal. `send_span` sends one span to the gateway with OTLP over HTTP. Its arguments are the trace ID, the span ID, the span name, the service name and the status code (0 is unset, 2 is error). `sampler_logs` prints the log of every sampler pod, with the pod name in front of each line.

```sh
send_span() {
  kubectl -n outpost exec deploy/drifter -- curl -s -o /dev/null -w '%{http_code}\n' \
    -X POST -H 'Content-Type: application/json' \
    -d "{\"resourceSpans\":[{\"resource\":{\"attributes\":[{\"key\":\"service.name\",\"value\":{\"stringValue\":\"$4\"}}]},\"scopeSpans\":[{\"spans\":[{\"traceId\":\"$1\",\"spanId\":\"$2\",\"name\":\"$3\",\"kind\":1,\"startTimeUnixNano\":\"1700000000000000000\",\"endTimeUnixNano\":\"1700000001000000000\",\"status\":{\"code\":$5}}]}]}]}" \
    http://gateway.starfleet.svc.cluster.local:4318/v1/traces
}
sampler_logs() {
  kubectl -n starfleet logs -l app=sampler --prefix --tail=-1
}
```

Use them like this: `send_span 5b8efff798038103d269b633813fc60c eee19b7ec3c1b174 checkout scout 2` and then, after about ten seconds, `sampler_logs | grep checkout`.

## Practice tasks

- Send three spans of one trace (same trace ID, different span IDs and service names) in three separate calls, one of them with status 2. Find the pod whose log shows all three.
- Send the same three spans with different trace IDs, ten times. Count how many sampler pods hold traces.
- Change `routing_key` to `service` in `gateway-config`, restart the gateway and repeat the first task. What can happen to a trace whose spans come from different services?
- Read the logs of both `scraper` pods and look for lines with `service.instance.id`. Which targets appear in both pods?
- Add a `relabel_configs` block with `hashmod` and `keep` to the scrape job in `scraper-config`, restart the StatefulSet, and read both logs again.
