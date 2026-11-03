# Gateway Deployment And Agent-To-Gateway Export - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-075-playground-020-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** UNTESTED (built untested; validated statically only)

Starting state in the `starfleet` namespace: a backend Collector (`otel-backend`) that accepts OTLP over HTTP only with a user name and password, a `shuttle` client pod, and an agent DaemonSet (`otel-agent`) that exports straight to the backend. There is no gateway. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-075-playground-020-02
```

Readers start it from the module page with `astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-020/module-02/playground`.
