#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
kubectl -n starfleet rollout restart deployment/gateway statefulset/scraper
kubectl -n starfleet rollout status deployment/gateway --timeout=180s
kubectl -n starfleet rollout status statefulset/scraper --timeout=180s
echo "[solution] Applied."
