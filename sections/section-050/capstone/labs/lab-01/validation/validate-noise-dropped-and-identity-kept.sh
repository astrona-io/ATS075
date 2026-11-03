#!/usr/bin/env bash
# Check: DEBUG log records and the metric scout.debug.counter are dropped, and user.id is removed from the shuttle.requests data points
set -uo pipefail
NS=otel
RUN="r$(date +%s)$RANDOM"
COLLECTOR_URL="http://collector.${NS}.svc.cluster.local:4318"
fail=0

# post <signal> <json>: posts an OTLP/HTTP JSON document from the sender pod.
# Retries for about 30 seconds, because the Collector may still be restarting.
post() {
  local signal="$1" body="$2" code="" i
  for i in $(seq 1 10); do
    code="$(printf '%s' "$body" | kubectl -n "$NS" exec -i sender -- curl -s -o /dev/null -w '%{http_code}' -m 10 \
      -H 'Content-Type: application/json' -X POST "${COLLECTOR_URL}/v1/${signal}" -d @- 2>/dev/null)"
    [ "$code" = "200" ] && return 0
    sleep 3
  done
  return 1
}

# collector_logs: what the Collector wrote in the last five minutes (debug exporter output included).
collector_logs() { kubectl -n "$NS" logs -l app=collector --tail=-1 --since=300s 2>&1; }

# wait_for <text>: waits up to about 60 seconds until the text appears in the Collector logs.
wait_for() {
  local i
  for i in $(seq 1 20); do
    collector_logs | grep -qF -- "$1" && return 0
    sleep 3
  done
  return 1
}

# resource_block <text>: prints the debug output of the one resource (ResourceSpans,
# ResourceLog or ResourceMetrics block) that contains the text.
resource_block() {
  awk -v n="$1" '
    /^Resource(Spans|Log|Metrics) #/ { if (hit) printf "%s", buf; buf = ""; hit = 0 }
    { buf = buf $0 "\n"; if (index($0, n)) hit = 1 }
    END { if (hit) printf "%s", buf }'
}

# span_block <name>: prints the debug output of one span, from its name line to the next span.
span_block() {
  awk -v n="$1" '/Span #/ { f = 0 } index($0, "Name") && index($0, n) { f = 1 } f'
}

# attr <key> <value>: one OTLP string attribute.
attr() { printf '{"key":"%s","value":{"stringValue":"%s"}}' "$1" "$2"; }

# span <name> <attributes>: one OTLP span. The attributes argument is a comma-separated list of attr output.
span() {
  printf '{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"%016x","name":"%s","kind":2,"startTimeUnixNano":"1700000000000000000","endTimeUnixNano":"1700000001000000000","attributes":[%s]}' \
    "$((RANDOM * 32768 + RANDOM))" "$1" "$2"
}

# spans_payload <resource attributes> <span> [<span>...]: a complete /v1/traces document.
spans_payload() {
  local resource="$1" joined="" s
  shift
  for s in "$@"; do joined="${joined:+$joined,}$s"; done
  printf '{"resourceSpans":[{"resource":{"attributes":[%s]},"scopeSpans":[{"scope":{"name":"grader"},"spans":[%s]}]}]}' "$resource" "$joined"
}

# log_record <severity number> <severity text> <body>: one OTLP log record.
log_record() {
  printf '{"timeUnixNano":"1700000000000000000","severityNumber":%s,"severityText":"%s","body":{"stringValue":"%s"},"attributes":[]}' "$1" "$2" "$3"
}

# logs_payload <resource attributes> <record> [<record>...]: a complete /v1/logs document.
logs_payload() {
  local resource="$1" joined="" s
  shift
  for s in "$@"; do joined="${joined:+$joined,}$s"; done
  printf '{"resourceLogs":[{"resource":{"attributes":[%s]},"scopeLogs":[{"scope":{"name":"grader"},"logRecords":[%s]}]}]}' "$resource" "$joined"
}

