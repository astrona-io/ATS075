# Overview: Attributes, Resources And Filtering (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a running OpenTelemetry Collector and waits. There is no task, no `astrona submit` and no pass or fail. Edit the configuration, send test telemetry, read what the Collector prints, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- The namespace `otel` with a Deployment named `collector` that runs `otel/opentelemetry-collector-contrib:0.162.0`. It reads `/conf/config.yaml` from the ConfigMap `collector-config`.
- The Collector listens for OTLP over HTTP on port 4318 and answers health checks on port 13133. Its three pipelines (traces, metrics and logs) have no processors and one exporter, `debug`, with `verbosity: detailed`. Everything the Collector receives is printed to its log.
- A pod named `sender` that runs curl. It posts test telemetry to `http://collector:4318` from inside the cluster.

The pipelines are empty on purpose: you add the resource, attributes and filter processors yourself.

## Helpers

Paste this once in each new terminal. It posts the JSON document that arrives on standard input to the Collector. The first argument is the signal: `traces`, `metrics` or `logs`.

```sh
send() { kubectl -n otel exec -i sender -- curl -s -o /dev/null -w '%{http_code}\n' -H 'Content-Type: application/json' -X POST "http://collector:4318/v1/$1" -d @-; }
```

Use it like this: `send traces < span.json`. A status of `200` means the Collector accepted the data. To change the configuration, edit the ConfigMap manifest, apply it, and restart the Deployment:

```sh
kubectl -n otel rollout restart deployment/collector && kubectl -n otel rollout status deployment/collector
```

Read the output with `kubectl -n otel logs deploy/collector --tail=80`.

## Practice tasks

- Send a span with a `host.name` resource attribute, then add a `resource` processor that deletes it and read the log again.
- Send the same span twice, once with an `insert` action and once with an `upsert` action for an attribute that already exists. Compare the values.
- Add an attributes processor with `hash` for `user.email` and check that the value in the log changed.
- Write a filter condition that drops spans by `span.name`, then change `error_mode` to `propagate` and break the condition on purpose to see what happens to the data.
- Swap the order of the attributes processor and the filter processor so that a filter reads an attribute before and after a change.
