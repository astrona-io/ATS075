# Question

Solve this question on: `terminal`

The `starfleet` namespace runs a Collector agent as the DaemonSet `otel-agent`. It reads its configuration from the ConfigMap `otel-agent-config` (key `config.yaml`, mounted at `/conf`). The Deployment `shuttle` stands in for an application: it runs `curl` and posts spans to the Service `otel-agent` on port 4318. Today the agent only prints the spans with the `debug` exporter. The platform team needs the agent to add the context of the sender at the edge. Do not delete the DaemonSet, the Service or the `shuttle` Deployment.

1. Access. The service account `otel-agent` has no rights. Give it read-only access to pods and namespaces in all namespaces (`get`, `list`, `watch`) with a `ClusterRole` and a `ClusterRoleBinding`. It must not read Secrets, delete pods or create Deployments.

2. Kubernetes attributes. Add the `k8sattributes` processor to the `traces` pipeline. Look up only the pods on the node of the agent: pass the node name to the container as the environment variable `KUBE_NODE_NAME` from `spec.nodeName`, and use it in the processor filter. Extract `k8s.namespace.name`, `k8s.pod.name`, `k8s.node.name` and `k8s.deployment.name`, and match the sender by the source address of the connection. A span posted by `shuttle` must show these attributes in the debug output.

3. Resource attributes. Add the `resourcedetection` processor with the `env` detector. Set the environment variable `OTEL_RESOURCE_ATTRIBUTES` on the agent container to `deployment.environment.name=lab`. The processor must not overwrite attributes that the sender already set.

4. Host metrics. Add the `hostmetrics` receiver with the `load` and `memory` scrapers (collection interval `10s`) and a `metrics` pipeline that exports to `debug`. Add the `system` detector so the metrics carry `host.name`.

In every pipeline put `memory_limiter` first. Restart the agent after a ConfigMap change, because the Collector reads its configuration only at start. `kubectl` already points at the cluster as the cluster administrator.
