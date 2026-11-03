---
draft: true
exam_objectives:
  - Transforming Data
---
# Attributes, Resources And Filtering

Telemetry leaves an application with more detail than anyone downstream needs. Some attributes are secrets, some are noise, and some have names that do not match what the dashboards expect. The OpenTelemetry Collector (a program that receives telemetry, changes it and sends it on) has processors that fix these problems before the data reaches a backend. This module covers the three simplest ones: the attributes processor, the resource processor and the filter processor.

Keep one idea in mind: **every processor changes the evidence that the next step receives, so what a processor can see depends on its position in the pipeline and on the level of the data it touches.**

The module has three parts. The first part changes attributes with the attributes processor and the resource processor. The second part removes whole spans, log records and metrics with the filter processor and its conditions. The third part shows why the order of processors and the level of an attribute (resource or span) decide the result.

## Learning Goals

After this module you can:

- Name the actions of the attributes processor (`insert`, `update`, `upsert`, `delete`, `hash`) and say what each one does to an attribute that exists and to one that does not.
- Use the resource processor to change attributes that describe the producer of the data.
- Write filter processor conditions in the OpenTelemetry Transformation Language (OTTL) and explain why a true condition drops the data.
- Explain the three `error_mode` values and what each one does when a condition fails.
- Predict the result of two processors in a different order.
- Tell a resource attribute from a span attribute and choose the processor that changes it.

## Before You Start

You need to know what a Collector pipeline is: receivers take data in, processors change it, and exporters send it out. Terms are defined where they first appear.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. It has these parts:

| Where | What it is |
| --- | --- |
| Deployment `collector` in `otel` | The Collector (`otel/opentelemetry-collector-contrib:0.162.0`). It reads `/conf/config.yaml` from the ConfigMap `collector-config`. |
| Service `collector` in `otel` | Port 4318 receives OTLP over HTTP. Port 13133 answers the health check. |
| pod `sender` in `otel` | Runs curl. You post test telemetry from it. |

The Collector starts with three pipelines (traces, metrics and logs). They have one receiver (`otlp`) and one exporter (`debug` with `verbosity: detailed`), and no processors. The debug exporter prints every item it receives to the Collector log. `kubectl` already points at the cluster.

## Reading Order

1. Changing Attributes With The Attributes And Resource Processors
2. Dropping Data With The Filter Processor
3. Processor Order And The Level Of An Attribute
4. Summary

Launch your playground now and keep it running while you read:

<!-- astrona:playground -->
