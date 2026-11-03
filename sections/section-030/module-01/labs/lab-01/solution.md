# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-030/module-01/labs/lab-01
```

## Step 1: Read the faults

```sh
kubectl -n starfleet logs deployment/gateway
kubectl -n starfleet get configmap gateway-config -o jsonpath='{.data.config\.yaml}'
```

The log shows export errors for an endpoint that ends in `:14317`. The configuration has no `service.telemetry` block, no processors and a `queue_size` of 100. The backend Service listens for OTLP gRPC on port 4317.

## Step 2: Save the fixed configuration

Save this as `gateway-config.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: gateway-config
  namespace: starfleet
data:
  config.yaml: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
    processors:
      memory_limiter:
        check_interval: 1s
        limit_mib: 200
        spike_limit_mib: 40
      batch:
        timeout: 1s
    exporters:
      otlp:
        endpoint: backend.starfleet.svc.cluster.local:4317
        tls:
          insecure: true
        sending_queue:
          queue_size: 5000
        retry_on_failure:
          enabled: true
          max_elapsed_time: 120s
    extensions:
      health_check:
        endpoint: 0.0.0.0:13133
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
          processors: [memory_limiter, batch]
          exporters: [otlp]
```

Apply it:

```sh
kubectl apply -f gateway-config.yaml
```

The ConfigMap now holds four changes: the telemetry reader on `0.0.0.0:8888` (the default is `127.0.0.1`, which a Service cannot reach), the correct exporter port, the two processors with `memory_limiter` first, and a queue of 5000.

## Step 3: Set the container memory limit

The `memory_limiter` limit of 200 MiB must stay below the container limit, or the kernel stops the container before the limiter acts. Save this as `gateway-resources.yaml`:

```yaml
spec:
  template:
    spec:
      containers:
        - name: collector
          resources:
            requests:
              cpu: 50m
              memory: 128Mi
            limits:
              memory: 256Mi
```

Apply it as a patch:

```sh
kubectl -n starfleet patch deployment gateway --patch-file gateway-resources.yaml
```

The container is named `collector`, so the patch merges into it by name.

## Step 4: Restart the gateway

The Collector reads its file once at start, so a ConfigMap change needs a new pod. The patch in the previous step already starts a rollout, and this command makes sure the new pod uses the new ConfigMap:

```sh
kubectl -n starfleet rollout restart deployment/gateway
kubectl -n starfleet rollout status deployment/gateway
```

## Step 5: Check

Send a span and read the metrics from the `drifter` pod:

```sh
kubectl -n outpost exec deploy/drifter -- curl -s http://gateway.starfleet.svc.cluster.local:8888/metrics | grep -E 'otelcol_exporter_queue_(size|capacity)'
```

The queue capacity line shows 5000 and the queue size is 0 or small. Then confirm that spans arrive at the backend:

```sh
kubectl -n starfleet logs deployment/backend --tail=20
```

## Step 6: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-030/module-01/labs/lab-01
```

If a check fails, read its hint. Typical causes: the gateway pod still runs the old ConfigMap, `limit_mib` is not below the container limit, or the processors list is not in the flow style.

## Clean up

```sh
astrona destroy ats-075-lab-030-01
```
