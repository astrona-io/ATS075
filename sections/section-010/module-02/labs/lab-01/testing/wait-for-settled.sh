#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until only
# the new agent pod is left.
set -euo pipefail

for i in $(seq 1 30); do
  pods="$(kubectl -n starfleet get pods -l app=otelcol -o json | jq '[.items[] | select(.metadata.deletionTimestamp == null)] | length')"
  terminating="$(kubectl -n starfleet get pods -l app=otelcol -o json | jq '[.items[] | select(.metadata.deletionTimestamp != null)] | length')"
  if [ "$pods" = "1" ] && [ "$terminating" = "0" ]; then
    echo "[testing] settled."
    exit 0
  fi
  sleep 2
done
echo "[testing] the agent did not settle in time." >&2
exit 1
