#!/usr/bin/env bash
# Starting state for the agent playground: applies the namespace, the client
# pod and the agent DaemonSet, then waits until they are ready.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/start.yaml"
kubectl -n starfleet rollout status deployment/shuttle --timeout=180s
kubectl -n starfleet rollout status daemonset/otel-agent --timeout=180s
echo "[playground] Ready."
