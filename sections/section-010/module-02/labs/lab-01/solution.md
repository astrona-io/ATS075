# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-010/module-02/labs/lab-01
```

`astrona submit` right after the start shows two checks that already pass: `agent-ready` and `primary-receiver`. The other four fail.

## Step 1: Read both files

Print the two files:

```sh
kubectl -n starfleet get configmap otelcol-config -o jsonpath='{.data.base\.yaml}'
kubectl -n starfleet get configmap otelcol-config -o jsonpath='{.data.override\.yaml}'
```

`base.yaml` has the literal token in the `authorization` header and defines `health_check` without listing it under `service.extensions`. `override.yaml` sets the environment attribute to the literal `staging`.

## Step 2: Write the corrected files

Save this as `otelcol-config.yaml`. It reads the token and the environment value from variables, enables the extension in `override.yaml` and defines `otlp/second`. In `override.yaml` the `receivers` list of the `traces` pipeline names both receivers, because a list in the second file replaces the list in the first file:

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
      pipelines:
        traces:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [debug, otlphttp/gateway]
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
      extensions: [health_check]
      pipelines:
        traces:
          receivers: [otlp, otlp/second]
          processors: [memory_limiter, resource, batch]
```

Apply it and restart the agent:

```sh
kubectl apply -f otelcol-config.yaml
kubectl -n starfleet rollout restart deployment/otelcol
kubectl -n starfleet rollout status deployment/otelcol --timeout=120s
```

If the new pod does not become ready, read the error with `kubectl -n starfleet logs deploy/otelcol`. The old pod keeps running while the new pod fails, because the Deployment replaces pods one at a time.

## Step 3: Check the result

Call the health endpoint from the `shuttle` pod and read the gateway log after a new request:

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://otelcol.starfleet.svc.cluster.local:13133/
kubectl -n outpost logs deploy/gateway --tail=40
```

The health call prints `200`. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-010/module-02/labs/lab-01
```

All six checks pass. Clean up with `astrona destroy ats-075-lab-010-02`.
