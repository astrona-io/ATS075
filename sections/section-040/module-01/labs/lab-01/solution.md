# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-040/module-01/labs/lab-01
```

Paste the helpers from the question into your terminal.

## Step 1: Read the starting point

```sh
kubectl -n starfleet get configmap collector-config -o jsonpath='{.data.config\.yaml}'
```

The file defines `otlphttp/backend` and `attributes/redact`, but the list `service.pipelines.traces.exporters` holds only `debug`, and the list `processors` holds only `batch`. A component that is defined but not listed in a pipeline is never started, so the `gateway` handles each span alone and the `backend` receives nothing.

## Step 2: Write the full configuration

Save this as `collector-config.yaml`. The processors of `traces` run in list order, so `attributes/redact` comes before `batch`, and both exporters receive the redacted data. The pipeline `logs` lists the same receiver `otlp`, so one listener on port 4318 serves both signals.

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
          processors: [attributes/redact, batch]
          exporters: [debug, otlphttp/backend]
        logs:
          receivers: [otlp]
          processors: [batch]
          exporters: [debug, otlphttp/backend]
```

## Step 3: Apply it and restart the gateway

Apply it:

```sh
kubectl apply -f collector-config.yaml
```

Then restart the Deployment, because the Collector reads its file once at start, and wait for the new pod:

```sh
kubectl -n starfleet rollout restart deployment/gateway
kubectl -n starfleet rollout status deployment/gateway
```

If the new pod does not become ready, read `kubectl -n starfleet logs deploy/gateway`. The first error line names the component or the key that the Collector rejected.

## Step 4: Send each signal and check both logs

```sh
send_trace lab-span-1
send_log lab-log-1
kubectl -n starfleet logs deploy/backend --since=5m | grep -E 'lab-span-1|lab-log-1|pilot@example.com'
```

Both status codes are `HTTP 200`. The last command prints lines that hold `lab-span-1` and `lab-log-1`. It prints no line with `pilot@example.com`, because `attributes/redact` deleted the attribute before the `batch` processor and the exporters saw the span. Run the same `grep` on `kubectl -n starfleet logs deploy/gateway` to confirm the `debug` exporter of the `gateway` printed the span without the attribute as well.

Submit the result:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-040/module-01/labs/lab-01
```

All four checks pass when the traces and the log record arrive, the email address is absent, and the `gateway` is healthy.
