#!/usr/bin/env bash
# Check: the traces pipeline starts with memory_limiter and has batch, memory_limiter sets a limit below the container memory limit, and the container has a limit.
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

list=$(traces_processors)
[ -n "$list" ] || fail "the traces pipeline has no flow-style processors list such as processors: [memory_limiter, batch]"
first="${list%%,*}"
[ "$first" = "memory_limiter" ] || fail "the first processor of the traces pipeline is '$first', it must be memory_limiter"
case ",$list," in
  *,batch,*) ;;
  *) fail "the traces pipeline has no batch processor (processors: [$list])" ;;
esac

limit_line=$(gateway_config_text | grep -E '^[[:space:]]*limit_mib:' | head -1 | awk '{print $2}')
percent_line=$(gateway_config_text | grep -E '^[[:space:]]*limit_percentage:' | head -1)
[ -n "$limit_line" ] || [ -n "$percent_line" ] || fail "memory_limiter sets neither limit_mib nor limit_percentage"

memory=$(memory_limit_mib)
[ -n "$memory" ] || fail "the gateway container has no memory limit in Mi or Gi (set resources.limits.memory)"
if [ -n "$limit_line" ] && [ "$limit_line" -ge "$memory" ]; then
  fail "limit_mib ($limit_line) must be lower than the container memory limit (${memory}Mi), or the kernel kills the container before the limiter acts"
fi
echo "PASS: memory_limiter is first, batch follows, and the container limit is ${memory}Mi"
