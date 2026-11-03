#!/usr/bin/env bash
# Check: the live gateway configuration protects the gateway and buffers
# between the tiers: memory_limiter, batch, an explicit sending queue of 5000
# requests and retry on failure for the backend exporter.
set -uo pipefail

config="$(kubectl -n starfleet get configmap otel-gateway-config -o jsonpath='{.data.config\.yaml}' 2>/dev/null || true)"
if [ -z "$config" ]; then
  echo "FAIL: the ConfigMap otel-gateway-config with the key config.yaml does not exist"
  exit 1
fi

fail=0
# need <pattern> <message>
need() {
  if ! echo "$config" | grep -q -E "$1"; then
    echo "FAIL: $2"
    fail=1
  fi
}

need '^[[:space:]]*memory_limiter:' "the gateway has no memory_limiter processor"
need '^[[:space:]]*batch:' "the gateway has no batch processor"
need '^[[:space:]]*sending_queue:' "the backend exporter has no sending_queue section"
need '^[[:space:]]*queue_size:[[:space:]]*5000[[:space:]]*$' "the sending queue size is not 5000 requests"
need '^[[:space:]]*retry_on_failure:' "the backend exporter has no retry_on_failure section"

# The gateway must have at least one pod that can load this configuration.
pod="$(kubectl -n starfleet get pods -l app=otel-gateway -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
if [ -z "$pod" ]; then
  echo "FAIL: there is no gateway pod"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the gateway has memory_limiter, batch, a 5000-request queue and retry"
fi
exit "$fail"
