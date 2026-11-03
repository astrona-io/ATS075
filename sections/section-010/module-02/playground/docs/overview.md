# Overview: Configuration Sources, Environment Values And Extensions (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with an OpenTelemetry Collector that reads two configuration files, and a backend. There is no task, no `astrona submit` and no pass or fail. Change the configuration, restart the Collector, send telemetry, read what arrives, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- Three workloads:

  | Namespace | Object | What it is |
  | --- | --- | --- |
  | `starfleet` | Deployment `otelcol` and Service `otelcol` | The agent Collector. It starts with `--config=/conf/base.yaml --config=/conf/override.yaml`. Both files are keys of the ConfigMap `otelcol-config`. The Service has the ports 4318, 4319 and 13133. |
  | `starfleet` | Deployment `shuttle` | A pod with `curl` that sends OTLP/HTTP requests to the agent. |
  | `outpost` | Deployment `gateway` and Service `gateway` | A second Collector that acts as the backend and prints everything it receives (`debug` exporter, `verbosity: detailed`). |

- The agent container has three environment variables: `GATEWAY_ENDPOINT` (the address of the gateway), `DEPLOY_ENV` (the text `outpost-test`) and `BACKEND_TOKEN` (the value of the key `token` in the Secret `gateway-token`).
- `base.yaml` defines one receiver, one processor, the exporters `debug` and `otlphttp/gateway` and a `traces` pipeline. It reads `GATEWAY_ENDPOINT` with `${env:GATEWAY_ENDPOINT}`. `override.yaml` has only a `debug` exporter setting. No file uses `DEPLOY_ENV` or `BACKEND_TOKEN`, and no extension is enabled.
- The Collector reads its configuration only when it starts. After you change the ConfigMap or an environment variable, run `kubectl -n starfleet rollout restart deployment/otelcol`.

## Helpers

Paste these once in each new terminal. `send_otlp` posts a JSON file to a port of the agent and prints the HTTP status code. `gateway_logs` and `agent_logs` print the end of the two Collector logs. `apply_config` stores the local files `base.yaml` and `override.yaml` in the ConfigMap `otelcol-config`, restarts the agent and waits for it. `validate_config` runs `otelcol-contrib validate` on a base file and an override file in a short-lived pod.

```sh
send_otlp() {
  kubectl -n starfleet exec -i deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' -H 'Content-Type: application/json' -d @- "http://otelcol.starfleet.svc.cluster.local:$2/v1/$1" < "$3"
}
gateway_logs() { kubectl -n outpost logs deploy/gateway --tail="${1:-60}"; }
agent_logs() { kubectl -n starfleet logs deploy/otelcol --tail="${1:-60}"; }
apply_config() {
  kubectl -n starfleet create configmap otelcol-config --from-file=base.yaml --from-file=override.yaml --dry-run=client -o yaml | kubectl apply -f - && kubectl -n starfleet rollout restart deployment/otelcol && kubectl -n starfleet rollout status deployment/otelcol --timeout=120s
}
validate_config() {
  kubectl -n starfleet run validate --rm -i --restart=Never --quiet --image=otel/opentelemetry-collector-contrib:0.162.0 --image-pull-policy=IfNotPresent --env="BASE=$(cat "$1")" --env="OVERRIDE=$(cat "$2")" --env=GATEWAY_ENDPOINT=http://gateway.outpost.svc.cluster.local:4318 --command -- /otelcol-contrib validate --config=env:BASE --config=env:OVERRIDE
}
```

Use them like this: `send_otlp traces 4318 span.json`, `gateway_logs 40`, `apply_config`, `validate_config base.yaml override.yaml`.

## Practice tasks

- Read the Deployment with `kubectl -n starfleet get deployment otelcol -o yaml`. Find where the three variables are defined and which one comes from a Secret.
- Add a `resource` processor that sets `deployment.environment` to `${env:DEPLOY_ENV}`. Send a span and read the attribute in the gateway log.
- Change the value of `DEPLOY_ENV` with `kubectl -n starfleet set env deployment/otelcol DEPLOY_ENV=changed`. Decide why the value in the gateway log changes only after the pod starts again.
- Set `exporters: [debug]` for the `traces` pipeline in `override.yaml` and send a span. Decide why the gateway receives nothing, and what the merged list is.
- Define the `health_check` extension without listing it in `service.extensions`, then list it. Call port 13133 from the `shuttle` pod each time.
- Add a second receiver `otlp/second` on port 4319 and send a span to it.
- Write the text `$${env:DEPLOY_ENV}` as the value of an attribute, send a span and read the value in the gateway log. Explain why it is not replaced.
