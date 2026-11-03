# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-030/capstone/labs/lab-01
```

## Step 1: Read the three faults

```sh
kubectl -n starfleet get configmap gateway-config -o jsonpath='{.data.config\.yaml}'
kubectl -n starfleet get configmap scraper-config -o jsonpath='{.data.config\.yaml}'
kubectl -n starfleet logs scraper-0 --tail=40 | grep service.instance.id
kubectl -n starfleet logs scraper-1 --tail=40 | grep service.instance.id
```

The gateway configuration has no processors, no telemetry reader and a queue of 100, and its exporter is a plain `otlp` exporter. The scraper configuration has one scrape job with three static targets and no relabeling. Both scraper logs list all three targets.

## Step 2: Save the gateway configuration

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
      load_balancing:
        routing_key: traceID
        protocol:
          otlp:
            tls:
              insecure: true
            sending_queue:
              queue_size: 5000
        resolver:
          dns:
            hostname: sampler-headless.starfleet.svc.cluster.local
            port: 4317
            interval: 5s
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
          exporters: [load_balancing]
```

Apply it:

```sh
kubectl apply -f gateway-config.yaml
```

This one file covers the protection, the self-telemetry and the routing. The queue size sits under `protocol.otlp`, because the `load_balancing` exporter creates one child `otlp` exporter for each sampler pod, and each child has its own queue.

## Step 3: Give the gateway a memory limit

Save this as `gateway-resources.yaml`:

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

Apply it as a patch, then restart the gateway so that it reads the ConfigMap:

```sh
kubectl -n starfleet patch deployment gateway --patch-file gateway-resources.yaml
kubectl -n starfleet rollout restart deployment/gateway
kubectl -n starfleet rollout status deployment/gateway
```

## Step 4: Save the sharded scraper configuration

Save this as `scraper-config.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: scraper-config
  namespace: starfleet
data:
  config.yaml: |
    receivers:
      prometheus:
        config:
          scrape_configs:
            - job_name: starfleet-collectors
              scrape_interval: 15s
              static_configs:
                - targets:
                    - gateway.starfleet.svc.cluster.local:8888
                    - sampler.starfleet.svc.cluster.local:8888
                    - scraper.starfleet.svc.cluster.local:8888
              relabel_configs:
                - source_labels: [__address__]
                  modulus: 2
                  target_label: __tmp_hash
                  action: hashmod
                - source_labels: [__tmp_hash]
                  regex: ${env:SHARD}
                  action: keep
    exporters:
      debug:
        verbosity: detailed
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
        metrics:
          receivers: [prometheus]
          exporters: [debug]
```

Apply it and restart the StatefulSet:

```sh
kubectl apply -f scraper-config.yaml
kubectl -n starfleet rollout restart statefulset/scraper
kubectl -n starfleet rollout status statefulset/scraper
```

The `hashmod` action hashes the address of each target and stores the remainder of a division by 2 in the temporary label `__tmp_hash`. The `keep` action then drops every target whose remainder differs from the `SHARD` value of the pod. Each target keeps a stable remainder, so exactly one pod scrapes it.

## Step 5: Check

Wait about 40 seconds for two scrape intervals, then read the scraper logs again:

```sh
kubectl -n starfleet logs scraper-0 --since=40s | grep service.instance.id
kubectl -n starfleet logs scraper-1 --since=40s | grep service.instance.id
kubectl -n outpost exec deploy/drifter -- curl -s http://gateway.starfleet.svc.cluster.local:8888/metrics | grep otelcol_exporter_queue_capacity
```

Each target appears in only one of the two logs. The queue capacity lines show 5000.

## Step 6: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-030/capstone/labs/lab-01
```

If a check fails, read its hint. Typical causes: a pod still runs an old ConfigMap, the scraper logs are older than 40 seconds, or the pipeline processors list is not in the flow style.

## Clean up

```sh
astrona destroy ats-075-capstone-030
```
