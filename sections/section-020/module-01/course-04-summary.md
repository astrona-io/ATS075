---
draft: true
exam_objectives:
  - Deployment
---
# Summary

An agent is a Collector that runs close to the sender. The three common forms differ in what they own and in how much breaks when they fail. A sidecar is a container inside the pod of one workload. It isolates that workload and costs resources in every pod. A DaemonSet agent runs once per node and serves all pods on the node. It is the usual choice, and a Service with `internalTrafficPolicy: Local` keeps traffic on the node. Direct export has no agent at all, so every application holds backend credentials and retries on its own.

The failure domain of each form follows from its scope. A sidecar failure affects one pod. A DaemonSet agent failure affects the senders on one node, and the data in its memory is lost when it restarts. Direct export has no shared component to fail, but a backend outage reaches every application at the same time.

Edge enrichment moves the knowledge of the platform out of the applications. The `k8sattributes` processor keeps a cache of pods that it fills from the Kubernetes API, matches each request to a pod by pod association, and copies chosen metadata into the resource attributes. It needs a ClusterRole that allows `get`, `list` and `watch` on pods and namespaces. If the permission is missing, the pipeline keeps running and the attributes are silently absent. A node filter that reads the node name from the downward API keeps the cache limited to the pods on the node. Passthrough mode moves the lookup to a later Collector.

The `resourcedetection` processor adds attributes from the environment and the host, and `override: false` keeps values that the sender already set. The `hostmetrics` receiver scrapes the operating system on a schedule, and scrapers that read mounted file systems need the node root mounted and `root_path` set. The `memory_limiter` processor must be the first processor in each pipeline, with a limit below the container memory limit, so that the agent refuses data instead of being killed. Together these choices decide what an agent owns: identity of the sender, description of the host, and protection of its own node.

<!-- astrona:playground:destroy -->
