#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until two
# gateway endpoints are ready, so the validation scripts do not race the
# endpoint controller.
set -euo pipefail

for _ in $(seq 1 30); do
  ready="$(kubectl -n starfleet get endpointslices -l kubernetes.io/service-name=otel-gateway -o json 2>/dev/null \
    | jq '[.items[].endpoints[]? | select(.conditions.ready == true)] | length' 2>/dev/null || echo 0)"
  if [ "${ready:-0}" -ge 2 ]; then
    echo "[testing] the gateway Service has $ready ready endpoints."
    exit 0
  fi
  sleep 2
done
echo "[testing] the gateway Service did not get two ready endpoints in time." >&2
exit 1
