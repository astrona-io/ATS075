# Overview: The Transform Processor And Data Safety (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a running OpenTelemetry Collector and waits. There is no task, no `astrona submit` and no pass or fail. Edit the configuration, send test telemetry, read what the Collector prints, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- The namespace `otel` with a Deployment named `collector` that runs `otel/opentelemetry-collector-contrib:0.162.0`. It reads `/conf/config.yaml` from the ConfigMap `collector-config`.
- The Collector listens for OTLP over HTTP on port 4318 and answers health checks on port 13133. Its three pipelines (traces, metrics and logs) have no processors and one exporter, `debug`, with `verbosity: detailed`. Everything the Collector receives is printed to its log.
- A pod named `sender` that runs curl. It posts test telemetry to `http://collector:4318` from inside the cluster.

The pipelines are empty on purpose: you add the transform processor and the statements yourself.

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

- Send a span whose `url.full` holds a token, add a `replace_pattern` statement, and compare the log before and after.
- Remove the `where ... != nil` guard, send a span without `url.full`, and read the Collector log for the error line.
- Set `error_mode: propagate` and repeat. Check whether the span still arrives.
- Send two metric data points that differ only by `user.id`, then delete `user.id` with `delete_key` and count the data points that the debug exporter prints.
- Put a second `debug` exporter in a separate pipeline, then place the transform processor in only one of the two pipelines and see which output still holds the secret.
