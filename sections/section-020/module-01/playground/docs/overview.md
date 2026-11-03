# Overview: Agent Deployment Patterns (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with one Collector agent and one client pod, and then waits. There is no task, no `astrona submit` and no pass or fail. Send telemetry, edit the agent configuration, restart the agent, read the output, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator.
- The workloads in the `starfleet` namespace:

  | Object | What it is |
  | --- | --- |
  | DaemonSet `otel-agent` | The Collector (`otel/opentelemetry-collector-contrib:0.162.0`), one pod per node. It runs `--config=/conf/config.yaml` from the ConfigMap `otel-agent-config` |
  | Service `otel-agent` | Port 4318 (OTLP over HTTP). `internalTrafficPolicy: Local` sends a request to the agent pod on the caller's own node |
  | ServiceAccount `otel-agent` | The identity of the agent. It has no RBAC rule yet |
  | Deployment `shuttle` | A pod that runs `curl`. Use it as the application that sends telemetry |

- The starting configuration has one `otlp` receiver (HTTP), one `debug` exporter with `verbosity: detailed` and one `traces` pipeline. It adds no attributes.

## Helpers

Paste these once in each new terminal. `send_trace` posts one span as OTLP/HTTP JSON from the `shuttle` pod to the agent and prints the HTTP status. `agent_logs` prints the recent agent output.

```sh
send_trace() {
  kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 \
    -X POST -H 'Content-Type: application/json' \
    -d '{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"'"$1"'"}}]},"scopeSpans":[{"scope":{"name":"playground"},"spans":[{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"eee19b7ec3c1b174","name":"demo","kind":2,"startTimeUnixNano":"1700000000000000000","endTimeUnixNano":"1700000001000000000"}]}]}]}' \
    http://otel-agent.starfleet.svc:4318/v1/traces
}
agent_logs() {
  kubectl -n starfleet logs -l app=otel-agent --tail="${1:-80}"
}
```

Use them like this: `send_trace scout` and then `agent_logs`. A status of `200` means the agent accepted the span.

## Practice tasks

- Send a trace and find the resource attributes in the debug output. Note which Kubernetes attributes are missing.
- Add the `k8sattributes` processor, watch the permission error in the agent log, add a ClusterRole and a ClusterRoleBinding, and watch the attributes appear.
- Add the `resourcedetection` processor with the `env` and `system` detectors and set `OTEL_RESOURCE_ATTRIBUTES` on the DaemonSet.
- Add the `hostmetrics` receiver with the `load` and `memory` scrapers and a `metrics` pipeline.
- Delete the agent pod and send a trace while it restarts. Write down what the sender sees.
