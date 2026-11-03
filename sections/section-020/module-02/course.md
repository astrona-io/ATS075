---
draft: true
exam_objectives:
  - Deployment
---
# Gateway Deployment And Agent-To-Gateway Export

An agent serves the workloads on one node. A gateway is a Collector that serves many agents. It runs as a normal Deployment behind a Service, so it can be scaled, replaced and updated like any other stateless application. Agents send their telemetry to the gateway, and the gateway is the only component that talks to the backend.

This module builds that second tier. You deploy a gateway and its Service, point an agent at it with the OTLP exporter, and move the backend credentials out of every agent into the gateway. You then look at the buffering and retry settings that protect the data between the tiers, and at the replica count that decides how much availability the gateway has. Authentication and transport encryption (TLS, Transport Layer Security) are covered as options and trade-offs, and the exercises use HTTP basic authentication because it needs no certificates.

The module has three parts. **Deploying A Gateway And Exporting To It** creates the Deployment and the Service and changes the agent exporter. **Centralising Credentials And Securing The Hop** moves the backend password into a Secret that only the gateway reads, and compares the authentication and TLS choices. **Buffering, Retry And Availability Between Tiers** shows how the sending queue, the retry policy and the replica count behave when the backend is unavailable. A graded lab follows the last part, and a capstone at the end of the section combines both modules.

## Learning Goals

- Deploy a gateway Collector as a Deployment with a Service and explain why it is stateless and scaled by replicas.
- Configure an agent to export OTLP to the gateway and verify that the data arrives.
- Keep the backend credentials only in the gateway, and read them from a Secret through an environment variable.
- Explain the authentication and TLS options between the tiers and between the gateway and the backend.
- Set the sending queue, retry and memory limit of the gateway, and explain what is lost when the gateway fails.

## Before You Start

You need the basics of Collector configuration: receivers, processors, exporters, and the pipelines that connect them. You should know what an agent is and why a DaemonSet agent exposes a node-local Service. You need `kubectl` access to the playground cluster. The playground starts with a backend that requires a password, an agent that exports straight to it, and no gateway.

## Reading Order

1. Deploying A Gateway And Exporting To It
2. Centralising Credentials And Securing The Hop
3. Buffering, Retry And Availability Between Tiers
4. Summary

<!-- astrona:playground -->
