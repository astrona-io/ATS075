#!/usr/bin/env bash
# Check: the gateway Collector exposes its self-telemetry on port 8888 and the Service reaches it. The client in outpost reads /metrics through the gateway Service.
set -u
fail() { echo "FAIL: $*"; exit 1; }

gateway_metrics() {
  kubectl -n outpost exec deploy/drifter -- curl -s --max-time 5 http://gateway.starfleet.svc.cluster.local:8888/metrics 2>/dev/null
}

text=""
for _ in $(seq 1 20); do
  text=$(gateway_metrics)
  printf '%s' "$text" | grep -q '^otelcol_exporter_queue_capacity' && break
  sleep 3
done

[ -n "$text" ] || fail "the gateway Service did not answer on port 8888 (is the Collector metrics endpoint bound to 0.0.0.0?)"
printf '%s' "$text" | grep -q '^otelcol_exporter_queue_capacity' || fail "port 8888 answers but has no otelcol_exporter_queue_capacity metric"
printf '%s' "$text" | grep -q '^otelcol_exporter_queue_size' || fail "no otelcol_exporter_queue_size metric on port 8888"
echo "PASS: the gateway exposes its own metrics on port 8888 through the Service"