# sum_metric <name> <data point> [<data point>...]: one monotonic sum in a complete /v1/metrics document.
# A data point is: {"attributes":[...],"startTimeUnixNano":"1700000000000000000","timeUnixNano":"1700000060000000000","asInt":"5"}
datapoint() {
  printf '{"attributes":[%s],"startTimeUnixNano":"1700000000000000000","timeUnixNano":"1700000060000000000","asInt":"%s"}' "$1" "$2"
}
metrics_payload() {
  local resource="$1" name="$2" joined="" s
  shift 2
  for s in "$@"; do joined="${joined:+$joined,}$s"; done
  printf '{"resourceMetrics":[{"resource":{"attributes":[%s]},"scopeMetrics":[{"scope":{"name":"grader"},"metrics":[{"name":"%s","unit":"1","sum":{"aggregationTemporality":2,"isMonotonic":true,"dataPoints":[%s]}}]}]}]}' "$resource" "$name" "$joined"
}

# need_collector: stops the check when the Collector Deployment never becomes available.
need_collector() {
  if ! kubectl -n "$NS" rollout status deployment/collector --timeout=120s >/dev/null 2>&1; then
    echo "FAIL: the Deployment collector in namespace otel is not available (check the ConfigMap with kubectl -n otel logs deploy/collector)"
    exit 1
  fi
}

# expect_present / expect_absent <description> <text>: fixed-string checks on $block.
expect_present() { printf '%s' "$block" | grep -qF -- "$2" || { echo "FAIL: $1"; fail=1; }; }
expect_absent()  { printf '%s' "$block" | grep -qF -- "$2" && { echo "FAIL: $1"; fail=1; }; }

need_collector

debug_record="$(log_record 5 DEBUG "$RUN-debug-noise")"
info_record="$(log_record 9 INFO "$RUN-info-keep")"
post logs "$(logs_payload "$(attr service.name scout),$(attr host.name "node-$RUN")" "$debug_record" "$info_record")" || { echo "FAIL: the Collector did not accept the test data"; exit 1; }
first="$(datapoint "$(attr route "/orders-$RUN"),$(attr user.id "u1-$RUN")" 5)"
second="$(datapoint "$(attr route "/orders-$RUN"),$(attr user.id "u2-$RUN")" 7)"
post metrics "$(metrics_payload "$(attr service.name scout),$(attr host.name "node-$RUN")" shuttle.requests "$first" "$second")" || { echo "FAIL: the Collector did not accept the test data"; exit 1; }
noise="$(datapoint "$(attr route "/debug-$RUN")" 3)"
post metrics "$(metrics_payload "$(attr service.name scout),$(attr host.name "node-$RUN")" scout.debug.counter "$noise")" || { echo "FAIL: the Collector did not accept the test data"; exit 1; }
wait_for "$RUN-info-keep" || { echo "FAIL: the test data never reached the debug exporter (a processor dropped it, or the Collector is broken)"; exit 1; }
wait_for "/orders-$RUN" || { echo "FAIL: the test data never reached the debug exporter (a processor dropped it, or the Collector is broken)"; exit 1; }
sleep 3
block="$(collector_logs | resource_block "/orders-$RUN")"
expect_absent "the data point attribute user.id is still there (u1-$RUN)" "u1-$RUN"
expect_absent "the data point attribute user.id is still there (u2-$RUN)" "u2-$RUN"
expect_present "the data point attribute route was lost" "route: Str(/orders-$RUN)"
if collector_logs | grep -qF -- "$RUN-debug-noise"; then echo "FAIL: the DEBUG log record reached the exporter"; fail=1; fi
if collector_logs | grep -qF -- "/debug-$RUN"; then echo "FAIL: the metric scout.debug.counter reached the exporter"; fail=1; fi
[ "$fail" -eq 0 ] && echo "PASS: DEBUG logs and the debug counter are dropped, user.id is removed from data points"
exit "$fail"
