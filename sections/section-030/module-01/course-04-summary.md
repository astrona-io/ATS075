# Summary

The Collector reports its own state on port 8888. Four groups of metrics matter for capacity: spans accepted by receivers, spans refused by the memory limiter or by a full downstream, spans sent and failed by the exporter, and the size and capacity of the exporter queue. Comparing them locates a bottleneck. Refused spans at the receiver mean the Collector is protecting itself. A queue that is close to its capacity and failed sends mean the destination is slow or down. A short queue with high CPU means the Collector itself is the limit.

Each exporter has a sending queue and a retry policy. The queue absorbs short slowdowns, the retry policy repeats failed sends with a growing delay until the total retry time passes, and data is dropped after that. A full queue rejects new data and passes an error back to the sender, which is how backpressure works. The queue size and the retry time together define how long an outage the Collector can absorb.

The memory limiter processor protects the process. It has a soft limit and a hard limit, which is the soft limit plus the spike limit, and it refuses data above the soft limit. It must be the first processor in every pipeline and its hard limit must be below the container memory limit, because the kernel kills a container that goes over its limit and everything in memory is lost. The batch processor goes after it and groups spans so that each export carries more of them.

Vertical scaling gives a pod more CPU and memory. CPU above the limit is throttled and slows the Collector without an error, while memory above the limit kills the container. Setting the Go memory limit environment variable below the limiter hard limit makes the runtime collect garbage earlier. Horizontal scaling adds replicas behind a Service, and it works without further design when the Collector is stateless, because every replica can handle every request.

Replicas do not help when the destination is the bottleneck, when a long-lived connection pins a sender to one pod, or when a processor needs related data on the same instance. The self-telemetry metrics show which case applies, and that decides whether the next step is more resources, more replicas, a faster destination or a different design.

<!-- astrona:playground:destroy -->
