#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the agent
# pods are ready and the first host metrics reached the debug exporter, so the
# validation scripts do not race the first collection interval.
set -euo pipefail

kubectl -n starfleet rollout status daemonset/otel-agent --timeout=180s
for _ in $(seq 1 30); do
  if kubectl -n starfleet logs -l app=otel-agent --tail=2000 2>/dev/null | grep -q 'system.cpu.load_average.1m'; then
    echo "[testing] the agent exports host metrics."
    exit 0
  fi
  sleep 2
done
echo "[testing] no host metrics seen in time." >&2
exit 1
