---
draft: true
exam_objectives:
  - Deployment
---
# Summary

A gateway is a Collector that serves many agents. Because it receives data over the network and keeps no state that must survive a restart, it runs as a normal Deployment with a ConfigMap for its configuration and a Service as its stable address. Agents know only the name of the Service. The number of replicas can change without any change to the agents, and a rolling update keeps the Service supplied with ready pods. An agent reaches the gateway with the OTLP exporter, and a reply of success from the agent proves only the first hop, so the next tier must be checked as well.

The gateway owns the connection to the backend. Moving the credentials there removes the secret from every agent: the password lives in one Kubernetes Secret, the Deployment exposes it as an environment variable, and the configuration refers to it with the `${env:...}` syntax. The agent configuration holds no secret. Basic authentication is simple but sends the password in every request, so without TLS it is readable on the network. Other options are token authentication, OAuth2 client credentials and custom headers, and mutual TLS can replace the password on a hop. Certificates need an operational process, and a rotation needs the Collector to reload or restart.

Between the tiers, three settings protect the data. The exporter sending queue holds batches while the network call is made, the retry policy sends a failed batch again with growing waits until its time limit, and the memory limiter refuses data before the process runs out of memory, which pushes load back to the previous tier. The default queue is in memory and acknowledges data before it is delivered, so a gateway restart loses what it holds, and an outage longer than the retry limit drops data. A persistent queue on a volume is the mitigation. Replicas remove the single point of failure, but connection-level balancing can be uneven for long-lived gRPC connections, and processing that needs every span of a trace on one Collector needs routing that a plain Service does not give.

<!-- astrona:playground:destroy -->
