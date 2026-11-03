---
draft: true
exam_objectives:
- Pipelines
---
# Summary

A connector is a component that acts as an exporter at the end of one pipeline and as a receiver at the start of another. It moves data inside the Collector process without a network hop, and it supports a fixed list of signal pairs. The `forward` connector joins pipelines of the same signal, the `count` connector turns spans, metrics or log records into counts such as `trace.span.count`, and the span metrics connector turns spans into request and duration metrics. The Collector refuses to start when a connector is used on one side only or when a component does not support the signal of its pipeline, and the error names the component.

A network exporter has three layers. The sending queue accepts batches and decouples the pipeline from the destination. The retry policy repeats failed attempts with a growing wait until `max_elapsed_time` ends. The timeout limits each attempt. The defaults are a queue of 1000 requests with 10 consumers, retry from 5 seconds up to 30 seconds for at most 300 seconds, and a timeout of 5 seconds. With the queue enabled, a failing destination is handled in the background and the sender sees success. With the queue disabled, the delay reaches the receiver, the sender and the exporters that come after the slow one.

When a queue is full, the exporter returns an error, and the error travels back through the pipeline and the receiver to the sender. With the default `block_on_overflow: false` the batch is rejected at once, and with `true` the call waits. The other exporters of the pipeline still receive the batch, so the healthy destination can receive the same data twice when the sender retries. A memory queue loses its content when the Collector restarts.

The Collector reports its own state on port 8888. Queue size and capacity, enqueue failures, send failures and the accepted and refused counts of the receiver show which exporter is in trouble and how close its queue is to the limit.

- A connector needs both sides and a supported signal pair.
- A queue turns a destination failure into background work; no queue moves it to the sender.
- A full queue returns an error to the sender while other exporters still deliver.
- Watch queue size against queue capacity before data is lost.

<!-- astrona:playground:destroy -->
