#!/usr/bin/env bash
# Starting state for the lab. Environment only: the gateway and backend
# Collectors with their ConfigMaps and Services, and the curl client. The
# learner changes the gateway configuration.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

kubectl -n starfleet rollout status deployment/backend --timeout=240s
kubectl -n starfleet rollout status deployment/shuttle --timeout=180s
# The gateway does not start in this lab: its configuration is invalid on purpose.
echo "[lab] Ready."
