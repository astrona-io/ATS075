# Agent Deployment Patterns - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-075-playground-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** UNTESTED (built untested; validated statically only)

Starting state: a `shuttle` client pod and an OpenTelemetry Collector agent that runs as a DaemonSet in the `starfleet` namespace. The agent receives OTLP over HTTP on port 4318 and prints traces with the debug exporter. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-075-playground-020-01
```

Readers start it from the module page with `astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-020/module-01/playground`.
