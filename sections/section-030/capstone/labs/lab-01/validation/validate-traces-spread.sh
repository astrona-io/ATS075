#!/usr/bin/env bash
# Check: with 20 different trace IDs, more than one sampler pod receives traces. A plain otlp exporter keeps one connection and sends everything to one pod.
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

TRACE_COUNT=20
SERVICES="scout probe shuttle"

tag=$(printf '%06x' $(( (RANDOM * 32768 + RANDOM) % 16777216 )))
ids_file=$(mktemp)
logs_dir=$(mktemp -d)
trap 'rm -rf "$ids_file" "$logs_dir"' EXIT

# Each trace has three spans that go to the gateway in three separate
# requests, from three services. The middle span has status ERROR, so the
# tail_sampling policy keeps the trace only if one sampler sees all its spans.
for i in $(seq 1 "$TRACE_COUNT"); do
  trace_id=$(printf '%s%02x%08x%08x%08x' "$tag" "$i" $((RANDOM * 32768 + RANDOM)) $((RANDOM * 32768 + RANDOM)) $((RANDOM * 32768 + RANDOM)))
  echo "$trace_id" >> "$ids_file"
  n=0
  for service in $SERVICES; do
    n=$((n + 1))
    span_id=$(printf '%02x%06x%08x' "$n" "$((16#$tag))" $((RANDOM * 32768 + RANDOM)))
    status=0
    [ "$n" -eq 2 ] && status=2
    code=$(send_span "$trace_id" "$span_id" "grader-$tag-$n" "$service" "$status")
    [ "$code" = "200" ] || fail "the gateway answered HTTP '$code' on port 4318 (expected 200)"
  done
done

# decision_wait is 5s on the samplers, and the gateway batches for 1s.
sleep 20

pods=$(kubectl -n starfleet get pods -l app=sampler -o jsonpath='{.items[*].metadata.name}')
[ -n "$pods" ] || fail "no sampler pods found"
for pod in $pods; do
  kubectl -n starfleet logs "$pod" --tail=-1 > "$logs_dir/$pod.log" 2>/dev/null
done

holding_pods=0
for log in "$logs_dir"/*.log; do
  if grep -q "$tag" "$log"; then
    holding_pods=$((holding_pods + 1))
  fi
done

[ "$holding_pods" -ge 2 ] || fail "only $holding_pods sampler pod received the traces: the gateway does not spread traces over the sampler pods"
echo "PASS: the traces were spread over $holding_pods sampler pods"
