# Question

Solve this question on: `terminal`

The agent Collector `otelcol` in `starfleet` must become the single entry point for telemetry from the `scout`, `probe` and `drifter` workloads and forward it to the gateway Collector in `outpost`. It starts with two configuration files, `base.yaml` and `override.yaml`, in the ConfigMap `otelcol-config`. The Collector merges them in this order. The Deployment sets the variables `GATEWAY_ENDPOINT`, `DEPLOY_ENV` (the text `outpost-test`) and `BACKEND_TOKEN` (from the Secret `gateway-token`).

Change the two files so that all of these are true:

1. The merged configuration passes `otelcol-contrib validate`.
2. Traces, metrics and logs sent to the receiver `otlp` on port 4318 reach the gateway through `otlphttp/gateway`. Each pipeline lists the processors `memory_limiter` and `batch`, in this order (the traces pipeline also has the `resource` processor between them).
3. A named receiver `otlp/second` accepts OTLP/HTTP on port 4319, and its spans reach the gateway.
4. The attribute `deployment.environment` comes from `${env:DEPLOY_ENV}`, without the literal text `outpost-test` in the ConfigMap.
5. The header `authorization` of `otlphttp/gateway` reads the token with `${env:BACKEND_TOKEN}`. The literal token is not in the ConfigMap and the Deployment keeps reading it from the Secret.
6. The `health_check` extension is enabled and answers on port 13133 of the Service `otelcol`.

Do not change the gateway, the `shuttle` pod, the Secret or the Deployment. The Collector reads its configuration only at start, so restart the Deployment after each change. `kubectl` already points at the cluster.
