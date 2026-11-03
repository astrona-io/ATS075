---
estimated_duration: 45m
---

# Capstone: A Protected, Trace-Aware And Sharded Collector Fleet

Graded capstone for the scaling section. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. It combines both modules: protect and expose a gateway Collector, route traces by trace ID to two `tail_sampling` pods, and shard the scrape work of a two-pod scraper StatefulSet so that no target is scraped twice. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-030/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-030/capstone/labs/lab-01
astrona destroy ats-075-capstone-030
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-protection.sh` | `memory_limiter` is first, `batch` follows, the container has a memory limit above `limit_mib` |
| `validate-self-metrics.sh` | The gateway Service answers on port 8888 with queue metrics |
| `validate-queue-capacity.sh` | The running exporter queue capacity is at least 5000 |
| `validate-routing-configured.sh` | A `load_balancing` exporter with a resolver routes by `traceID` and the pipeline uses it |
| `validate-traces-colocated.sh` | 20 traces are each kept whole by exactly one sampler pod |
| `validate-traces-spread.sh` | The traces reach more than one sampler pod |
| `validate-scrape-sharded.sh` | Each of the three scrape targets appears in the log of exactly one scraper pod |
| `validate-services-available.sh` | The gateway, both samplers and both scrapers are available |

## Known risks

- The sharding check greps the debug exporter output for `service.instance.id` lines that name the target. The attribute name is the one the `prometheus` receiver sets on scraped resources, and the exact log layout is assumed for the installed version.
- The `${env:SHARD}` value in `regex` depends on the Collector expanding the environment variable before the Prometheus configuration is parsed.
- The `SHARD` variable uses the pod label `apps.kubernetes.io/pod-index`, which Kubernetes sets on StatefulSet pods.
- The checks that send traces carry the same timing and probability notes as the routing lab.
