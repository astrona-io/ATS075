---
draft: true
exam_objectives:
  - Scaling
---
# Sharding And Stateful Processing

Adding replicas is easy when each batch of data stands alone. It becomes a design problem when a component needs related data in one place. Tail sampling needs every span of a trace on the same instance, or it decides on half a trace. A pull receiver that is run twice scrapes every target twice, and the backend stores every sample twice. This module shows how to scale such components: route data by a key so that related items meet, and divide scrape targets so that each target has one owner.

You will run a gateway layer that routes by trace ID to two sampler pods, send traces and see which pod holds each one, break the routing on purpose, and shard a scraping StatefulSet so that no target is scraped twice.

## Learning Goals

- Explain why a stateless gateway scales with replicas behind a Service, and why a long-lived connection can leave a replica idle.
- Explain why `tail_sampling` needs all spans of a trace on one instance and describe the two-layer design that provides it.
- Configure the `load_balancing` exporter with a routing key and a resolver, and say what happens when the set of backends changes.
- Explain how replicated pull receivers create duplicates and how `hashmod` relabeling, a StatefulSet and the Target Allocator avoid them.
- Name the cases where duplicates still occur after correct sharding.

## Before You Start

You need the self-telemetry and the memory limiter from the capacity module, and the basics of the `tail_sampling` processor. You do not need to know the `load_balancing` exporter or Prometheus relabeling.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. The Collector image is `otel/opentelemetry-collector-contrib:0.162.0`.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | `gateway`, which receives OTLP and sends each span to a sampler chosen by trace ID. `sampler`, two pods with `tail_sampling` that keep traces with an error span. `scraper`, a StatefulSet with two pods and the `prometheus` receiver |
| `outpost` | `drifter`, a pod with `curl` that sends test spans |

## Reading Order

1. Stateless Replicas Behind A Service
2. Routing By Trace ID For Tail Sampling
3. Sharding Scrapes And Avoiding Duplicates
4. Summary

<!-- astrona:playground -->
