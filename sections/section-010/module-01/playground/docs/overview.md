# Overview: Component Definitions And Enabled Pipelines (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with an OpenTelemetry Collector and a backend, and then waits. There is no task, no `astrona submit` and no pass or fail. Change the Collector configuration, restart it, send telemetry, read what arrives, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- Three workloads:

  | Namespace | Object | What it is |
  | --- | --- | --- |
  | `starfleet` | Deployment `otelcol` and Service `otelcol` | The agent Collector (`otel/opentelemetry-collector-contrib:0.162.0`). It reads the ConfigMap `otelcol-config` (key `config.yaml`) from `/conf`. |
  | `starfleet` | Deployment `shuttle` | A pod with `curl` that sends OTLP/HTTP requests to the agent. |
  | `outpost` | Deployment `gateway` and Service `gateway` | A second Collector that acts as the backend. It receives OTLP and prints every span, metric and log record with the `debug` exporter (`verbosity: detailed`). |

- The agent starts with one receiver (`otlp`, HTTP on `0.0.0.0:4318`), one processor (`batch`), the exporters `debug` and `otlphttp/gateway`, the `health_check` extension and one pipeline: `traces` with `otlp`, `batch` and `debug`. The exporter `otlphttp/gateway` is defined but no pipeline uses it.
- The Collector reads its configuration only when it starts. After you change the ConfigMap, run `kubectl -n starfleet rollout restart deployment/otelcol`.

## Helpers

Paste these once in each new terminal. `send_otlp` posts a JSON file to the agent and prints the HTTP status code. `gateway_logs` and `agent_logs` print the end of the two Collector logs. `apply_config` stores a Collector configuration file in the ConfigMap `otelcol-config`, restarts the agent and waits for it. `validate_config` runs `otelcol-contrib validate` against a file in a short-lived pod.

```sh
send_otlp() {
  kubectl -n starfleet exec -i deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' -H 'Content-Type: application/json' -d @- "http://otelcol.starfleet.svc.cluster.local:$2/v1/$1" < "$3"
}
gateway_logs() { kubectl -n outpost logs deploy/gateway --tail="${1:-60}"; }
agent_logs() { kubectl -n starfleet logs deploy/otelcol --tail="${1:-60}"; }
apply_config() {
  kubectl -n starfleet create configmap otelcol-config --from-file=config.yaml="$1" --dry-run=client -o yaml | kubectl apply -f - && kubectl -n starfleet rollout restart deployment/otelcol && kubectl -n starfleet rollout status deployment/otelcol --timeout=120s
}
validate_config() {
  kubectl -n starfleet run validate --rm -i --restart=Never --quiet --image=otel/opentelemetry-collector-contrib:0.162.0 --image-pull-policy=IfNotPresent --env="CANDIDATE=$(cat "$1")" --command -- /otelcol-contrib validate --config=env:CANDIDATE
}
```

Use them like this: `send_otlp traces 4318 span.json`, `gateway_logs 40`, `apply_config config.yaml`, `validate_config candidate.yaml`.

## Practice tasks

- Send a span, a metric and a log record to the agent. Find out which of the three the agent accepts and which one the gateway shows.
- Enable `otlphttp/gateway` in the traces pipeline and send a span again. Find the span name in the gateway log.
- Add a `metrics` pipeline and a `logs` pipeline. Send one request for each signal and find each one in the gateway log.
- Put `batch` before `memory_limiter` in a pipeline and run `validate_config`. Decide whether the file is valid and whether it is a good file.
- Use the `prometheus` exporter in the `traces` pipeline. Run `validate_config` and then `apply_config`. Note which command reports the error and read the pod log if the new pod fails.
- Change `0.0.0.0:4318` to `localhost:4318`, restart the agent and send a span. Write down the status code and explain it.
- Run `kubectl -n starfleet exec deploy/otelcol -- /otelcol-contrib components` and find the exporters that the contrib distribution has.
