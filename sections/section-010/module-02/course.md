---
draft: true
exam_objectives:
- Configuration
---
# Configuration Sources, Environment Values And Extensions

This module teaches where a Collector configuration comes from and how its values are filled in. It covers environment variable expansion, several configuration files merged in a fixed order, providers that read from files and environment variables, secrets that stay out of the configuration, the `health_check` extension and components that have more than one named instance.

## Learning Goals

- Write `${env:NAME}` and `${env:NAME:-default}` in a configuration, say when the value is read and what an unset variable gives.
- Start a Collector with two `--config` files, and predict the merged result, including the rule that a list replaces a list.
- Name the configuration providers (`file`, `env`, `yaml`, `http`, `https`) and choose between an environment variable and a mounted file for a secret.
- Enable an extension such as `health_check` and explain why a defined extension that is not listed under `service` does nothing.
- Define a second instance of a component with a `type/name` identifier, and validate a set of files before a restart.

## Before You Start

You should know what a pod, a Deployment, a ConfigMap and a Secret are in Kubernetes, and that a container can read a Secret as an environment variable. You should know that a Collector configuration defines components and that a pipeline activates them. The hands-on parts use a playground with a kind cluster and a Collector that starts with two configuration files.

## Reading Order

1. Environment Variables In Configuration
2. Several Files, Providers And Secrets
3. Extensions, Named Instances And Validation
4. Summary

<!-- astrona:playground -->
