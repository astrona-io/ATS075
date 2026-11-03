# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. The commands print no real output that you need to copy, so the text describes what to look for.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-050/module-01/labs/lab-01
```

Run the grader once before you change anything:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-050/module-01/labs/lab-01 --keep
```

All five checks fail, because the Collector passes every attribute and every record through. That is the starting point.

## Step 1: Read the current configuration

Print the configuration that the Collector reads:

```sh
kubectl -n otel get configmap collector-config -o jsonpath='{.data.config\.yaml}'
```

It shows the receiver `otlp`, the exporter `debug`, the extension `health_check` and three pipelines. The lists `processors` do not exist yet. Every processor needs two things: a definition under `processors:` and a name in the `processors` list of each pipeline that should use it. A processor that you define but do not list does nothing.

## Step 2: Write the new configuration

The resource processor changes resource attributes, and the attributes processor changes span, log record and data point attributes. The filter processor drops data when one of its conditions is true. Save this as `collector-config.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: collector-config
  namespace: otel
data:
  config.yaml: |
    receivers:
      otlp:
        protocols:
          http:
            endpoint: 0.0.0.0:4318

    processors:
      resource/environment:
        attributes:
          - key: deployment.environment.name
            value: training
            action: upsert
          - key: host.name
            action: delete
      attributes/privacy:
        actions:
          - key: http.request.header.authorization
            action: delete
          - key: user.email
            action: hash
      filter/noise:
        error_mode: ignore
        trace_conditions:
          - span.attributes["http.route"] == "/healthz"
        log_conditions:
          - log.severity_number < SEVERITY_NUMBER_INFO

    exporters:
      debug:
        verbosity: detailed

    extensions:
      health_check:
        endpoint: 0.0.0.0:13133

    service:
      extensions: [health_check]
      pipelines:
        traces:
          receivers: [otlp]
          processors: [resource/environment, attributes/privacy, filter/noise]
          exporters: [debug]
        metrics:
          receivers: [otlp]
          processors: [resource/environment]
          exporters: [debug]
        logs:
          receivers: [otlp]
          processors: [resource/environment, attributes/privacy, filter/noise]
          exporters: [debug]
```

Apply it and restart the Collector:

```sh
kubectl apply -f collector-config.yaml
kubectl -n otel rollout restart deployment/collector
kubectl -n otel rollout status deployment/collector
```

The order of the names in each `processors` list is the order of execution. In the lists above the resource processor runs first, the attributes processor second and the filter processor last. The metrics pipeline only gets the resource processor, because the rules do not mention metric data.

## Step 3: Send test data and look at it

Save this as `span-checkout.json`:

```json
{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"scout"}},{"key":"host.name","value":{"stringValue":"node-a"}}]},"scopeSpans":[{"scope":{"name":"manual"},"spans":[{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"eee19b7ec3c1b174","name":"checkout","kind":2,"startTimeUnixNano":"1700000000000000000","endTimeUnixNano":"1700000001000000000","attributes":[{"key":"http.route","value":{"stringValue":"/orders"}},{"key":"user.email","value":{"stringValue":"jason@starfleet.test"}},{"key":"http.request.header.authorization","value":{"stringValue":"Bearer secret"}}]},{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"eee19b7ec3c1b175","name":"health","kind":2,"startTimeUnixNano":"1700000000000000000","endTimeUnixNano":"1700000001000000000","attributes":[{"key":"http.route","value":{"stringValue":"/healthz"}}]}]}]}]}
```

Post it from the `sender` pod and read the log:

```sh
kubectl -n otel exec -i sender -- curl -s -o /dev/null -w '%{http_code}\n' -H 'Content-Type: application/json' -X POST http://collector.otel.svc.cluster.local:4318/v1/traces -d @- < span-checkout.json
kubectl -n otel logs deploy/collector --tail=60
```

The status is `200`. The log shows one span named `checkout`. The resource has `deployment.environment.name` with `training` and no `host.name`. The span has `http.route`, a `user.email` that is now a long hexadecimal string, and no authorization header. The span `health` does not appear.

## Step 4: Grade

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-050/module-01/labs/lab-01
```

All five checks pass. When one fails, the usual causes are these. A processor is defined but missing from a pipeline list. The key is misspelled in `kubectl get configmap`, so the Collector did not start (read `kubectl -n otel logs deploy/collector` for the error). The ConfigMap was applied but the Deployment was not restarted. The `delete` action was applied to `host.name` with the attributes processor, which changes span attributes and never the resource.
