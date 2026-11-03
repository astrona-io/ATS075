# Summary

A stateless Collector scales by running identical replicas behind a Service. The Service picks a pod once per connection, so many short connections spread evenly and one long-lived gRPC connection stays on one pod. The remedies are to limit the connection age, to use a headless Service with a client-side balancer, or to balance in front by request. A replica that is not ready receives no new connections.

Tail sampling is stateful. The processor holds the spans of each trace for the decision wait and then evaluates its policies against everything it received. If the spans of one trace are split between pods, each pod decides on part of the trace and the result is wrong. The remedy is two layers: a stateless gateway layer that hashes each span by its trace ID and sends it to one sampler pod, and a sampler layer that receives only complete traces.

The load balancing exporter implements the first layer. It takes a routing key, a template for the OTLP exporter to each backend, and a resolver that finds the backends, either a static list, DNS names or the Kubernetes endpoints of a Service. A headless Service gives the exporter the pod addresses it needs. When the backend list changes, the hash ring changes and in-flight traces can be split, and when a backend fails, the exporter does not choose another one. Routing by service keeps a trace together only when the trace has one service.

Pulling receivers scale differently from listening receivers. Two copies of a Collector with the same scrape configuration both scrape every target, and the backend receives each sample twice. Sharding gives each target one owner. The hash of the target address is taken with a modulus equal to the replica count, and each replica keeps the targets whose result equals its own number, which a StatefulSet pod index provides. The Target Allocator of the OpenTelemetry Operator does the same job centrally, with service discovery done once and a strategy that divides targets between Collectors.

Duplicates still appear for other reasons. Retries after a timeout can send data that was already delivered, rollouts and changes of the replica count leave targets with two owners or none for a short time, and the hash does not consider how heavy a target is. Delivery is at least once, so a destination that must not count twice needs its own deduplication.

<!-- astrona:playground:destroy -->
