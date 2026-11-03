#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# headless Service lists both sampler pods and the gateway has had time to
# resolve them.
set -u

for _ in $(seq 1 60); do
  ready=$(kubectl -n starfleet get endpoints sampler-headless -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w | tr -d ' ')
  if [ "$ready" -ge 2 ]; then
    echo "[testing] Both sampler pods are listed."
    sleep 10
    exit 0
  fi
  sleep 3
done
echo "[testing] The sampler pods were not ready in time." >&2
exit 1
