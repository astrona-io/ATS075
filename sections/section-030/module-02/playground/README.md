# Sharding And Stateful Processing - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-075-playground-030-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** UNTESTED. Built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing). It has not been started.

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with a
two-layer Collector fleet in `starfleet`. The `gateway` Collector receives OTLP
and sends spans with the `load_balancing` exporter, routed by trace ID, to two
`sampler` Collector pods that run the `tail_sampling` processor. A `scraper`
StatefulSet with two pods scrapes the metrics endpoints of the other Collectors
with the `prometheus` receiver. It is not sharded on purpose, so every target
is scraped twice. The `drifter` pod in `outpost` runs `curl`. Plain manifests
only. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-075-playground-030-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config
path. `astrona submit` and `astrona test` do not apply: there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, bootstrap) |
| `bootstrap/prepare.sh` | Applies the manifests and waits for the rollouts |
| `manifests/starfleet.yaml` | Namespaces, gateway, samplers, scraper StatefulSet, Services and the curl client |
| `docs/overview.md` | What the environment contains, helpers and ideas to try |
