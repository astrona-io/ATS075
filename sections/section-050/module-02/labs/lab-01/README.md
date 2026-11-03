---
estimated_duration: 30m
---

# Lab: Redact Sensitive Data With The Transform Processor

Graded lab. **UNTESTED**: built with static checks only (`astrona validate`, `bash -n`, YAML parsing); it has not been run on a cluster. The cluster starts with the OpenTelemetry Collector (`otel/opentelemetry-collector-contrib:0.162.0`) in the namespace `otel`, deployed with plain manifests. A curl pod named `sender` posts test telemetry. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-050/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-050/module-02/labs/lab-01
astrona destroy ats-075-lab-050-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

Every script sends its own test telemetry with a unique marker from the `sender` pod, waits until the debug exporter prints it in the Collector log, and then checks what the log shows. A check fails when the marker never appears (the data did not arrive), so a broken configuration cannot pass an "absent" check by accident.

| Script | What it proves |
| --- | --- |
| `validate-url-token-redacted.sh` | `url.full` shows `token=REDACTED` and `page=1`, and the token value is absent |
| `validate-span-attributes-deleted.sh` | The authorization header value and the email address are absent, `http.route` stays |
| `validate-plain-span-intact.sh` | A span sent in the same request without `url.full` arrives with `http.route` |
| `validate-log-card-masked.sh` | The log body shows `card=****` and not the card number |
| `validate-datapoint-user-id-removed.sh` | The `user.id` values are absent from the metric output and `route` stays |

## Open items (UNTESTED assumptions)

- The layout of the debug exporter output (`Name`, `-> key: Str(value)` lines, `ResourceSpans #0` headers) is assumed from the exporter at `verbosity: detailed`.
- The `filter` processor uses the `trace_conditions`, `log_conditions` and `metric_conditions` keys with prefixed paths such as `span.attributes[...]`, as documented for Collector 0.162.0.
- The `hash` action of the attributes processor is checked only as "a 40 to 64 character hexadecimal value", because the algorithm depends on a feature gate.
