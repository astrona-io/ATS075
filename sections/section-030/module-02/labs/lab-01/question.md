# Question

Solve this question on: `terminal`

The `sampler` Deployment in `starfleet` has two pods. Each runs the `tail_sampling` processor with one policy: keep a trace when one of its spans has status ERROR. The `gateway` Collector receives spans from many services and sends them to the samplers. Today the gateway uses a plain `otlp` exporter that points at the Service `sampler`. The pods can be reached by the headless Service `sampler-headless` on port 4317. The gateway configuration is the ConfigMap `gateway-config`, key `config.yaml`. `kubectl` points at the cluster as the cluster administrator.

The team sees two problems. One sampler pod gets all the spans while the other idles. And once the load is spread, spans of one trace must not be split over two pods, because the error span would be judged without its other spans.

1. Change the gateway so that it sends traces with the `load_balancing` exporter. Route by `traceID`. Use the `dns` resolver on `sampler-headless.starfleet.svc.cluster.local`, port 4317, and send with TLS disabled (`insecure`). Keep `memory_limiter` and `batch` in the pipeline.

2. After the change, spans with the same trace ID must reach the same sampler pod, even when they arrive in different requests and carry different `service.name` values.

3. Spans with different trace IDs must reach both sampler pods.

Do not change the sampler Deployment or its ConfigMap. Do not remove the second sampler pod.
