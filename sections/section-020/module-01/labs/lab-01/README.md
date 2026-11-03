---
estimated_duration: 25m
---

# Lab: Configure A Collector Agent At The Edge

Graded lab for the agent deployment patterns module. **UNTESTED: built untested.** It was validated statically only (`astrona validate`, `bash -n`, YAML parsing). The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-020/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-020/module-01/labs/lab-01
astrona destroy ats-075-lab-020-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-agent-rbac.sh` | The `otel-agent` DaemonSet is ready on every node; its service account can list and watch pods and namespaces but cannot read Secrets, delete pods or create Deployments |
| `validate-traces-enriched.sh` | A span posted by `shuttle` shows `k8s.namespace.name`, `k8s.pod.name`, `k8s.node.name` and `k8s.deployment.name` in the debug output of the agent |
| `validate-resource-attributes.sh` | The same span carries `deployment.environment.name=lab` |
| `validate-host-metrics.sh` | The agent output has `system.cpu.load_average.1m` and `system.memory.usage`, and the metrics carry `host.name` |

All four checks fail on the starting state. The grader sends real OTLP requests with `curl` from the `shuttle` pod and reads the agent log.

## Notes

The checks read the output of the debug exporter. The line format (`-> key: Str(value)`) comes from the debug exporter documentation and was not run here.
