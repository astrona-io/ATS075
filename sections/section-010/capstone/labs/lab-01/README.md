---
estimated_duration: 40m
---

# Lab: Configuration Capstone

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The agent starts with a listener on `localhost`, one pipeline, a literal token and environment value, a second file that overrides the exporter list and a `health_check` extension that is not enabled. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-010/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-010/capstone/labs/lab-01
astrona destroy ats-075-capstone-010
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-agent-ready.sh` | The agent Deployment is available with the original contrib image |
| `validate-config-validates.sh` | `otelcol-contrib validate` accepts the merged `base.yaml` and `override.yaml` (run in a short-lived pod) |
| `validate-signals-reach-gateway.sh` | A span, a metric and a log record sent to port 4318 appear in the gateway log |
| `validate-second-receiver.sh` | A span sent to port 4319 reaches the gateway |
| `validate-environment-attribute.sh` | The configuration uses `${env:DEPLOY_ENV}` and a new span carries `deployment.environment` with the value `outpost-test` |
| `validate-secret-from-env.sh` | No literal token in the ConfigMap, `${env:BACKEND_TOKEN}` is used and the variable still comes from the Secret |
| `validate-health-check.sh` | Port 13133 of the agent answers HTTP 200 |

Each check sends new OTLP/HTTP requests from the `shuttle` pod with a unique marker and looks for the marker in the log of the gateway, so it reads live behaviour and not only the ConfigMap. A rollout that is still running is covered by retries.
