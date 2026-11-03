# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-030/module-02/labs/lab-01
```

## Step 1: Read the current state

```sh
kubectl -n starfleet get pods -l app=sampler
kubectl -n starfleet get endpoints sampler-headless
```

Two sampler pods run. The headless Service lists both pod addresses, which is what the `dns` resolver reads. The `sampler` ClusterIP Service hides the pods behind one address, and a gRPC client keeps one connection to it. That is why one pod gets all spans.

## Step 2: Save the new gateway configuration

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

The `load_balancing` exporter hashes the trace ID of each span and picks one backend from the list that the `dns` resolver returns. The `protocol.otlp` block is the template for the child exporter that it creates for each backend. It does not take an `endpoint`, because the resolver sets it.

## Step 3: Restart the gateway

```sh
kubectl -n starfleet rollout restart deployment/gateway
kubectl -n starfleet rollout status deployment/gateway
```

## Step 4: Test the routing

Send three spans of one trace in three separate requests, one with status 2 (error), and read the sampler logs. The helper function `send_span` is the one from the playground:

```sh
send_span() {
  kubectl -n outpost exec deploy/drifter -- curl -s -o /dev/null -w '%{http_code}\n' \
    -X POST -H 'Content-Type: application/json' \
    -d "{\"resourceSpans\":[{\"resource\":{\"attributes\":[{\"key\":\"service.name\",\"value\":{\"stringValue\":\"$4\"}}]},\"scopeSpans\":[{\"spans\":[{\"traceId\":\"$1\",\"spanId\":\"$2\",\"name\":\"$3\",\"kind\":1,\"startTimeUnixNano\":\"1700000000000000000\",\"endTimeUnixNano\":\"1700000001000000000\",\"status\":{\"code\":$5}}]}]}]}" \
    http://gateway.starfleet.svc.cluster.local:4318/v1/traces
}
send_span 0123456789abcdef0123456789abcdef 0000000000000001 first scout 0
send_span 0123456789abcdef0123456789abcdef 0000000000000002 second probe 2
send_span 0123456789abcdef0123456789abcdef 0000000000000003 third shuttle 0
sleep 12
kubectl -n starfleet logs -l app=sampler --prefix --tail=-1 | grep 0123456789abcdef0123456789abcdef
```

Each `send_span` call prints 200. After the decision wait, three lines with the trace ID appear, all with the same pod name in front. A different trace ID goes through a hash again, so it can land on the other pod.

## Step 5: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-030/module-02/labs/lab-01
```

If a check fails, read its hint. Typical causes: the gateway pod still runs the old ConfigMap, `routing_key` is `service`, or the resolver hostname is the ClusterIP Service `sampler` instead of the headless Service.

## Clean up

```sh
astrona destroy ats-075-lab-030-02
```
