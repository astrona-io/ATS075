---
draft: true
exam_objectives:
- Pipelines
---
# Signal Paths, Shared Components And Export Fan-Out

A Collector pipeline describes an enabled path for one telemetry signal. Data enters through a receiver, moves through an ordered processor chain and reaches one or more exporters. Component definitions supply the implementations and settings, while the service configuration connects them. The complete enabled path is the unit to review when deciding what data is accepted, changed or delivered.

Receivers can support several signals or only particular inputs. A shared OTLP receiver can participate in trace, metric and log pipelines where its implementation supports them. The data still retains signal-specific meaning. A metrics pipeline does not become a tracing path simply because both reference a receiver with the same name. Each selected processor and exporter must implement the required signal contract.

Processor order is executable data logic. Suppose a transformation normalizes a route attribute and a later filter excludes a particular route. Reversing the order makes the filter evaluate the original value instead. A batching processor changes delivery grouping rather than the business meaning of a span, while a redaction processor changes data content. Authors should explain the intended sequence and not assume every ordering is equivalent.

Components can be shared across configured paths according to their implementation and Collector construction. Sharing may reduce duplication, but it also creates connected resource and lifecycle behavior. A processor reused across pipelines does not imply that every path is operationally isolated. Review component support and state rather than inferring isolation from the presence of separate YAML blocks.

Multiple exporters create fan-out. This can send the same processed data to an analysis backend and a diagnostic destination. The extra destination is another data-exposure boundary and can have its own capacity, authentication and failure behavior. Whether and how its pressure affects other paths depends on the component contracts and buffering arrangement. Fan-out should not be presented as an unconditional atomic transaction across all destinations.

Consider a trace pipeline exporting to two systems. One accepts spans while the other repeatedly rejects them. The first system can contain useful data even though the overall export path reports failures. Retrying the second may duplicate some records if acknowledgements are ambiguous. This does not mean that all telemetry should be discarded or that every destination necessarily has an identical history.

Pipelines can also connect processing stages through supported connectors. A connector acts at an exporter boundary for one path and a receiver boundary for another, according to its signal capabilities. This enables relationships such as deriving another signal from processed input where implemented. It should not be confused with an ordinary exporter that happens to send data to a network address.

Backpressure and queues influence timing and loss. A receiver that accepts input has not necessarily established durable downstream storage. Processor work can consume capacity, and an exporter queue can fill during destination failure. A useful design observes intake, processing and export rather than declaring success solely from a listener accepting connections.

Privacy review follows the real path. If confidential attributes must be removed before any external destination, the transformation must occur before fan-out to those destinations. A diagnostic exporter can expose full payloads even when the main exporter uses a safer path. Restricting only the final storage backend does not protect earlier logs or side destinations.

Students should trace one record through the declared path and explain each change and failure boundary. That method reveals unreferenced processors, incompatible signal components and unexpected destinations. It also keeps the explanation grounded in what configuration actually enables rather than in an inventory of component names.

## Common pitfalls

> [!WARNING]
> Separate YAML pipelines are not proof of complete operational isolation. Review shared components, fan-out and processing order. Receiver acceptance is not durable storage, and every diagnostic destination needs the same deliberate privacy review as the primary backend.
