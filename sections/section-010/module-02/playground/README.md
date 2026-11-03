# Configuration Sources, Environment Values And Extensions - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-075-playground-010-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with three
workloads: the `gateway` Collector in `outpost` (prints everything it receives),
the `shuttle` pod in `starfleet` (curl, sends OTLP/HTTP requests) and the
`otelcol` agent Collector in `starfleet`. The agent reads two configuration files and gets its gateway address from an environment variable. The variables DEPLOY_ENV and BACKEND_TOKEN (from the Secret gateway-token) exist in the Deployment but no file uses them yet. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-075-playground-010-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the
config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/lab-start.yaml` | Namespaces, gateway, shuttle, agent ConfigMap, Deployment and Service |
| `docs/overview.md` | What the environment contains, helper functions and ideas to try |
