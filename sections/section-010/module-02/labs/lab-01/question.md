# Question

Solve this question on: `terminal`

The agent Collector `otelcol` in `starfleet` starts with two configuration files, `base.yaml` and `override.yaml`, which are keys of the ConfigMap `otelcol-config`. The Collector merges them in this order. The Deployment sets three environment variables: `GATEWAY_ENDPOINT`, `DEPLOY_ENV` (the text `outpost-test`) and `BACKEND_TOKEN` (the key `token` of the Secret `gateway-token`).

Change the two files so that all of these are true:

1. The resource attribute `deployment.environment` is set from the variable `DEPLOY_ENV`. The file must contain `${env:DEPLOY_ENV}` and must not contain the text `outpost-test`.
2. The header `authorization` of the exporter `otlphttp/gateway` is `Bearer ` followed by the variable `BACKEND_TOKEN`. The literal token must not appear in the ConfigMap, and the Deployment keeps reading the variable from the Secret.
3. The `health_check` extension answers on port 13133 of the Service `otelcol`.
4. A second receiver with the name `otlp/second` accepts OTLP/HTTP on port 4319, and the first receiver `otlp` keeps accepting on port 4318. Spans from both receivers go through the `traces` pipeline.

Do not change the gateway, the `shuttle` pod, the Secret or the Deployment. The Collector reads its configuration and its environment only at start, so restart the Deployment after each change. `kubectl` already points at the cluster.
