---
draft: true
exam_objectives:
  - Scaling
---
# Capacity Signals And Protecting The Collector

A Collector that works with ten spans a second can fail with ten thousand. When it fails, the symptom is rarely a clean error. Spans go missing, senders time out, or the pod restarts with an out-of-memory kill. This module teaches how to find out what is happening from the Collector itself, how to protect a Collector so that overload slows data down and does not crash the process, and how to decide between giving one Collector more resources and running more Collectors.

The Collector writes metrics about its own work and serves them on port 8888. Those numbers tell you whether the receiver, the processors or the exporter is the part that cannot keep up. You will read them in a running gateway Collector, force a backlog on purpose, trigger the memory limiter, and scale the gateway to two replicas.

## Learning Goals

- Name the self-telemetry metrics for accepted, refused and failed spans and for the exporter queue, and say what each one tells you.
- Tell a source bottleneck from a processor bottleneck and a destination bottleneck by reading those metrics.
- Configure `sending_queue`, `retry_on_failure`, `memory_limiter` and `batch`, and explain what each one does when the load is too high.
- Explain the soft limit and the hard limit of `memory_limiter` and why it must be the first processor.
- Compare vertical scaling with horizontal scaling and say when a stateless gateway can use replicas.

## Before You Start

You need Kubernetes basics (namespaces, Deployments, ConfigMaps, Services, `kubectl`) and the shape of a Collector configuration: receivers, processors, exporters and `service` pipelines. You do not need to know the Collector self-telemetry or the memory limiter.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. The Collector image is `otel/opentelemetry-collector-contrib:0.162.0`.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | `gateway`, a Collector that receives OTLP, runs `memory_limiter` and `batch`, exports to `backend` and serves its own metrics on port 8888. `backend`, a Collector that prints every span with the debug exporter |
| `outpost` | `drifter`, a pod with `curl` that sends test spans and reads metrics |

`kubectl` already points at the playground cluster, as the cluster administrator.

## Reading Order

1. Reading The Collector's Own Metrics
2. Queues, Retries And Memory Limits
3. Vertical And Horizontal Scaling
4. Summary

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
