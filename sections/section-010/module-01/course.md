---
draft: true
exam_objectives:
- Configuration
---
# Component Definitions And Enabled Pipelines

This module teaches how an OpenTelemetry Collector configuration file decides what the Collector runs. It separates the definition of a component from its activation in a pipeline, shows how signal support and processor order shape a pipeline, and explains how the distribution and the listener address decide whether the configuration works at all.

## Learning Goals

- Name the top-level sections of a Collector configuration (receivers, processors, exporters, connectors, extensions and service) and say what each one does.
- Explain why a component that is defined but not listed in a pipeline does nothing, and why a pipeline that lists an undefined component is an error.
- Build one pipeline for each signal (traces, metrics and logs) with the processors in a safe order and an exporter that sends the data to a backend.
- Explain why a receiver bound to `localhost` cannot be reached through a Kubernetes Service, and when to bind to `0.0.0.0`.
- Tell the core and contrib distributions apart, list the components of a build and validate a file with `otelcol-contrib validate`.

## Before You Start

You should know what a pod, a Deployment, a ConfigMap and a Service are in Kubernetes. You do not need to know OpenTelemetry. The hands-on parts use a playground with a kind cluster, `kubectl` and a Collector that you change and restart. Each technical term is defined where it first appears.

## Reading Order

1. Definitions And Enabled Pipelines
2. Signals, Processors And Exporters In A Pipeline
3. Distributions, Validation And Listener Endpoints
4. Summary

<!-- astrona:playground -->
