# Overview: Gateway Deployment And Agent-To-Gateway Export (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a backend Collector, an agent and a client pod, and then waits. There is no task, no `astrona submit` and no pass or fail. Add a gateway, move the credentials, stop the backend, watch the retries, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator.
- The workloads in the `starfleet` namespace. Every Collector runs `otel/opentelemetry-collector-contrib:0.162.0` with `--config=/conf/config.yaml` from a ConfigMap:

  | Object | What it is |
  | --- | --- |
  | Deployment `otel-backend`, Service `otel-backend` (4318) | Stands in for the observability platform. Its `otlp` receiver uses the `basicauth/server` extension, so it answers `401` without the right user name and password. It prints what it accepts with the `debug` exporter |
  | DaemonSet `otel-agent`, Service `otel-agent` (4318) | The agent. It exports with `otlphttp` straight to the backend. The password is written in its ConfigMap `otel-agent-config` on purpose |
  | Secret `backend-credentials` | The user name `gateway` and its password. It belongs to the team that runs the gateway |
  | Secret `backend-htpasswd` | The htpasswd line that the backend uses to check the password |
  | Deployment `shuttle` | A pod that runs `curl`. Use it as the application that sends telemetry |

- There is no gateway Deployment yet. You create it while you work through the module.

## Helpers

Paste these once in each new terminal. `send_trace` posts one span as OTLP/HTTP JSON from the `shuttle` pod to the agent and prints the HTTP status. `backend_logs` prints the recent output of the backend.

```sh
send_trace() {
  kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 \
    -X POST -H 'Content-Type: application/json' \
    -d '{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"'"$1"'"}}]},"scopeSpans":[{"scope":{"name":"playground"},"spans":[{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"eee19b7ec3c1b174","name":"demo","kind":2,"startTimeUnixNano":"1700000000000000000","endTimeUnixNano":"1700000001000000000"}]}]}]}' \
    http://otel-agent.starfleet.svc:4318/v1/traces
}
backend_logs() {
  kubectl -n starfleet logs deploy/otel-backend --tail="${1:-80}"
}
```

Use them like this: `send_trace scout` and then `backend_logs`.

## Practice tasks

- Find the backend password with `kubectl get configmap otel-agent-config -n starfleet -o yaml`. Count how many places on the cluster hold it.
- Prove that the backend refuses a request without credentials: post to `http://otel-backend.starfleet.svc:4318/v1/traces` with `curl` and read the status.
- Create a gateway: a ConfigMap, a Deployment with two replicas and a Service named `otel-gateway`. Give the gateway the password from the Secret through an environment variable. Point the agent at the gateway and remove the password from the agent.
- Scale the backend to zero, send three traces, read the retry messages in the gateway log, scale the backend back to one replica and read the traces in the backend log.
- Delete one gateway pod while you send traces. Write down what the agent sees.
