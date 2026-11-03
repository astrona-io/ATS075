---
estimated_duration: 30m
---

# Lab: Count Spans With A Connector And Isolate A Failing Exporter

Graded lab for the connectors module. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. The `gateway` Collector in `starfleet` exports traces to an archive address that does not exist, with the sending queue switched off. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-040/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-040/module-02/labs/lab-01
astrona destroy ats-075-lab-040-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-trace-fanout.sh` | A trace posted to the gateway gets HTTP 200 in under 10 seconds and reaches the `backend` and the `gateway` log (fails while the failing exporter blocks the request) |
| `validate-archive-queue.sh` | The metric `otelcol_exporter_queue_capacity` exists for `otlphttp/archive`, so the exporter still runs and has a queue |
| `validate-count-metric.sh` | After a trace is posted, the metric name `trace.span.count` appears in the `backend` log |
| `validate-gateway-healthy.sh` | The `gateway` Deployment has all replicas available and port 13133 answers 200 |

## Known risks

- The blocking behavior of the start state depends on the exporter retry logic running inside the request. The check only asks for a fast answer and does not depend on how the Collector orders its exporters.
- The metric name label format `exporter="otlphttp/archive"` on port 8888 is read with a pattern match, so a different label layout in a later release would need a change in the script.
