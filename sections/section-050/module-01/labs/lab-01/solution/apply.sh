#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
kubectl -n otel rollout restart deployment/collector
kubectl -n otel rollout status deployment/collector --timeout=180s
echo "[solution] Applied."
