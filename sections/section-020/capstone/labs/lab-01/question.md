# Question

Solve this question on: `terminal`

The `starfleet` namespace runs a backend Collector (`otel-backend`) that stands in for the observability platform and accepts OTLP over HTTP only with the user `gateway` and a password. The agents run as the DaemonSet `otel-agent` and read the ConfigMap `otel-agent-config`. Today every agent exports straight to the backend, holds the backend password in its own configuration and adds no context to the telemetry. The Deployment `shuttle` stands in for an application: it runs `curl` and posts spans to the Service `otel-agent` on port 4318. The platform team wants a two-tier deployment: the agents enrich at the edge, and a gateway owns the credentials. Do not change the backend, and do not delete the Secrets `backend-credentials` and `backend-htpasswd`.

1. Edge enrichment. Give the service account `otel-agent` read-only access (`get`, `list`, `watch`) to pods and namespaces in all namespaces, and nothing more. In the agent add the `k8sattributes` processor (filtered to the node of the agent with the environment variable `KUBE_NODE_NAME`, extracting `k8s.namespace.name`, `k8s.pod.name`, `k8s.node.name` and `k8s.deployment.name`, matching the sender by the connection address) and the `resourcedetection` processor with the `env` and `system` detectors and `override: false`. Set `OTEL_RESOURCE_ATTRIBUTES` to `deployment.environment.name=lab` on the agent container. Put `memory_limiter` first in the pipeline.

2. Gateway. Create a Deployment `otel-gateway` with two replicas and a Service `otel-gateway` on port 4318. The gateway runs the same image, reads the ConfigMap `otel-gateway-config` (key `config.yaml`, mounted at `/conf`), receives OTLP over HTTP and exports with `otlphttp` to `http://otel-backend.starfleet.svc:4318` using the `basicauth` extension as a client. Give the pods a readiness probe on the `health_check` extension (port 13133). The gateway must not replace the resource attributes that the agent added.

3. Credentials. The gateway reads the password from the Secret `backend-credentials` (key `password`) through the environment variable `BACKEND_PASSWORD`, and the configuration uses `${env:BACKEND_PASSWORD}`. The password must not appear as a literal in any ConfigMap or Deployment, and the agent must hold neither the password nor a reference to the Secret.

4. Agent export. The agent exports with `otlphttp` to `http://otel-gateway.starfleet.svc:4318` and no longer mentions `otel-backend`. Restart the agent after a ConfigMap change, because the Collector reads its configuration only at start.

A span that `shuttle` posts to the agent must appear in the log of the backend with the Kubernetes attributes of `shuttle` and `deployment.environment.name=lab`. `kubectl` already points at the cluster as the cluster administrator.
