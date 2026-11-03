# Solution

Solve this lab on `terminal`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-010/capstone/labs/lab-01
```

`astrona submit` right after the start shows that `agent-ready` and `config-validates` pass. The other checks fail.

## Step 1: Read both files and find the faults

Print the two files:

```sh
kubectl -n starfleet get configmap otelcol-config -o jsonpath='{.data.base\.yaml}'
kubectl -n starfleet get configmap otelcol-config -o jsonpath='{.data.override\.yaml}'
```

Five faults are visible. The receiver listens on `localhost:4318`. The `authorization` header holds a literal token. The `health_check` extension is defined and not listed under `service.extensions`. Only a `traces` pipeline exists. In `override.yaml`, the `exporters` list of the `traces` pipeline is `[debug]`, and a list in the second file replaces the list in the first file, so the merged traces pipeline never uses `otlphttp/gateway`. The environment attribute is the literal `staging`.

## Step 2: Write the corrected files

Save this as `otelcol-config.yaml`. `base.yaml` now binds the listener to all addresses, reads the token from `${env:BACKEND_TOKEN}`, enables the extension and defines three pipelines. `override.yaml` adds the named receiver `otlp/second`, reads the environment value from `${env:DEPLOY_ENV}` and restates every list that it changes, because a list in the second file replaces the list in the first file:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: otelcol-config
  namespace: starfleet
data:
  base.yaml: |
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
        endpoint: ${env:GATEWAY_ENDPOINT}
        headers:
          authorization: "Bearer ${env:BACKEND_TOKEN}"
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
  override.yaml: |
    receivers:
      otlp/second:
        protocols:
          http:
            endpoint: 0.0.0.0:4319
    processors:
      resource:
        attributes:
          - key: deployment.environment
            value: ${env:DEPLOY_ENV}
            action: upsert
    service:
      pipelines:
        traces:
          receivers: [otlp, otlp/second]
          processors: [memory_limiter, resource, batch]
          exporters: [debug, otlphttp/gateway]
        metrics:
          receivers: [otlp, otlp/second]
        logs:
          receivers: [otlp, otlp/second]
```

Apply it and restart the agent:

```sh
kubectl apply -f otelcol-config.yaml
kubectl -n starfleet rollout restart deployment/otelcol
kubectl -n starfleet rollout status deployment/otelcol --timeout=120s
```

## Step 3: Validate and check

Run the validate command from a short-lived pod, with the two files in environment variables. Save the files first as `base.yaml` and `override.yaml` (the text of the two keys in `otelcol-config.yaml`):

```sh
kubectl -n starfleet run validate --rm -i --restart=Never --quiet --image=otel/opentelemetry-collector-contrib:0.162.0 --image-pull-policy=IfNotPresent --env="BASE=$(cat base.yaml)" --env="OVERRIDE=$(cat override.yaml)" --command -- /otelcol-contrib validate --config=env:BASE --config=env:OVERRIDE
```

A valid configuration prints no error. Then grade:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-010/capstone/labs/lab-01
```

All seven checks pass. Clean up with `astrona destroy ats-075-capstone-010`.
