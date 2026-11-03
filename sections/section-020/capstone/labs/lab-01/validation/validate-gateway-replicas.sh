#!/usr/bin/env bash
# Check: a Deployment otel-gateway with at least two ready replicas exists, and
# the Service otel-gateway has at least two ready endpoints on port 4318.
set -uo pipefail

if ! kubectl -n starfleet get deployment otel-gateway >/dev/null 2>&1; then
  echo "FAIL: there is no Deployment otel-gateway in starfleet"
  exit 1
fi
if ! kubectl -n starfleet rollout status deployment/otel-gateway --timeout=120s >/dev/null 2>&1; then
  echo "FAIL: the otel-gateway Deployment is not rolled out"
  exit 1
fi

fail=0
ready="$(kubectl -n starfleet get deployment otel-gateway -o jsonpath='{.status.readyReplicas}')"
if [ -z "$ready" ] || [ "$ready" -lt 2 ]; then
  echo "FAIL: the gateway has ${ready:-0} ready replicas, expected at least 2"
  fail=1
fi

port="$(kubectl -n starfleet get service otel-gateway -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || true)"
if [ "$port" != "4318" ]; then
  echo "FAIL: the Service otel-gateway must exist and expose port 4318 (found '${port:-none}')"
  fail=1
else
  endpoints="$(kubectl -n starfleet get endpointslices -l kubernetes.io/service-name=otel-gateway -o json \
    | jq '[.items[].endpoints[]? | select(.conditions.ready == true)] | length')"
  if [ "${endpoints:-0}" -lt 2 ]; then
    echo "FAIL: the Service otel-gateway has ${endpoints:-0} ready endpoints, expected at least 2"
    fail=1
  fi
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the gateway runs with $ready ready replicas behind the Service otel-gateway"
fi
exit "$fail"
