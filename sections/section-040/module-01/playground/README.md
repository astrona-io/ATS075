# Signal Paths, Shared Components And Fan-Out - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-075-playground-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** UNTESTED. Built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing). It has not been started.

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`). The
namespace `starfleet` runs the `gateway` Collector (the one you edit through the
ConfigMap `collector-config`), a `backend` Collector that prints every signal it
receives, and a `shuttle` pod with curl. The image is
`otel/opentelemetry-collector-contrib:0.162.0`. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-075-playground-040-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config
path. `astrona submit` and `astrona test` do not apply: there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/pipelines.yaml` | Namespace, the gateway and backend Collectors with their ConfigMaps and Services, and the curl client |
| `docs/overview.md` | What the environment contains, the helper functions and ideas to try |
