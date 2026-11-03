# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-040/module-02/labs/lab-01
```

Paste the helpers from the question into your terminal.

## Step 1: Reproduce the blocked request

```sh
send_trace before-fix
```

The request does not return `HTTP 200` within the 15-second limit of the helper. The exporter `otlphttp/archive` has no queue, so the export runs inside the request. The address `archive.starfleet.svc.cluster.local` does not resolve, every attempt fails, and the exporter waits with its retry back-off before it tries again. The receiver cannot answer the sender until the exporter returns.

## Step 2: Write the full configuration

Save this as `collector-config.yaml`. The exporter `otlphttp/archive` now has `sending_queue.enabled: true`. The request adds the data to the queue and returns, and queue workers retry in the background. The connector `count` is listed as an exporter of the `traces` pipeline and as the receiver of the `metrics` pipeline, which exports the counts to `otlphttp/backend`.

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
        metrics:
          receivers: [count]
          exporters: [otlphttp/backend]
```

## Step 3: Apply it and restart the gateway

Apply it:

```sh
kubectl apply -f collector-config.yaml
```

Then restart the Deployment and wait for the new pod:

```sh
kubectl -n starfleet rollout restart deployment/gateway
kubectl -n starfleet rollout status deployment/gateway
```

If the new pod exits, read `kubectl -n starfleet logs deploy/gateway`. A connector that appears on only one side of a pair makes the Collector refuse to start, and the message names the connector.

## Step 4: Check the three results

```sh
send_trace after-fix
kubectl -n starfleet logs deploy/backend --since=5m | grep -E 'after-fix|trace.span.count'
kubectl -n starfleet exec deploy/shuttle -- curl -s http://gateway.starfleet.svc.cluster.local:8888/metrics | grep otelcol_exporter_queue_capacity
```

The helper prints `HTTP 200` quickly. The `backend` log shows the span name `after-fix` and the metric name `trace.span.count`. The metrics list a queue capacity for `otlphttp/archive`. Look at `otelcol_exporter_queue_size` for that exporter as well: it counts the batches that wait for a retry.

Submit the result:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-040/module-02/labs/lab-01
```
