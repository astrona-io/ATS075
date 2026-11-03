#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
kubectl -n starfleet rollout restart deployment/otelcol
kubectl -n starfleet rollout status deployment/otelcol --timeout=240s
echo "[solution] Applied."
