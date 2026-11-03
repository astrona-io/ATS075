---
draft: true
exam_objectives:
  - Transforming Data
---
# The Transform Processor And Data Safety

Simple processors add, delete and hash whole attribute values. Real data needs more: a token sits inside a URL, a card number sits inside a log message, and a user identifier turns one metric into thousands. The transform processor handles these cases with small statements, and it can also make them worse. This module covers how it works, how to use it to remove sensitive data, and what it does to the identity of metrics.

Keep one idea in mind: **a transformation is a change to evidence, so every statement needs a clear scope, a safe failure mode and a position in the pipeline that comes before every destination that must not see the original data.**

The module has three parts. The first part explains statements, contexts and the way the transform processor reads them. The second part redacts sensitive attributes, URL parts and log text. The third part shows how deleting a metric attribute changes metric identity, why the position of a processor decides who sees the secret, and how to verify the result with the debug exporter.

## Learning Goals

After this module you can:

- Write OpenTelemetry Transformation Language (OTTL) statements with a function, a path and a `where` clause.
- Name the contexts that a signal offers (`span`, `log`, `datapoint` and the levels above them) and choose the right one.
- Redact a value inside a string with `replace_pattern`, and remove attributes with `delete_key` and `delete_matching_keys`.
- Explain what `error_mode` does to a statement that fails, and why a guard with `where` is needed.
- Explain why deleting or renaming a metric attribute changes metric identity and cardinality, and why the processor does not fix the result.
- Describe how pipeline layout and processor order can leak the original data, and verify a redaction with the debug exporter.

## Before You Start

You need to know what a Collector pipeline is and how processors run in list order. Terms are defined where they first appear.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. It has these parts:

| Where | What it is |
| --- | --- |
| Deployment `collector` in `otel` | The Collector (`otel/opentelemetry-collector-contrib:0.162.0`). It reads `/conf/config.yaml` from the ConfigMap `collector-config`. |
| Service `collector` in `otel` | Port 4318 receives OTLP over HTTP. Port 13133 answers the health check. |
| pod `sender` in `otel` | Runs curl. You post test telemetry from it. |

The Collector starts with three pipelines (traces, metrics and logs) that have the `otlp` receiver, the `debug` exporter with `verbosity: detailed` and no processors. `kubectl` already points at the cluster.

## Reading Order

1. Statements And Contexts In The Transform Processor
2. Redacting Sensitive Attributes
3. Metric Identity, Pipeline Position And Verification
4. Summary

Launch your playground now and keep it running while you read:

<!-- astrona:playground -->
