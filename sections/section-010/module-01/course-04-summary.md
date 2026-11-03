---
draft: true
exam_objectives:
- Configuration
---
# Summary

A Collector configuration file has six top-level sections: receivers, processors, exporters, connectors, extensions and service. The first four define components, and a definition only describes a component. The `service` section activates it. A pipeline lists the receivers, the processors and the exporters for one signal, and the `service.extensions` list activates the extensions. A component that is defined and never listed does not start and does not cause an error. A pipeline that lists a component without a definition is an error, and the Collector does not start.

Each pipeline carries one signal: traces, metrics or logs. A component works in a pipeline only if its code supports that signal, so the README of the component is the source of truth. One receiver or exporter that appears in several pipelines is created once and shared, while every pipeline gets its own instance of each processor. A pipeline with two exporters sends a copy of the data to each one. The order of the processors is part of the behaviour: `memory_limiter` first, so that the process refuses data before it uses too much memory, and `batch` last, so that a batch holds only data that will be sent.

The distribution decides which components exist. The core build has a small set, the contrib build has many more, and a custom build has what its author chose. A file cannot add a component to a binary, and the `components` command lists what a binary has. The `validate` command loads the files like a normal start and reports a missing definition or a wrong setting before the pod restarts. The Collector reads its files only at start, so every change needs a restart, and a rollout with a readiness check keeps the old pod until the new one is ready.

A listener is reachable only if its address matches the way callers connect. The `otlp` receiver defaults to `localhost`, which a Kubernetes Service cannot reach. Binding to `0.0.0.0` makes it reachable and also opens it to every pod that can connect, so limit access with a NetworkPolicy, TLS or authentication. A ready pod proves only that the readiness listener answers.

Key facts:

- Definition describes, `service` activates.
- Pipeline names start with the signal: `traces`, `metrics`, `logs`, with an optional `/name`.
- Receivers and exporters are shared between pipelines, processors are not.
- Put `memory_limiter` first and `batch` last.
- `otelcol-contrib validate` finds structural errors and `otelcol-contrib components` lists the build.
- `localhost` is not reachable through a Service, and `0.0.0.0` is.

<!-- astrona:playground:destroy -->
