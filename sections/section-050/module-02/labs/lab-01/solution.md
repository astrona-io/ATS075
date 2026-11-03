# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. The commands print no real output that you need to copy, so the text describes what to look for.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-050/module-02/labs/lab-01
```

Run the grader once before you change anything:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-050/module-02/labs/lab-01 --keep
```

Four checks fail, because the Collector passes every value through. The check `plain-span-intact` already passes. It stays your guard: it fails if your processor drops or damages a span that has no `url.full` attribute.

## Step 1: Choose the statements

The transform processor runs OTTL statements. Each signal has its own list: `trace_statements`, `log_statements` and `metric_statements`. The first path segment of a statement names the context: `span.` for a span, `log.` for a log record and `datapoint.` for a metric data point. The processor reads the contexts from the paths, so a statement that uses `span.attributes` belongs to the span context.

Four functions solve the task. `replace_pattern(target, regex, replacement)` rewrites the part of a string that the regular expression matches. `delete_key(map, key)` removes one key from an attribute map. `IsString(value)` is true when a value is a string, which protects the log rule from non-string bodies. A `where` clause limits a statement to the data that matches.

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
      transform/redact:
        error_mode: ignore
        trace_statements:
          - 'replace_pattern(span.attributes["url.full"], "token=[^&]*", "token=REDACTED") where span.attributes["url.full"] != nil'
          - 'delete_key(span.attributes, "http.request.header.authorization")'
          - 'delete_key(span.attributes, "user.email")'
        log_statements:
          - 'replace_pattern(log.body.string, "card=[0-9]+", "card=****") where IsString(log.body)'
        metric_statements:
          - 'delete_key(datapoint.attributes, "user.id")'

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
          processors: [transform/redact]
          exporters: [debug]
        metrics:
          receivers: [otlp]
          processors: [transform/redact]
          exporters: [debug]
        logs:
          receivers: [otlp]
          processors: [transform/redact]
          exporters: [debug]
```

Apply it and restart the Collector:

```sh
kubectl apply -f collector-config.yaml
kubectl -n otel rollout restart deployment/collector
kubectl -n otel rollout status deployment/collector
```

The statements use single quotes in YAML so that the double quotes of OTTL stay as they are. The `where span.attributes["url.full"] != nil` clause makes the replacement run only on spans that have the attribute. With `error_mode: ignore`, a failing statement is logged and skipped. With `propagate`, the whole payload would be dropped, so the guard also protects the data.

## Step 3: Check the result by eye

Save this as `span-checkout.json`:

```json
{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"scout"}}]},"scopeSpans":[{"scope":{"name":"manual"},"spans":[{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"eee19b7ec3c1b174","name":"checkout","kind":2,"startTimeUnixNano":"1700000000000000000","endTimeUnixNano":"1700000001000000000","attributes":[{"key":"url.full","value":{"stringValue":"https://scout.starfleet.test/api?token=abc&page=1"}},{"key":"user.email","value":{"stringValue":"jason@starfleet.test"}},{"key":"http.route","value":{"stringValue":"/orders"}}]}]}]}]}
```

Post it and read the log:

```sh
kubectl -n otel exec -i sender -- curl -s -o /dev/null -w '%{http_code}\n' -H 'Content-Type: application/json' -X POST http://collector.otel.svc.cluster.local:4318/v1/traces -d @- < span-checkout.json
kubectl -n otel logs deploy/collector --tail=60
```

The status is `200`. The span has `url.full` with `token=REDACTED&page=1`, has `http.route`, and has no `user.email`.

## Step 4: Grade

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-050/module-02/labs/lab-01
```

All five checks pass. When one fails, look for these causes. The processor is defined but missing from one of the three pipeline lists. The statement is in `trace_statements` but uses `log.` paths, which the Collector rejects at start (read `kubectl -n otel logs deploy/collector`). The regular expression `token=[^&]*` was written as `token=.*`, which removes `&page=1` too. The ConfigMap was applied but the Deployment was not restarted.
