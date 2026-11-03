#!/usr/bin/env bash
# Check: the gateway Deployment is available and its health check answers 200.
set -uo pipefail

NS=starfleet
GATEWAY=http://gateway.starfleet.svc.cluster.local:4318
MARKER="check-$(date +%s)-${RANDOM}"

# post_json <path> <json body>: prints the HTTP status code, or 000 on failure.
post_json() {
  kubectl -n "$NS" exec deploy/shuttle -- curl -s -o /dev/null -m 15 -w '%{http_code}' -X POST \
    -H 'Content-Type: application/json' -d "$2" "${GATEWAY}$1" 2>/dev/null || true
}

# trace_body <span name> <email>: an OTLP/HTTP JSON trace with one span.
trace_body() {
  local now
  now="$(date +%s)000000000"
  printf '{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"scout"}}]},"scopeSpans":[{"scope":{"name":"lab"},"spans":[{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"eee19b7ec3c1b174","name":"%s","kind":1,"startTimeUnixNano":"%s","endTimeUnixNano":"%s","attributes":[{"key":"user.email","value":{"stringValue":"%s"}}]}]}]}]}' "$1" "$now" "$now" "$2"
}

log_body() {
  local now
  now="$(date +%s)000000000"
  printf '{"resourceLogs":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"scout"}}]},"scopeLogs":[{"scope":{"name":"lab"},"logRecords":[{"timeUnixNano":"%s","severityText":"INFO","body":{"stringValue":"%s"}}]}]}]}' "$now" "$1"
}

metric_body() {
  local now
  now="$(date +%s)000000000"
  printf '{"resourceMetrics":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"scout"}}]},"scopeMetrics":[{"scope":{"name":"lab"},"metrics":[{"name":"%s","sum":{"aggregationTemporality":2,"isMonotonic":true,"dataPoints":[{"asInt":"1","timeUnixNano":"%s"}]}}]}]}]}' "$1" "$now"
}

# wait_for_text <deployment> <text>: polls the logs of a Deployment for up to 80 seconds.
wait_for_text() {
  local attempt
  for attempt in $(seq 1 40); do
    if kubectl -n "$NS" logs "deploy/$1" --since=10m 2>/dev/null | grep -q -- "$2"; then
      return 0
    fi
    sleep 2
  done
  return 1
}

# require_clients: the curl client and the backend must exist.
require_clients() {
  if ! kubectl -n "$NS" get deploy/shuttle deploy/backend deploy/gateway >/dev/null 2>&1; then
    echo "FAIL: the Deployments gateway, backend and shuttle must exist in ${NS}. Fix the gateway, do not delete anything."
    exit 1
  fi
}

require_clients
desired="$(kubectl -n "$NS" get deploy/gateway -o jsonpath='{.spec.replicas}' 2>/dev/null)"
available="$(kubectl -n "$NS" get deploy/gateway -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
if [ -z "$available" ] || [ "$available" != "$desired" ]; then
  echo "FAIL: gateway has '${available:-0}' of '${desired}' replicas available. Read the error with kubectl logs deploy/gateway."
  exit 1
fi
code="$(kubectl -n "$NS" exec deploy/shuttle -- curl -s -o /dev/null -m 5 -w '%{http_code}' http://gateway.starfleet.svc.cluster.local:13133/ 2>/dev/null || true)"
if [ "$code" != "200" ]; then
  echo "FAIL: the gateway health check answered '${code}', expected 200"
  exit 1
fi
echo "PASS: the gateway is available and healthy"
