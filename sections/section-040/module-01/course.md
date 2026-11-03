---
draft: true
exam_objectives:
- Pipelines
---
# Signal Paths, Shared Components And Fan-Out

A Collector does nothing with a component until a pipeline lists it. The `service.pipelines` section of the configuration file decides which receivers, processors and exporters run for each signal, in which order data passes them and which components several pipelines share. This module explains that wiring with a real gateway Collector that you edit and test.

Keep one sentence in mind: **a pipeline is the path of one signal, and the file proves a path only when data arrives at the end of it.** You will read a pipeline, add a second signal and a second named pipeline that share one receiver, see which objects the Collector shares and which it creates for each pipeline, add a second exporter, and watch the order of two processors decide whether a confidential value leaves the Collector.

The module has three parts. **Signal Paths And Pipeline Names** defines pipelines, names them and shows what the Collector checks at start. **Shared Components And Instances** uses one receiver, one exporter and one processor name in several pipelines and shows what is shared. **Fan-Out And Processor Order** sends one pipeline to several exporters and shows how processor order changes what every exporter receives.

## Learning Goals

- Trace a signal from receiver to exporter through the pipelines listed in the `service` section.
- Name pipelines with the `type/name` form and explain what the Collector validates at start.
- Explain which components a Collector shares between pipelines and which it creates for each pipeline.
- Use several exporters in one pipeline and explain what each one receives.
- Order processors so that removal of a value happens before any step that copies it.

## Before You Start

You need Kubernetes basics: namespaces, Deployments, ConfigMaps, `kubectl get`, `kubectl logs` and `kubectl apply`. You do not need to know the Collector; each component is explained where it first appears.

Your playground is a single-node `kind` cluster running Kubernetes 1.35, with these workloads in the namespace `starfleet`:

| Workload | What it does |
| --- | --- |
| `gateway` | The Collector you edit, image `otel/opentelemetry-collector-contrib:0.162.0`. Its file is the key `config.yaml` of the ConfigMap `collector-config` |
| `backend` | A second Collector that prints every trace, metric and log it receives |
| `shuttle` | A pod with `curl`, used to send telemetry to the `gateway` |

`kubectl` already points at the playground cluster, as the cluster administrator. You install nothing on your own machine.

## Reading Order

1. Signal Paths And Pipeline Names
2. Shared Components And Instances
3. Fan-Out And Processor Order
4. Summary

Launch your playground now, and keep it running next to you while you read:

<!-- astrona:playground -->
