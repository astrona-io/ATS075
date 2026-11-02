---
draft: true
exam_objectives:
- Scaling
---
# Capacity Signals, Sharding And Stateful Processing

Collector scaling should follow evidence about the actual bottleneck. Intake, processing and export can each limit useful throughput. CPU and memory pressure can indicate expensive local work, while growing export queues can indicate a slow or unavailable destination. Adding replicas is useful only when the distribution design and downstream capacity allow those replicas to do productive work.

Stateless forwarding is comparatively straightforward. Producers can be distributed across compatible replicas through an appropriate routing layer. Each replica still needs enough resources and valid destination access. Long-lived connections can make distribution uneven, so the number of replicas does not guarantee equal load. Evidence should compare actual intake and resource use rather than assume perfect balancing.

Active scrapers have a different responsibility. A Prometheus receiver obtains data from configured targets. Running several identical configurations can cause every replica to scrape the same endpoints. This increases source load and can create duplicate or conflicting samples downstream. Useful horizontal scaling assigns each target to an intended scraper through sharding or a supported target-allocation mechanism.

Stateful processing also changes the distribution contract. Tail sampling waits for sufficient spans from a trace before making a decision. If related spans are divided randomly among independent processors, each can see an incomplete request. The resulting retained traces may have gaps or inconsistent decisions. Routing by trace identity can help preserve the evidence needed by that processing boundary.

Metric transformations can have stream-specific state. Converting temporal representations or aggregating related points can depend on consistent ownership and sequence. Moving a stream among replicas without accounting for that state can change results even when all replicas are healthy. The component's documented scaling model should determine routing and lifecycle decisions.

Consider a gateway whose export queue grows while CPU remains moderate. If the backend rejects writes because credentials expired, adding gateways gives more instances the same invalid credential. If the backend is overloaded, more concurrent export attempts can worsen the problem. Scaling the Collector is different from repairing a destination contract or increasing destination capacity.

Queue evidence needs careful interpretation. A rising queue can mean a temporary burst, sustained capacity mismatch or persistent delivery failure. Failed-send and dropped-data evidence helps distinguish those cases. Memory pressure and processing latency add local context. A single high measurement does not explain whether the system is catching up or moving toward exhaustion.

Capacity planning should include the expected signal mix. Logs, traces and metrics can have very different record sizes and processing costs. A configuration dominated by attribute transformation may have a different limiting resource from one dominated by network export. Scaling each signal or processing tier independently can be more useful than enlarging a single shared deployment indiscriminately.

Resizing also creates operational transitions. New replicas must receive compatible configuration, identities and routes. Removed replicas may hold buffered data or state that needs a controlled termination path. Routing membership changes can temporarily affect trace affinity or stream ownership. The transition therefore needs consideration as well as the final replica count.

The useful decision connects observed pressure to a component and its distribution model. Students should be able to explain why a stateless path can share load, why a scraper needs assigned targets and why a stateful processor needs coherent evidence. That reasoning is more durable than memorizing a replica count without understanding the pipeline.

## Common pitfalls

> [!WARNING]
> Do not duplicate active scrapers without target ownership or distribute stateful processing arbitrarily. Growing queues may indicate downstream failure rather than insufficient Collector replicas. Scaling should preserve signal semantics and account for buffered state during transitions.
