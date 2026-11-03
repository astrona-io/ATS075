---
draft: true
exam_objectives:
- Configuration
---
# Extensions, Named Instances And Validation

Pipelines move data, but a running Collector also needs behaviour around them: a way to ask whether it is healthy, and sometimes a second listener or a second exporter with different settings. This part covers extensions, which add that supporting behaviour, and named instances, which let a file hold more than one component of the same type. It ends with the habit of validating the full set of files before a restart.

## Extensions

An extension is a component that is not in the data path. It never sees traces, metrics or logs. It adds a function to the Collector as a whole. The `health_check` extension opens an HTTP endpoint that answers whether the Collector is running. Other extensions provide authentication, persistent storage or diagnostic pages. Some of these are used by other components. An exporter can name an authentication extension, for example, and the Collector connects them.

An extension follows the same two-step rule as a pipeline component. It is defined under `extensions`, and it runs only when it is listed under `service.extensions`. The `health_check` extension has an `endpoint` setting (the address and port to listen on) and a `path` setting (the URL path, `/` by default). Its endpoint defaults to `localhost`, so a Kubernetes probe or a Service must use `0.0.0.0` to reach it. The answer is HTTP status `200` while the Collector is healthy and `503` when it is not ready.

Kubernetes uses this directly. A `readinessProbe` that calls the health port decides whether the Service sends traffic to the pod. A `livenessProbe` decides whether the kubelet, the node agent that runs containers, restarts the container. If the extension is not enabled, the port is closed, a probe fails and the pod never becomes ready.

<!-- astrona:playground:renew -->

Check this on the playground agent. Save these helper functions as `helpers.sh`. `send_otlp` posts a JSON file and prints the HTTP status code, `apply_config` stores `base.yaml` and `override.yaml` in the ConfigMap `otelcol-config`, restarts the agent and waits, and `validate_config` runs `otelcol-contrib validate` on two files in a short-lived pod, passing the text of each file in an environment variable:

```sh
send_otlp() {
  kubectl -n starfleet exec -i deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' -H 'Content-Type: application/json' -d @- "http://otelcol.starfleet.svc.cluster.local:$2/v1/$1" < "$3"
}
agent_logs() { kubectl -n starfleet logs deploy/otelcol --tail="${1:-60}"; }
apply_config() {
  kubectl -n starfleet create configmap otelcol-config --from-file=base.yaml --from-file=override.yaml --dry-run=client -o yaml | kubectl apply -f - && kubectl -n starfleet rollout restart deployment/otelcol && kubectl -n starfleet rollout status deployment/otelcol --timeout=120s
}
validate_config() {
  kubectl -n starfleet run validate --rm -i --restart=Never --quiet --image=otel/opentelemetry-collector-contrib:0.162.0 --image-pull-policy=IfNotPresent --env="BASE=$(cat "$1")" --env="OVERRIDE=$(cat "$2")" --env=GATEWAY_ENDPOINT=http://gateway.outpost.svc.cluster.local:4318 --command -- /otelcol-contrib validate --config=env:BASE --config=env:OVERRIDE
}
```

```sh
source helpers.sh
```

Save the base file as `base.yaml`. It defines the `health_check` extension, but `service` does not list it yet:

```yaml
extensions:
  health_check:
    endpoint: 0.0.0.0:13133
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318
processors:
  batch: {}
exporters:
  debug:
    verbosity: basic
  otlphttp/gateway:
    endpoint: ${env:GATEWAY_ENDPOINT}
service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug, otlphttp/gateway]
```

Save an override file that only keeps the debug exporter as it is. Save it as `override.yaml`, validate both files, apply them and call the health port from the `shuttle` pod:

```yaml
exporters:
  debug:
    verbosity: basic
```

```sh
validate_config base.yaml override.yaml
apply_config
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://otelcol.starfleet.svc.cluster.local:13133/
```

`validate_config` prints no error: the file is valid. The call to port 13133 prints `000`. The extension is defined, but `service.extensions` does not list it, so the Collector never started it and nothing listens on that port. Add this to the `service` section of `base.yaml`, directly above `pipelines:`, so that it reads `extensions: [health_check]` at the same indentation as `pipelines`, then apply and call the port again. The status code is `200` now.

## Named instances

A component identifier has the form `type` or `type/name`. The part after the slash is a free name. It lets a file hold several components of the same type, each with its own settings, and the full identifier is what a pipeline lists. The `otlp` receiver and the `otlp/second` receiver are two receivers of the same type with two listeners. The same works for exporters (`debug` and `debug/detailed`), processors and pipelines (`traces` and `traces/slow`).

A second instance needs a reason: a different port, a different destination or different settings. It does not create a copy of the first. The identifier must be unique, and a typo in a pipeline list is an error because the Collector finds no definition for the typed name.

Save a new override file as `override.yaml`. It defines a second receiver on port 4319 and a second debug exporter that prints the full data. The lists of the traces pipeline are written out completely, because a list in this file replaces the list in `base.yaml`:

```yaml
receivers:
  otlp/second:
    protocols:
      http:
        endpoint: 0.0.0.0:4319
exporters:
  debug/detailed:
    verbosity: detailed
service:
  pipelines:
    traces:
      receivers: [otlp, otlp/second]
      exporters: [debug/detailed, otlphttp/gateway]
```

Validate, apply and send a span to the second port. Save a span as `span.json` first (the same JSON as before: a `resourceSpans` object with one span named `read-sensor`):

```json
{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"scout"}}]},"scopeSpans":[{"scope":{"name":"manual"},"spans":[{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"eee19b7ec3c1b174","name":"read-sensor","kind":1,"startTimeUnixNano":"1700000000000000000","endTimeUnixNano":"1700000001000000000"}]}]}]}
```

```sh
validate_config base.yaml override.yaml
apply_config
send_otlp traces 4319 span.json
agent_logs 40
```

The status code is `200` on port 4319, and the agent log shows the full span from the `debug/detailed` exporter. Port 4318 still works too, because the list names both receivers. The key habit here is `validate_config` before `apply_config`. The validate command loads the same files in the same order as a real start, so it finds a typo in an identifier, a reference to a missing component and a setting with the wrong type before the pod restarts. If a new pod fails anyway, the Deployment keeps the old pod running until the new one is ready, and `kubectl logs` on the new pod shows the reason.

You can now enable an extension, give a component more than one instance and check the whole set of files before a rollout. Together with environment values and several sources, that covers how a Collector configuration is assembled and how it is changed safely.

## Common pitfalls

> [!WARNING]
> Do not assume that defining an extension starts it: list it under `service.extensions`. Do not bind `health_check` to `localhost` if a probe or Service must reach it. A second instance such as `otlp/second` is a new listener, so it needs its own port and, in Kubernetes, a Service port or a container port that matches. Validate the merged files before every restart, and read the pod log when a new pod does not become ready.
