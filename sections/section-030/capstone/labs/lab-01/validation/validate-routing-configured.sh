#!/usr/bin/env bash
# Check: the gateway pipeline sends traces to a load_balancing exporter that routes by traceID with a resolver, and the gateway is available.
set -u
fail() { echo "FAIL: $*"; exit 1; }

gateway_config_text() {
  kubectl -n starfleet get configmap gateway-config -o jsonpath='{.data.config\.yaml}' 2>/dev/null
}

# traces_processors prints the flow-style processors list of the pipeline,
# without spaces, for example "memory_limiter,batch".
traces_processors() {
  gateway_config_text | tr -d ' \n' | grep -o 'processors:\[[^]]*\]' | tail -1 | sed 's/processors:\[//; s/\]//'
}

# memory_limit_mib prints the memory limit of the gateway container in MiB.
memory_limit_mib() {
  local raw
  raw=$(kubectl -n starfleet get deployment gateway -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null)
  case "$raw" in
    *Mi) echo "${raw%Mi}" ;;
    *Gi) echo $(( ${raw%Gi} * 1024 )) ;;
    *) echo "" ;;
  esac
}

config_text=$(gateway_config_text)
[ -n "$config_text" ] || fail "the ConfigMap gateway-config has no config.yaml key"
printf '%s' "$config_text" | grep -qE '^[[:space:]]+load_balancing(/[A-Za-z0-9_-]+)?:' || fail "the gateway configuration has no load_balancing exporter"

exporters=$(printf '%s' "$config_text" | tr -d ' \n' | grep -o 'exporters:\[[^]]*\]' | tail -1)
case "$exporters" in
  *load_balancing*) ;;
  *) fail "the traces pipeline does not send to the load_balancing exporter (found: ${exporters:-nothing})" ;;
esac

routing=$(printf '%s' "$config_text" | grep -E '^[[:space:]]*routing_key:' | head -1 | awk '{print $2}' | tr -d '"')
if [ -n "$routing" ] && [ "$routing" != "traceID" ]; then
  fail "routing_key is '$routing', spans of one trace must be routed by traceID"
fi

printf '%s' "$config_text" | grep -qE '^[[:space:]]+(dns|k8s|static):' || fail "the load_balancing exporter has no resolver (dns, k8s or static)"

ready=$(kubectl -n starfleet get deployment gateway -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
[ "${ready:-0}" -ge 1 ] || fail "the gateway Deployment has no available replica (check the Collector log for configuration errors)"
echo "PASS: the gateway routes traces with load_balancing by traceID"
