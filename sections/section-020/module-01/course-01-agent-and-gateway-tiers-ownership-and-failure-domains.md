---
draft: true
exam_objectives:
- Deployment
---
# Agent And Gateway Tiers, Ownership And Failure Domains

Collector deployment topology determines where telemetry is handled and which failures affect it. An agent tier runs near applications or hosts. A gateway tier serves many producers or agents from a shared collection boundary. The two approaches can be used separately or together. Their value comes from deliberate responsibility placement, not from adding the largest number of collection services.

Agents can obtain local files or host measurements and enrich observations with nearby resource information. They can expose a convenient endpoint for application SDKs. Gateways can centralize policy, destination credentials and expensive processing. This separation can reduce application configuration complexity while giving operators a common export path. It also creates dependencies whose capacity and availability need explicit ownership.

Consider applications sending telemetry to node-local agents, which forward it to a shared gateway. The agent can attach node context where appropriate while preserving the service's original resource identity. The gateway can apply organization policy and export to approved backends. If the gateway replaces every resource with its own service name, analysis loses producer attribution even though delivery succeeds.

Placement influences credential and trust boundaries. Agents may need host or workload access for their selected receivers. Gateways may hold credentials for external destinations. Receivers should accept data only from intended producers, and transport protection should match the network path. A gateway that accepts arbitrary callers can ingest misleading or excessive telemetry even when its exporters are correctly authenticated.

Failure behavior differs by topology. If a local agent stops, nearby applications depend on their SDK queues and retry behavior. If a shared gateway stops, many agents can accumulate data or drop it when their buffers fill. More tiers can increase the number of places data waits. They do not automatically create a durable end-to-end record unless the relevant storage and queue contracts are designed and configured.

Signals also have different collection needs. File-based logs may require local access to the host or container filesystem. OTLP receivers can accept network-delivered traces and metrics. Prometheus scraping needs target assignment to avoid duplicate collection. A single generic deployment diagram cannot settle all those responsibilities. The chosen receiver and processing behavior should explain why a signal belongs at a particular tier.

Availability planning includes replicas and routing, but stateful processing needs more than interchangeable servers. Tail sampling can require related spans to reach the same processing instance. Stateful metric transformations can require consistent stream ownership. A load balancer that distributes requests arbitrarily may work for stateless forwarding and still break those processing semantics.

Operational visibility should identify intake, processing and export at each tier. A gateway can be healthy while its exporter repeatedly fails. An agent can export successfully while application instrumentation produces no useful spans. Comparing evidence between tiers helps locate where observations disappear or change. It also prevents every failure from being attributed to the final analysis backend.

Privacy policy should occur before the boundary where restricted data must not pass. Redacting at the gateway is too late if an unapproved intermediate destination already received the data. Source-side minimization and tier-specific transformations should match the actual trust design. Configuration examples must identify their scope rather than imply that every deployment is protected by default.

## Common pitfalls

> [!WARNING]
> Another collection tier is another dependency, not automatic durability. Preserve producer identity and review credentials, receiver access and signal-specific state. Redaction must occur before the boundary it is meant to protect.
