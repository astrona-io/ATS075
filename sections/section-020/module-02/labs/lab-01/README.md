---
estimated_duration: 30m
---

# Lab: Put A Gateway Between The Agents And The Backend

Graded lab for the gateway deployment module. **UNTESTED: built untested.** It was validated statically only (`astrona validate`, `bash -n`, YAML parsing). The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-020/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-020/module-02/labs/lab-01
astrona destroy ats-075-lab-020-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-gateway-replicas.sh` | The Deployment `otel-gateway` has at least two ready replicas, and the Service `otel-gateway` (port 4318) has at least two ready endpoints |
| `validate-agent-via-gateway.sh` | The agent ConfigMap points at `otel-gateway` and not at `otel-backend`; a span that `shuttle` posts to the agent shows up in the backend log |
| `validate-credentials-central.sh` | The backend password is not in the agent ConfigMap or DaemonSet, not as a literal in the gateway, and the gateway reads it from the Secret `backend-credentials` |
| `validate-backend-requires-auth.sh` | The backend answers `401` without credentials and `200` with the gateway credentials |
| `validate-gateway-buffering.sh` | The gateway ConfigMap has `memory_limiter`, `batch`, a `sending_queue` with `queue_size: 5000` and `retry_on_failure` |

`backend-requires-auth` passes before any change. It fails if a fix weakens or breaks the backend.

## Notes

The `401` answer for a missing password comes from the `basicauth` server extension and was not run here.
