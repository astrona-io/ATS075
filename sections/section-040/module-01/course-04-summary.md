---
draft: true
exam_objectives:
- Pipelines
---
# Summary

A Collector pipeline is the path of one signal: traces, metrics or logs. Its key has the form `type` or `type/name`, and it lists receivers, processors and exporters. Component definitions only describe components. A component starts only when a pipeline lists it, and the Collector validates the whole file at start and exits when a name is undefined, a signal is not supported or a connector is used on one side only.

Receivers and exporters exist once for each name, and every pipeline that lists them connects to the same object. Processors exist once for each pipeline that lists them, so their state, such as the buffer of the `batch` processor, is never shared. One receiver can serve all three signals and several pipelines of one signal. When a pipeline contains a processor that changes data, the Collector gives that pipeline its own copy, and the other pipelines keep the original.

A pipeline with several exporters hands the same processed data to every exporter. Fan-out happens after the last processor, so no exporter can receive anything other than the output of the chain. Processors run in list order, and the order decides the result: removing a value before a step that copies it removes the value for every destination, while the reverse order leaves a copy. The `debug` exporter prints attributes and counts as a destination for privacy decisions.

Fan-out is not a transaction. Each exporter delivers on its own and can succeed or fail independently, so two destinations can hold different data. Every added exporter also adds traffic, memory and credentials. A short test with real data at the end of the path is the proof that a pipeline works.

- A defined component that no pipeline lists never runs.
- Receivers and exporters are shared by name; processors are created for each pipeline.
- Processor order is part of the logic, and removal comes before copying.
- Each exporter of a fan-out delivers independently.

<!-- astrona:playground:destroy -->
