---
estimated_duration: 30m
---

# Lab: Clean Up Telemetry Before Export

Graded lab. **UNTESTED**: built with static checks only (`astrona validate`, `bash -n`, YAML parsing); it has not been run on a cluster. The cluster starts with the OpenTelemetry Collector (`otel/opentelemetry-collector-contrib:0.162.0`) in the namespace `otel`, deployed with plain manifests. A curl pod named `sender` posts test telemetry. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-050/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-050/module-01/labs/lab-01
astrona destroy ats-075-lab-050-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

Every script sends its own test telemetry with a unique marker from the `sender` pod, waits until the debug exporter prints it in the Collector log, and then checks what the log shows. A check fails when the marker never appears (the data did not arrive), so a broken configuration cannot pass an "absent" check by accident.

| Script | What it proves |
| --- | --- |
| `validate-resource-attributes.sh` | The resource of a test span has `deployment.environment.name: Str(training)`, has no `host.name` value, and keeps `service.name` |
| `validate-secret-attributes-removed.sh` | The authorization header value is absent from the span output and `http.route` stays |
| `validate-email-hashed.sh` | The plain email address is absent and `user.email` is a hexadecimal value of 40 to 64 characters |
| `validate-health-spans-dropped.sh` | A span with route `/healthz` never reaches the debug exporter while its sibling span does |
| `validate-debug-logs-dropped.sh` | A DEBUG log record is dropped and an INFO log record arrives |

## Open items (UNTESTED assumptions)

- The layout of the debug exporter output (`Name`, `-> key: Str(value)` lines, `ResourceSpans #0` headers) is assumed from the exporter at `verbosity: detailed`.
- The `filter` processor uses the `trace_conditions`, `log_conditions` and `metric_conditions` keys with prefixed paths such as `span.attributes[...]`, as documented for Collector 0.162.0.
- The `hash` action of the attributes processor is checked only as "a 40 to 64 character hexadecimal value", because the algorithm depends on a feature gate.
