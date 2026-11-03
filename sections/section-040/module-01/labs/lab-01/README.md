---
estimated_duration: 25m
---

# Lab: Fan Out Signals From One Receiver

Graded lab for the pipelines module. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. The `gateway` Collector in `starfleet` exports traces only to its own `debug` exporter. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-040/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-040/module-01/labs/lab-01
astrona destroy ats-075-lab-040-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-trace-fanout.sh` | A trace posted to the gateway gets HTTP 200 in under 10 seconds and its span name appears in the `backend` log and the `gateway` log |
| `validate-logs-pipeline.sh` | A log record posted to the gateway appears in the `backend` log |
| `validate-redaction.sh` | A span carrying a unique `user.email` value arrives at the `backend`, and the value appears in neither the `backend` nor the `gateway` log |
| `validate-gateway-healthy.sh` | The `gateway` Deployment has all replicas available and port 13133 answers 200 |

## Known risks

- The checks read pod logs with `--since=10m` and look for a unique marker. They rely on the `debug` exporter printing span names, log bodies and attribute values at `detailed` verbosity.
- The `batch` processor waits one second before it sends, so the checks poll for up to 80 seconds.
