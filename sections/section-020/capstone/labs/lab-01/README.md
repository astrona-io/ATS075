---
estimated_duration: 40m
---

# Capstone: A Two-Tier Collector Deployment

Graded capstone for the deployment section. **UNTESTED: built untested.** It was validated statically only (`astrona validate`, `bash -n`, YAML parsing). The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-020/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-020/capstone/labs/lab-01
astrona destroy ats-075-capstone-020
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-agent-rbac.sh` | The `otel-agent` DaemonSet is ready on every node; its service account can list and watch pods and namespaces but cannot read Secrets, delete pods or create Deployments |
| `validate-gateway-replicas.sh` | The Deployment `otel-gateway` has at least two ready replicas and the Service `otel-gateway` has at least two ready endpoints |
| `validate-credentials-central.sh` | The backend password is not in the agent ConfigMap or DaemonSet, not a literal in the gateway, and the gateway reads it from the Secret `backend-credentials` |
| `validate-end-to-end.sh` | A span posted by `shuttle` reaches the backend through the agent and the gateway with `k8s.namespace.name`, `k8s.pod.name`, `k8s.node.name`, `k8s.deployment.name` and `deployment.environment.name=lab` |
| `validate-backend-requires-auth.sh` | The backend answers `401` without credentials and `200` with the gateway credentials |

`backend-requires-auth` passes before any change. It fails if a fix breaks the backend.
