#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# gateway is ready and answers its health check through the Service.
set -uo pipefail

kubectl -n starfleet rollout status deployment/gateway --timeout=180s || exit 1
for i in $(seq 1 40); do
  code="$(kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -m 5 -w '%{http_code}' http://gateway.starfleet.svc.cluster.local:13133/ 2>/dev/null || true)"
  if [ "$code" = "200" ]; then
    echo "[testing] The gateway is healthy."
    exit 0
  fi
  sleep 3
done
echo "[testing] The gateway did not become healthy in time." >&2
exit 1
