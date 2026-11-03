#!/usr/bin/env bash
# Check: the running gateway reports an exporter queue capacity of at least 5000 (otelcol_exporter_queue_capacity), so the setting is live and not only saved.
set -u
fail() { echo "FAIL: $*"; exit 1; }

gateway_metrics() {
  kubectl -n outpost exec deploy/drifter -- curl -s --max-time 5 http://gateway.starfleet.svc.cluster.local:8888/metrics 2>/dev/null
}

capacity=""
for _ in $(seq 1 20); do
  capacity=$(gateway_metrics | awk '/^otelcol_exporter_queue_capacity/ { if ($NF + 0 > max) max = $NF + 0 } END { print max + 0 }')
  [ "${capacity:-0}" -ge 5000 ] && break
  sleep 3
done

[ "${capacity:-0}" -gt 0 ] || fail "no exporter queue capacity is reported (the metrics endpoint is not reachable yet)"
[ "$capacity" -ge 5000 ] || fail "the largest exporter queue capacity is $capacity, expected at least 5000 (raise sending_queue.queue_size and restart the gateway)"
echo "PASS: the exporter sending queue has a capacity of $capacity"
