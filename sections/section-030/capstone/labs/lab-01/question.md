# Question

Solve this question on: `terminal`

The `starfleet` namespace runs a small Collector fleet. The `gateway` Collector receives OTLP from services, and sends traces to two `sampler` pods that run `tail_sampling`. A `scraper` StatefulSet with two pods scrapes the metrics endpoints (port 8888) of the gateway, the samplers and the scrapers themselves with the `prometheus` receiver, and prints what it scraped with the debug exporter. The `drifter` pod in `outpost` runs `curl`. The configuration of each Collector is a ConfigMap (`gateway-config`, `sampler-config`, `scraper-config`, key `config.yaml`). `kubectl` points at the cluster as the cluster administrator.

The fleet works on a quiet day and fails under load. Fix it.

1. The gateway has no protection against memory growth and no sizeable queue. In the traces pipeline, `memory_limiter` must be the first processor and `batch` must follow. Give the gateway container a memory limit, and keep `limit_mib` below it. The running gateway must report an exporter queue capacity of at least 5000.

2. The gateway hides its own metrics. They must answer at `http://gateway.starfleet.svc.cluster.local:8888/metrics` from the `drifter` pod.

3. The gateway sends all spans to one sampler pod. Use the `load_balancing` exporter, routed by `traceID`, with the `dns` resolver on the headless Service `sampler-headless.starfleet.svc.cluster.local`, port 4317, TLS disabled. Spans of one trace, sent in separate requests with different `service.name` values, must be kept whole by exactly one sampler pod, and different traces must reach both pods.

4. Both scraper pods scrape all three targets, so every series is stored twice. Shard the scrape: each target must appear in the log of exactly one scraper pod, and the StatefulSet must keep two pods. Each pod has the environment variable `SHARD` set to its index, 0 or 1.

Keep the processors in the flow style that the files already use for lists. Do not scale the samplers or the scrapers down, and do not delete the Services.
