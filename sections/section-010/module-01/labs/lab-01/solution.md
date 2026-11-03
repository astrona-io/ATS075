# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-010/module-01/labs/lab-01
```

`astrona submit` right after the start shows two checks that already pass: `agent-ready` and `gateway-unchanged`. The other three fail.

## Step 1: Read the configuration and the symptoms

Print the configuration that the agent runs:

```sh
kubectl -n starfleet get configmap otelcol-config -o jsonpath='{.data.config\.yaml}'
```

Three problems are visible. The receiver listens on `localhost:4318`, so only a process inside the pod can connect. The exporter `otlphttp/gateway` is defined under `exporters` but no pipeline lists it, so the Collector never starts it. Only a `traces` pipeline exists, so the Collector has no path for metrics or logs.

## Step 2: Write the corrected configuration

Save this as `otelcol-config.yaml`. It keeps the `health_check` extension, binds the receiver to all addresses, enables `otlphttp/gateway` and adds the two missing pipelines:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: otelcol-config
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
      memory_limiter:
        check_interval: 1s
        limit_mib: 150
        spike_limit_mib: 30
      batch: {}
    exporters:
      debug:
        verbosity: basic
      otlphttp/gateway:
        endpoint: http://gateway.outpost.svc.cluster.local:4318
    service:
      extensions: [health_check]
      pipelines:
        traces:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [debug, otlphttp/gateway]
        metrics:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [otlphttp/gateway]
        logs:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [otlphttp/gateway]
```

Apply it and restart the agent, because the Collector reads the file only when it starts:

```sh
kubectl apply -f otelcol-config.yaml
kubectl -n starfleet rollout restart deployment/otelcol
kubectl -n starfleet rollout status deployment/otelcol --timeout=120s
```

The new pod becomes ready only after the `health_check` extension answers, which is why the extension must stay in the file.

## Step 3: Send telemetry and read the gateway log

Save this as `span.json`:

```json
{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"scout"}}]},"scopeSpans":[{"scope":{"name":"manual"},"spans":[{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"eee19b7ec3c1b174","name":"lab-span","kind":1,"startTimeUnixNano":"1700000000000000000","endTimeUnixNano":"1700000001000000000"}]}]}]}
```

Send it through the agent and look for the span name in the gateway log:

```sh
kubectl -n starfleet exec -i deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' -H 'Content-Type: application/json' -d @- http://otelcol.starfleet.svc.cluster.local:4318/v1/traces < span.json
kubectl -n outpost logs deploy/gateway --tail=60
```

The status code is `200` and the log has a span named `lab-span`. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-010/module-01/labs/lab-01
```

All five checks pass. The check for metrics and logs sends its own requests, so you do not need to send them by hand. Clean up with `astrona destroy ats-075-lab-010-01`.
