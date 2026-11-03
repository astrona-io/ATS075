---
estimated_duration: 25m
---

# Lab: Protect And Observe A Gateway Collector

Graded lab for the capacity module. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. A `gateway` Collector forwards traces to a `backend` Collector. The gateway hides its own metrics, sends to the wrong port, has a small queue and has no protection against memory growth. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-030/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-030/module-01/labs/lab-01
astrona destroy ats-075-lab-030-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-self-metrics.sh` | The gateway Service answers on port 8888 with `otelcol_exporter_queue_capacity` and `otelcol_exporter_queue_size` |
| `validate-delivery.sh` | A span sent to the gateway with OTLP over HTTP appears in the backend log |
| `validate-protection.sh` | `memory_limiter` is the first processor, `batch` follows, `limit_mib` or `limit_percentage` is set and the container memory limit is higher than `limit_mib` |
| `validate-queue-capacity.sh` | The running gateway reports an exporter queue capacity of at least 5000 |

## Known risks

- The grader reads the pipeline with text matching and expects the flow style `processors: [memory_limiter, batch]`, as in the starting file.
- The metric names are matched by prefix, so a `_total` suffix or a unit suffix does not matter.
- The queue capacity assumes the default `sizer` (`requests`), where the capacity equals `queue_size`.
