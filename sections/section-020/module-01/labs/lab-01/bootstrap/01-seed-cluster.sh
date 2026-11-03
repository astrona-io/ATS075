#!/usr/bin/env bash
# Starting state for the agent lab. Environment only: it creates the client pod
# and the agent with its minimal configuration. It does not create any RBAC
# rule or processor that the learner must write.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/start.yaml"
kubectl -n starfleet rollout status deployment/shuttle --timeout=180s
kubectl -n starfleet rollout status daemonset/otel-agent --timeout=180s
echo "[lab] Ready."
