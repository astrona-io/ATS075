#!/usr/bin/env bash
# Check: a span sent to the gateway reaches the backend Collector (shown by the debug exporter in the backend log).
set -u
fail() { echo "FAIL: $*"; exit 1; }

GATEWAY_URL="http://gateway.starfleet.svc.cluster.local:4318/v1/traces"

# send_span <trace id> <span id> <span name> <service name> <status code>
# Sends one span as OTLP/HTTP JSON from the drifter pod. Prints the HTTP status.
send_span() {
  local now_ns payload
  now_ns=$(( $(date +%s) * 1000000000 ))
  payload=$(printf '{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"%s"}}]},"scopeSpans":[{"scope":{"name":"grader"},"spans":[{"traceId":"%s","spanId":"%s","name":"%s","kind":1,"startTimeUnixNano":"%s","endTimeUnixNano":"%s","status":{"code":%s}}]}]}]}' \
    "$4" "$1" "$2" "$3" "$((now_ns - 1000000000))" "$now_ns" "$5")
  kubectl -n outpost exec deploy/drifter -- curl -s -o /dev/null -w '%{http_code}' --max-time 10 \
    -X POST -H 'Content-Type: application/json' -d "$payload" "$GATEWAY_URL" 2>/dev/null
}

tag=$(printf '%06x' $(( (RANDOM * 32768 + RANDOM) % 16777216 )))
trace_id=$(printf '%s%02x%08x%08x%08x' "$tag" 1 $((RANDOM * 32768 + RANDOM)) $((RANDOM * 32768 + RANDOM)) $((RANDOM * 32768 + RANDOM)))
span_id=$(printf '%02x%06x%08x' 1 "$((16#$tag))" $((RANDOM * 32768 + RANDOM)))
span_name="grader-delivery-$tag"

code=$(send_span "$trace_id" "$span_id" "$span_name" scout 0)
[ "$code" = "200" ] || fail "the gateway answered HTTP '$code' on port 4318 (expected 200)"

for _ in $(seq 1 20); do
  if kubectl -n starfleet logs deployment/backend --tail=-1 2>/dev/null | grep -q "$span_name"; then
    echo "PASS: the span $span_name travelled from the gateway to the backend"
    exit 0
  fi
  sleep 3
done
fail "the span $span_name did not reach the backend within 60 seconds (check the gateway exporter endpoint and its logs)"
