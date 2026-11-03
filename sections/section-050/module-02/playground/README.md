# The Transform Processor And Data Safety - Playground

- **Slug:** ats-075-playground-050-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with the OpenTelemetry Collector (`otel/opentelemetry-collector-contrib:0.162.0`) in the namespace `otel` and a curl pod named `sender`. UNTESTED: built with static checks only. Nothing to submit.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-050/module-02/playground
astrona destroy ats-075-playground-050-02
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, manifests) |
| `manifests/collector.yaml` | Namespace, ConfigMap with the Collector configuration, Deployment, Service and the sender pod |
| `docs/overview.md` | What the environment contains and ideas to try |
