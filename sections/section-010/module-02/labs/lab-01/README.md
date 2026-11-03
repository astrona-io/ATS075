---
estimated_duration: 30m
---

# Lab: Use Environment Values, Secrets And Extensions

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The agent starts with two configuration files, a literal environment value, a literal token and an extension that is defined but not enabled. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-010/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-010/module-02/labs/lab-01
astrona destroy ats-075-lab-010-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-agent-ready.sh` | The agent Deployment is available with the original contrib image |
| `validate-health-check.sh` | Port 13133 of the agent answers HTTP 200 (the extension is enabled) |
| `validate-environment-attribute.sh` | The configuration uses `${env:DEPLOY_ENV}` and a new span on the gateway carries `deployment.environment` with the value `outpost-test` |
| `validate-secret-from-env.sh` | The literal token is gone from the ConfigMap, `${env:BACKEND_TOKEN}` is used and the variable still comes from the Secret |
| `validate-second-receiver.sh` | A span sent to port 4319 reaches the gateway |
| `validate-primary-receiver.sh` | A span sent to port 4318 still reaches the gateway (the merge did not drop the first receiver) |

Each check sends new OTLP/HTTP requests from the `shuttle` pod with a unique marker and looks for the marker in the log of the gateway, so it reads live behaviour and not only the ConfigMap. A rollout that is still running is covered by retries.
