---
estimated_duration: 25m
---

# Lab: Route Spans By Trace ID To Tail Sampling

Graded lab for the sharding module. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. Two `sampler` pods run `tail_sampling` and keep traces that have an error span. The `gateway` sends spans with a plain `otlp` exporter to the `sampler` ClusterIP Service, so one pod gets all the traffic. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-030/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-030/module-02/labs/lab-01
astrona destroy ats-075-lab-030-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-routing-configured.sh` | The gateway ConfigMap has a `load_balancing` exporter with a resolver, the traces pipeline uses it, `routing_key` is `traceID` or absent, and the gateway is available |
| `validate-traces-colocated.sh` | 20 traces of three spans each (three separate requests, three service names, one error span) are each kept whole by exactly one sampler pod |
| `validate-traces-spread.sh` | The 20 traces reach more than one sampler pod |

## Known risks

- The debug exporter output is matched by trace ID, once for each span. The grader counts lines that contain the trace ID.
- With 20 traces and two pods, the chance that all traces hash to one pod is about two in a million. A pass is not guaranteed to be repeatable in theory, and a failure on a correct solution should be repeated once.
- The grader waits 20 seconds for the `decision_wait` of 5 seconds and the batch timeout.
