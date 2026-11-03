# Capacity Signals And Protecting The Collector - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-075-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** UNTESTED. Built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing). It has not been started.

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`). The
`starfleet` namespace holds a `backend` Collector that prints every span with the
debug exporter, and a `gateway` Collector (`otel/opentelemetry-collector-contrib:0.162.0`)
that receives OTLP on ports 4317 and 4318, runs a `memory_limiter` and a `batch`
processor, and exports to the backend. The gateway exposes its own metrics on
port 8888. The `drifter` pod in `outpost` runs `curl` and sends test spans.
Plain manifests only: no operator, no Helm. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-075-playground-030-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config
path. `astrona submit` and `astrona test` do not apply: there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, bootstrap) |
| `bootstrap/prepare.sh` | Applies the manifests and waits for the rollouts |
| `manifests/starfleet.yaml` | Namespaces, backend, gateway, Services and the curl client |
| `docs/overview.md` | What the environment contains, helpers and ideas to try |
