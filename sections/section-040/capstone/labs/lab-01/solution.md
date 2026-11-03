# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-040/capstone/labs/lab-01
```

Paste the helpers from the question into your terminal.

## Step 1: Read the startup error

```sh
kubectl -n starfleet get pods -l app=gateway
kubectl -n starfleet logs deploy/gateway
```

The `gateway` pod is not ready and restarts. The log names the connector `count` and says that it is used as a receiver in the `metrics` pipeline but not as an exporter in any pipeline of a supported signal. The Collector checks every connector pair when it starts, and it refuses to run when one side is missing.

## Step 2: Plan the fix

Four more problems sit behind the first error. The exporter `otlphttp/backend` and the processor `attributes/redact` are defined but unused. The exporter `otlphttp/archive` has no sending queue, so the missing archive address would block the request. The file has no `logs` pipeline. All three pipelines share the one receiver `otlp`.

## Step 3: Write the full configuration

Save this as `collector-config.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: collector-config
  namespace: starfleet
data:
  config.yaml: |
    extensions:
      health_check:
        endpoint: 0.0.0.0:13133
    receivers:
      otlp:
        protocols:
          http:
            endpoint: 0.0.0.0:4318
    processors:
      batch:
        timeout: 1s
      attributes/redact:
        actions:
          - key: user.email
            action: delete
    exporters:
      debug:
        verbosity: detailed
      otlphttp/backend:
        endpoint: http://backend.starfleet.svc.cluster.local:4318
      otlphttp/archive:
        endpoint: http://archive.starfleet.svc.cluster.local:4318
        sending_queue:
          enabled: true
          queue_size: 100
    connectors:
      count: {}
    service:
      extensions: [health_check]
      telemetry:
        metrics:
          readers:
            - pull:
                exporter:
                  prometheus:
                    host: 0.0.0.0
                    port: 8888
      pipelines:
        traces:
          receivers: [otlp]
          processors: [attributes/redact]
          exporters: [otlphttp/archive, otlphttp/backend, debug, count]
        logs:
          receivers: [otlp]
          processors: [batch]
          exporters: [debug, otlphttp/backend]
        metrics:
          receivers: [otlp, count]
          processors: [batch]
          exporters: [debug, otlphttp/backend]
```

The `traces` pipeline lists `count` as an exporter, so every batch of spans also goes to the connector. The `metrics` pipeline lists `otlp` and `count` as receivers, so metrics from clients and the counts take the same path to the `backend`.

## Step 4: Apply it and restart the gateway

Apply it:

```sh
kubectl apply -f collector-config.yaml
```

Then restart the Deployment and wait for the new pod:

```sh
kubectl -n starfleet rollout restart deployment/gateway
kubectl -n starfleet rollout status deployment/gateway
```

## Step 5: Send each signal

```sh
send_trace cap-span
send_log cap-log
send_metric cap.metric
kubectl -n starfleet logs deploy/backend --since=5m | grep -E 'cap-span|cap-log|cap.metric|trace.span.count|pilot@example.com'
```

Each helper prints `HTTP 200`. The `grep` prints lines for the span, the log record, the metric and `trace.span.count`, and no line with `pilot@example.com`. Submit the result:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-040/capstone/labs/lab-01
```
