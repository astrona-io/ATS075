#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# gateway answers on its metrics port through the Service.
set -u

for _ in $(seq 1 60); do
  if kubectl -n outpost exec deploy/drifter -- curl -s --max-time 3 http://gateway.starfleet.svc.cluster.local:8888/metrics 2>/dev/null | grep -q '^otelcol_'; then
    echo "[testing] The gateway metrics endpoint answers."
    sleep 5
    exit 0
  fi
  sleep 3
done
echo "[testing] The gateway metrics endpoint did not answer in time." >&2
exit 1
