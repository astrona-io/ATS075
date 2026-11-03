# Question

Solve this question on: `terminal`

The `starfleet` namespace runs a backend Collector (`otel-backend`) that stands in for the observability platform. It accepts OTLP over HTTP only with the user `gateway` and a password. The agents run as the DaemonSet `otel-agent` and read the ConfigMap `otel-agent-config`. Today every agent exports straight to the backend and holds the backend password in its own configuration. The Deployment `shuttle` stands in for an application: it runs `curl` and posts spans to the Service `otel-agent` on port 4318. The platform team wants one gateway tier that owns the credentials. Do not change the backend, and do not delete the Secrets `backend-credentials` and `backend-htpasswd`.

1. Gateway. Create a Deployment `otel-gateway` with two replicas and a Service `otel-gateway` on port 4318, in `starfleet`. The gateway Collector runs the same image as the agent (`otel/opentelemetry-collector-contrib:0.162.0`) with its configuration in the ConfigMap `otel-gateway-config` (key `config.yaml`, mounted at `/conf`). It receives OTLP over HTTP on port 4318 and exports with `otlphttp` to `http://otel-backend.starfleet.svc:4318` using the `basicauth` extension as a client. Give the pods a readiness probe on the `health_check` extension (port 13133).

2. Credentials. The gateway reads the password from the Secret `backend-credentials` (key `password`) through an environment variable named `BACKEND_PASSWORD`, and the Collector configuration uses `${env:BACKEND_PASSWORD}`. The password must not appear as a literal in the gateway ConfigMap or Deployment. Remove the password and the `basicauth` extension from the agent. The agent must not read the Secret.

3. Agent export. Change the agent so it exports with `otlphttp` to `http://otel-gateway.starfleet.svc:4318` and no longer mentions `otel-backend`. Restart the agent after the ConfigMap change, because the Collector reads its configuration only at start. A span that `shuttle` posts to the agent must appear in the log of the backend.

4. Buffering. In the gateway configuration use `memory_limiter` and `batch` processors, and set `sending_queue` with `queue_size: 5000` and a `retry_on_failure` section on the backend exporter.

`kubectl` already points at the cluster as the cluster administrator. The user name is `gateway`; read the password from the Secret with `kubectl`.
