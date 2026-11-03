#!/usr/bin/env bash
# Check: a span that the shuttle pod sends to the agent leaves the debug
# exporter with the Kubernetes attributes of the sender: namespace, pod name,
# node name and Deployment name.
set -uo pipefail

if ! kubectl -n starfleet rollout status daemonset/otel-agent --timeout=120s >/dev/null 2>&1; then
  echo "FAIL: the otel-agent DaemonSet is not rolled out"
  exit 1
fi

name="lab-$(date +%s)-$RANDOM"
payload='{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"'"$name"'"}}]},"scopeSpans":[{"scope":{"name":"validation"},"spans":[{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"eee19b7ec3c1b174","name":"validate","kind":2,"startTimeUnixNano":"1700000000000000000","endTimeUnixNano":"1700000001000000000"}]}]}]}'

code="$(kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}' --max-time 5 \
  -X POST -H 'Content-Type: application/json' -d "$payload" \
  http://otel-agent.starfleet.svc:4318/v1/traces 2>/dev/null || true)"
if [ "$code" != "200" ]; then
  echo "FAIL: the agent did not accept the span (HTTP status ${code:-none})"
  exit 1
fi

block=""
for _ in $(seq 1 15); do
  block="$(kubectl -n starfleet logs -l app=otel-agent --tail=3000 2>/dev/null | grep -B25 -A25 "service.name: Str($name)" || true)"
  [ -n "$block" ] && break
  sleep 1
done
if [ -z "$block" ]; then
  echo "FAIL: the span did not reach the debug exporter of the agent"
  exit 1
fi

fail=0
for key in "k8s.namespace.name: Str(starfleet)" "k8s.pod.name: Str(shuttle-" "k8s.node.name: Str(" "k8s.deployment.name: Str(shuttle)"; do
  if ! echo "$block" | grep -q -F "$key"; then
    echo "FAIL: the span has no attribute '$key'"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: the span carries the Kubernetes attributes of the shuttle pod"
fi
exit "$fail"
