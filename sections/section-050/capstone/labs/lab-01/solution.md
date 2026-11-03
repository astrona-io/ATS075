# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. The commands print no real output that you need to copy, so the text describes what to look for.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-050/capstone/labs/lab-01
```

Run the grader once before you change anything:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-050/capstone/labs/lab-01 --keep
```

Four checks fail. The check `collector-accepts-all-signals` already passes. It stays your guard: it fails if a change breaks the Collector or one of the pipelines.

## Step 1: Map each rule to a processor

The rules use four kinds of processors. The resource processor changes resource attributes, which describe the producer. The attributes processor changes span, log record and data point attributes, and has the `hash` action. The transform processor runs OTTL statements and handles pattern replacement. The filter processor drops data when a condition is true.

The order matters for one rule. The health check spans with a query string, such as `/healthz?probe=7`, do not equal `/healthz`. The transform statement that removes the query string must run first, so that the filter sees `/healthz` and drops the span. The filter therefore comes after the transform processor in every `processors` list. Sensitive data also never leaves before the privacy steps, because the exporter is the last step.

## Step 2: Write and apply the configuration

Save this as `collector-config.yaml`:

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
            value: starfleet-prod
            action: upsert
          - key: host.name
            action: delete
      attributes/privacy:
        actions:
          - key: http.request.header.authorization
            action: delete
          - key: user.email
            action: hash
      transform/redact:
        error_mode: ignore
        trace_statements:
          - 'replace_pattern(span.attributes["url.full"], "token=[^&]*", "token=REDACTED") where span.attributes["url.full"] != nil'
          - 'replace_pattern(span.attributes["http.target"], "\\?.*", "") where span.attributes["http.target"] != nil'
        log_statements:
          - 'replace_pattern(log.body.string, "card=[0-9]+", "card=****") where IsString(log.body)'
        metric_statements:
          - 'delete_key(datapoint.attributes, "user.id")'
      filter/noise:
        error_mode: ignore
        trace_conditions:
          - span.attributes["http.target"] == "/healthz"
        log_conditions:
          - log.severity_number < SEVERITY_NUMBER_INFO
        metric_conditions:
          - metric.name == "scout.debug.counter"

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
          processors: [resource/environment, attributes/privacy, transform/redact, filter/noise]
          exporters: [debug]
        metrics:
          receivers: [otlp]
          processors: [resource/environment, attributes/privacy, transform/redact, filter/noise]
          exporters: [debug]
        logs:
          receivers: [otlp]
          processors: [resource/environment, attributes/privacy, transform/redact, filter/noise]
          exporters: [debug]
```

Apply it and restart the Collector:

```sh
kubectl apply -f collector-config.yaml
kubectl -n otel rollout restart deployment/collector
kubectl -n otel rollout status deployment/collector
```

The OTTL string `"\\?.*"` holds two backslashes in the file. OTTL reads them as one backslash, so the regular expression is `\?.*`: a question mark and everything after it. The `where ... != nil` clauses make each replacement run only on spans that have the attribute.

## Step 3: Check by eye

Save this as `span-probe.json`:

```json
{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"scout"}},{"key":"host.name","value":{"stringValue":"node-a"}}]},"scopeSpans":[{"scope":{"name":"manual"},"spans":[{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"eee19b7ec3c1b174","name":"orders","kind":2,"startTimeUnixNano":"1700000000000000000","endTimeUnixNano":"1700000001000000000","attributes":[{"key":"http.target","value":{"stringValue":"/orders?id=42"}}]},{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"eee19b7ec3c1b175","name":"probe","kind":2,"startTimeUnixNano":"1700000000000000000","endTimeUnixNano":"1700000001000000000","attributes":[{"key":"http.target","value":{"stringValue":"/healthz?probe=7"}}]}]}]}]}
```

Post it and read the log:

```sh
kubectl -n otel exec -i sender -- curl -s -o /dev/null -w '%{http_code}\n' -H 'Content-Type: application/json' -X POST http://collector.otel.svc.cluster.local:4318/v1/traces -d @- < span-probe.json
kubectl -n otel logs deploy/collector --tail=60
```

The status is `200`. The log shows the span `orders` with `http.target` set to `/orders`, and the resource with `deployment.environment.name` set to `starfleet-prod` and no `host.name`. The span `probe` does not appear.

## Step 4: Grade

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-050/capstone/labs/lab-01
```

All five checks pass. When `route-normalised-before-filter` fails, the filter runs before the transform processor, or the transform statement for `http.target` is missing. When `noise-dropped-and-identity-kept` fails, check that `metric_conditions` and `log_conditions` exist and that the processors are in the metrics and logs pipelines too.
