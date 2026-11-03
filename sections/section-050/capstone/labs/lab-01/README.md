---
estimated_duration: 30m
---

# Lab: Starfleet Gateway Data Policy Capstone

Graded lab. **UNTESTED**: built with static checks only (`astrona validate`, `bash -n`, YAML parsing); it has not been run on a cluster. The cluster starts with the OpenTelemetry Collector (`otel/opentelemetry-collector-contrib:0.162.0`) in the namespace `otel`, deployed with plain manifests. A curl pod named `sender` posts test telemetry. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-050/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-050/capstone/labs/lab-01
astrona destroy ats-075-capstone-050
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

Every script sends its own test telemetry with a unique marker from the `sender` pod, waits until the debug exporter prints it in the Collector log, and then checks what the log shows. A check fails when the marker never appears (the data did not arrive), so a broken configuration cannot pass an "absent" check by accident.

| Script | What it proves |
| --- | --- |
| `validate-collector-accepts-all-signals.sh` | The health check answers 200 and an ordinary span, log record and metric all reach the debug exporter |
| `validate-resource-and-privacy.sh` | The resource shows `starfleet-prod` and no `host.name`, the authorization value is absent and `user.email` is a hexadecimal hash |
| `validate-route-normalised-before-filter.sh` | `http.target` loses its query string and probe spans, with or without a query string, are dropped |
| `validate-token-and-card-masked.sh` | `url.full` shows `token=REDACTED&page=1` shape and the log body shows `card=****` |
| `validate-noise-dropped-and-identity-kept.sh` | A DEBUG log record and the metric `scout.debug.counter` are dropped and `user.id` is removed from data points |

## Open items (UNTESTED assumptions)

- The layout of the debug exporter output (`Name`, `-> key: Str(value)` lines, `ResourceSpans #0` headers) is assumed from the exporter at `verbosity: detailed`.
- The `filter` processor uses the `trace_conditions`, `log_conditions` and `metric_conditions` keys with prefixed paths such as `span.attributes[...]`, as documented for Collector 0.162.0.
- The `hash` action of the attributes processor is checked only as "a 40 to 64 character hexadecimal value", because the algorithm depends on a feature gate.
