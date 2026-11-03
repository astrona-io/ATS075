#!/usr/bin/env bash
# Environment preparation for the capacity lab (ats-075-lab-030-01). It applies the manifests and waits until
# every workload is ready. There is no task here; the files under manifests/ hold
# the whole starting state.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[setup] Applying the manifests..."
kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet rollout status deployment/backend --timeout=240s
kubectl -n starfleet rollout status deployment/gateway --timeout=240s
kubectl -n outpost rollout status deployment/drifter --timeout=240s
echo "[setup] Ready."
