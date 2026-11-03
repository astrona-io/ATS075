---
estimated_duration: 25m
---

# Lab: Enable Pipelines For All Three Signals

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The agent Collector starts with a receiver on `localhost`, a traces pipeline that only prints spans and no metrics or logs pipeline. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-010/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-075-lab-010-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-agent-ready.sh` | The agent Deployment is available with the original contrib image |
| `validate-traces-reach-gateway.sh` | A span sent to port 4318 of the agent appears in the gateway log |
| `validate-metrics-reach-gateway.sh` | A metric sent to port 4318 appears in the gateway log |
| `validate-logs-reach-gateway.sh` | A log record sent to port 4318 appears in the gateway log |
| `validate-gateway-unchanged.sh` | The gateway keeps its image and its debug exporter (the backend was not changed to pass) |

Each check sends new OTLP/HTTP requests from the `shuttle` pod with a unique marker and looks for the marker in the log of the gateway, so it reads live behaviour and not only the ConfigMap. A rollout that is still running is covered by retries.
