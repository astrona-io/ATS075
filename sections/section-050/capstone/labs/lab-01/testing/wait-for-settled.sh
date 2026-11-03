#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# restarted Collector answers its health check from inside the cluster.
set -uo pipefail

kubectl -n otel rollout status deployment/collector --timeout=180s >/dev/null 2>&1
for _ in $(seq 1 40); do
  code="$(kubectl -n otel exec sender -- curl -s -o /dev/null -w '%{http_code}' -m 5 http://collector.otel.svc.cluster.local:13133/ 2>/dev/null)"
  if [ "$code" = "200" ]; then
    echo "[testing] The Collector is healthy."
    sleep 3
    exit 0
  fi
  sleep 3
done
echo "[testing] The Collector did not become healthy in time." >&2
exit 1
