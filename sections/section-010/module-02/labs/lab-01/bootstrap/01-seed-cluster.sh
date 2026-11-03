#!/usr/bin/env bash
# Starting state: the gateway Collector in outpost, the shuttle sender and the
# agent Collector in starfleet with a configuration that has deliberate faults.
# Environment only: it does not fix the configuration.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

kubectl -n outpost rollout status deployment/gateway --timeout=240s
kubectl -n starfleet rollout status deployment/shuttle --timeout=240s
kubectl -n starfleet rollout status deployment/otelcol --timeout=240s
echo "[lab] Ready."
