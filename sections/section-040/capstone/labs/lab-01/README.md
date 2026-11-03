---
estimated_duration: 40m
---

# Capstone: Repair A Gateway Collector Pipeline Set

Graded capstone for the pipelines section. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. The `gateway` Collector does not start. Behind that fault are an unused exporter, an unused processor, a missing logs pipeline and an exporter without a sending queue. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-040/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-040/capstone/labs/lab-01
astrona destroy ats-075-capstone-040
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-gateway-healthy.sh` | The `gateway` Deployment has all replicas available and port 13133 answers 200 |
| `validate-trace-fanout.sh` | A trace gets HTTP 200 in under 10 seconds and reaches the `backend` and the `gateway` log |
| `validate-redaction.sh` | A unique `user.email` value appears in neither the `backend` nor the `gateway` log |
| `validate-archive-queue.sh` | `otlphttp/archive` still runs and exposes a queue capacity metric |
| `validate-logs-pipeline.sh` | A log record reaches the `backend` |
| `validate-metrics-pipeline.sh` | A metric posted over OTLP reaches the `backend` |
| `validate-count-metric.sh` | The metric `trace.span.count` reaches the `backend` after a trace is posted |

## Known risks

- The bootstrap does not wait for the `gateway`, because it crashes on purpose. A learner can start grading before the pod is ready, and the checks then fail with a clear message.
- The checks read pod logs with `--since=10m` and look for unique markers that the `debug` exporter prints at `detailed` verbosity.
