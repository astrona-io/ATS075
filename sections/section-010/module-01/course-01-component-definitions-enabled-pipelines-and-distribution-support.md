---
draft: true
exam_objectives:
- Configuration
---
# Component Definitions, Enabled Pipelines And Distribution Support

The Collector is a configurable service that receives, processes and exports telemetry. Its configuration defines component instances, then connects selected instances through service pipelines. Receivers accept telemetry from producers or actively collect it from sources. Processors act on data in an ordered sequence. Exporters deliver the resulting data to compatible destinations. Extensions provide supporting service behavior through their own activation path.

A definition is not the same as an enabled pipeline. An exporter listed in the exporters configuration does not automatically receive every signal. The service pipeline must reference it. Likewise, a receiver that is defined but absent from enabled pipelines is not evidence of an active collection path. This separation makes configuration modular but can confuse authors who read only the component definitions.

A pipeline has a signal type, such as traces, metrics or logs. Its selected components must support that signal. A receiver may support several signals, while a particular processor or exporter may support only a subset. Configuration that looks structurally plausible can fail because a component does not implement the pipeline's required capability. Signal support belongs to the implementation contract, not to the similarity of component names.

Processor order affects meaning. A filtering processor can remove records before batching, while an attribute transformation can change values used by a later filter. A memory-limiting component and batching policy have their own placement considerations. The ordered list should therefore be treated as data-processing logic rather than a decorative collection of recommended features.

For example, imagine a trace pipeline that receives OTLP, removes an unwanted attribute, batches spans and exports them. If an author defines the redaction processor but forgets to reference it in the pipeline, the spans can export unchanged. The YAML can be valid while the privacy goal remains unmet. Reviewing the enabled path catches that omission more directly than searching for the processor's name anywhere in the file.

Available component types depend on the selected Collector distribution or custom build. Core and broader distributions can include different receivers, processors and exporters. A configuration copied from a different distribution may name code that the current binary does not contain. Version support also affects field names and behavior. A component definition cannot install a missing implementation.

Endpoints need deliberate listener scope. A receiver bound beyond the intended local boundary can accept data from callers the operator did not expect. Authentication, TLS and network policy should match the collection design. Exporters need appropriate destination addresses, protocols, trust and credentials. Listener success is narrower than authorized and semantically compatible export.

Extensions can supply functions such as health endpoints, authentication or persistent storage where supported. They must be enabled under the appropriate service configuration. Some pipeline components can reference extensions for supporting behavior. Those references need compatible instances and lifecycle. Defining a storage extension alone does not make every queue durable without the corresponding component configuration.

Configuration sources and substitutions also need review. Values can come from files or environment through supported providers. The effective configuration should retain expected types and protected secret delivery. A successful parse does not prove that a certificate exists, a destination accepts the signal or a sensitive attribute is removed before the intended boundary.

This partial configuration illustrates activation rather than a complete protected deployment:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 127.0.0.1:4317
processors:
  batch: {}
exporters:
  debug:
    verbosity: basic
service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug]
```

The pipeline references each defined component and establishes its order. The receiver binds locally in this illustration. The debug exporter writes diagnostics rather than proving durable backend ingestion. Distribution support, authentication and confidential-data policy remain separate considerations.

## Common pitfalls

> [!WARNING]
> Defined components are not automatically active. Review the complete enabled pipeline, its ordered processors and the selected distribution's capabilities. Valid YAML does not establish listener safety, redaction behavior or compatible destination permissions.
