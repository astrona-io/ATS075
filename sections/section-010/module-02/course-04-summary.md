---
draft: true
exam_objectives:
- Configuration
---
# Summary

A Collector configuration can contain references that the Collector replaces when it loads the file. The reference `${env:NAME}` takes the value of an environment variable, `${env:NAME:-fallback}` gives a fallback when the variable is not set, and `$$` writes a literal dollar sign. A part of the Collector called the resolver does the replacement once, at start, before it checks the components and builds the pipelines. A running Collector therefore does not see a changed variable, and a new process is needed.

The `--config` flag can be repeated. The Collector merges the sources in the order of the flags. Maps merge key by key, and a list in a later source replaces the whole list from an earlier source. This rule makes an override file powerful and risky: a short exporter list in the override removes an exporter from the merged pipeline without an error. Providers read the sources. The `file`, `env`, `yaml`, `http` and `https` schemes read a file, an environment variable, an inline YAML text and a web address, and the same schemes work inside a value.

Secrets stay out of the configuration. A ConfigMap is readable by everyone who can read ConfigMaps, and a Secret is only base64 encoded, so the access rules around it are the real protection. The Deployment gives the Secret to the Collector as an environment variable or a mounted file, and the configuration refers to it with `${env:NAME}` or `${file:/path}`.

An extension adds behaviour that is not in the data path, such as the `health_check` endpoint that Kubernetes probes call. It runs only when `service.extensions` lists it. A component identifier of the form `type/name` lets one file hold several components of the same type, such as `otlp` and `otlp/second`, and a pipeline lists the full identifier. The `validate` command loads all the files in order, like a real start, and finds a wrong identifier or a missing definition before a restart.

Key facts:

- `${env:NAME}`, `${env:NAME:-fallback}` and `$$` are the three forms to know.
- Values are read at start, so restart after a change.
- Maps are merged, lists are replaced, the last source wins.
- Put secrets in a Secret and refer to them with `${env:...}` or `${file:...}`.
- An extension must be listed under `service.extensions`.
- Validate the merged files before every rollout.

<!-- astrona:playground:destroy -->
