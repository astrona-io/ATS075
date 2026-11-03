---
draft: true
exam_objectives:
- Pipelines
---
# Connectors, Backpressure And Failure Behavior

Pipelines do not stop at the edge of one signal, and they do not always work. A connector hands the output of one pipeline to another pipeline inside the same Collector. An exporter that cannot reach its destination holds, retries or drops data, and the way it does so decides what the sender and the other exporters experience. This module explains both with a gateway Collector that has an exporter pointed at an address that does not exist.

Keep one sentence in mind: **a failing exporter does not stay inside its own box unless its queue is on and big enough.** You will build a counting path with the `count` connector, read what the Collector reports when a connector is wired on one side only, watch the same failing exporter with the sending queue on and off, and read the queue metrics while the queue overflows.

The module has three parts. **Connectors Between Pipelines** shows a connector as an exporter in one pipeline and a receiver in another, the signal pairs and the start errors. **Sending Queue, Retry And Timeout** explains the three layers of a network exporter and what the sender sees with and without the queue. **Backpressure And Failing Exporters** fills a queue on purpose, follows the error back to the sender and reads the queue metrics.

## Learning Goals

- Wire a connector as an exporter of one pipeline and a receiver of another, and name the signal pairs of `forward`, `count` and span metrics.
- Read the start error for a connector that is used on one side only or for a component that does not support a signal.
- Explain `sending_queue`, `retry_on_failure` and `timeout`, and their defaults.
- Explain how a full queue or a blocked exporter affects the sender and the other exporters of a pipeline.
- Read the Collector's own metrics for queue size, capacity and failures.

## Before You Start

You need Kubernetes basics: namespaces, Deployments, ConfigMaps, `kubectl logs` and `kubectl apply`. You need to know that a Collector pipeline lists receivers, processors and exporters.

Your playground is a single-node `kind` cluster running Kubernetes 1.35, with these workloads in the namespace `starfleet`:

| Workload | What it does |
| --- | --- |
| `gateway` | The Collector you edit, image `otel/opentelemetry-collector-contrib:0.162.0`. Its file is the key `config.yaml` of the ConfigMap `collector-config`. Its traces pipeline exports to `otlphttp/archive` (the Service `archive` does not exist), `otlphttp/backend` and `debug` |
| `backend` | A second Collector that prints every trace, metric and log it receives |
| `shuttle` | A pod with `curl`, used to send telemetry to the `gateway` |

`kubectl` already points at the playground cluster, as the cluster administrator. You install nothing on your own machine.

## Reading Order

1. Connectors Between Pipelines
2. Sending Queue, Retry And Timeout
3. Backpressure And Failing Exporters
4. Summary

Launch your playground now, and keep it running next to you while you read:

<!-- astrona:playground -->
