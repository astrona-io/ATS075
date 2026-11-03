---
draft: true
exam_objectives:
  - Deployment
---
# Agent Deployment Patterns

An application produces telemetry, and something has to receive it, add context to it and pass it on. In a Kubernetes cluster that something is usually an OpenTelemetry Collector that runs close to the application. The Collector is a program that receives, processes and exports telemetry (traces, metrics and logs). A Collector that runs next to the workloads it serves is called an agent.

This module teaches where to run the agent and what to give it. You compare three patterns: no Collector at all, a Collector as a sidecar container in each pod, and a Collector as a DaemonSet with one pod on every node. You then give the DaemonSet agent the context that only the edge knows: the pod, namespace and node of the sender, the environment name and the host metrics of the node. Throughout the module you ask who owns each decision and what fails together when one agent pod stops.

The module has three parts. **Agent Topologies: Sidecar, DaemonSet And Direct Export** compares the patterns and shows how an application reaches a node-local agent. **Enriching Telemetry At The Edge** adds the `k8sattributes` processor, the permission it needs and the node filter that keeps each agent small. **Resource Attributes, Host Metrics And Failure Domains** adds the `resourcedetection` processor and the `hostmetrics` receiver, protects the agent with `memory_limiter` and shows what the sender sees when the agent restarts. A graded lab follows the last part.

## Learning Goals

- Compare no Collector, a sidecar Collector and a DaemonSet agent by what each one owns and what fails with it.
- Route an application to the agent on its own node with a Service that has `internalTrafficPolicy: Local`.
- Add pod, namespace, node and Deployment attributes with the `k8sattributes` processor, and grant the read-only access it needs.
- Add environment and host attributes with the `resourcedetection` processor, and explain what `override` changes.
- Collect node metrics with the `hostmetrics` receiver, and say why a containerised agent needs `root_path` for some scrapers.
- Protect an agent with `memory_limiter` and describe the failure domain of an agent restart.

## Before You Start

You need Kubernetes basics: namespaces, Deployments, DaemonSets, Services, ConfigMaps, and the commands `kubectl get`, `kubectl apply`, `kubectl logs` and `kubectl exec`. You should know that a Collector configuration file has the sections `receivers`, `processors`, `exporters` and `service`, and that a pipeline in `service.pipelines` connects them.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. The namespace `starfleet` holds these objects:

| Object | What it is |
| --- | --- |
| DaemonSet `otel-agent` | A Collector (`otel/opentelemetry-collector-contrib:0.162.0`) with one pod per node. It reads `/conf/config.yaml` from the ConfigMap `otel-agent-config` |
| Service `otel-agent` | Port 4318, OTLP over HTTP. It sends traffic to the agent pod on the caller's own node |
| ServiceAccount `otel-agent` | The identity of the agent. It has no RBAC rule yet |
| Deployment `shuttle` | A pod that runs `curl`. It stands in for an application and posts spans to the agent |

The agent starts with one `otlp` receiver, one `debug` exporter with `verbosity: detailed` and one `traces` pipeline. You edit the ConfigMap and restart the agent, because the Collector reads its configuration file only at start. Every command runs against the playground cluster as the cluster administrator, and `kubectl` already points at it.

## Reading Order

1. Agent Topologies: Sidecar, DaemonSet And Direct Export
2. Enriching Telemetry At The Edge
3. Resource Attributes, Host Metrics And Failure Domains
4. Summary

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
