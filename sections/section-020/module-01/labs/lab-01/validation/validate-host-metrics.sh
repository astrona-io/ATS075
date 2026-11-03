#!/usr/bin/env bash
# Check: the agent scrapes host metrics (load and memory) and the exported
# metrics carry the host.name resource attribute from the system detector.
set -uo pipefail

if ! kubectl -n starfleet rollout status daemonset/otel-agent --timeout=120s >/dev/null 2>&1; then
  echo "FAIL: the otel-agent DaemonSet is not rolled out"
  exit 1
fi

fail=0
logs=""
for _ in $(seq 1 20); do
  logs="$(kubectl -n starfleet logs -l app=otel-agent --tail=4000 2>/dev/null || true)"
  if echo "$logs" | grep -q -F "system.cpu.load_average.1m"; then
    break
  fi
  sleep 2
done

if ! echo "$logs" | grep -q -F "system.cpu.load_average.1m"; then
  echo "FAIL: no system.cpu.load_average.1m metric in the agent output (hostmetrics receiver with the load scraper)"
  fail=1
fi
if ! echo "$logs" | grep -q -F "system.memory.usage"; then
  echo "FAIL: no system.memory.usage metric in the agent output (memory scraper)"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  if ! echo "$logs" | grep -B30 -F "system.cpu.load_average.1m" | grep -q -F "host.name: Str("; then
    echo "FAIL: the host metrics carry no host.name resource attribute (system detector in the metrics pipeline)"
    fail=1
  fi
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the agent exports load and memory metrics with host.name"
fi
exit "$fail"
