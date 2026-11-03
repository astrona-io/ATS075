#!/usr/bin/env bash
# Starting state for the Clean Up Telemetry Before Export lab (ats-075-lab-050-01).
# Environment only: no task state, no grading. The Collector has no processors afterwards.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/collector.yaml"
kubectl -n otel rollout status deployment/collector --timeout=180s
kubectl -n otel wait --for=condition=Ready pod/sender --timeout=180s
echo "[env] Ready: Collector 0.162.0 in namespace otel with a pass-through configuration, curl pod sender."
