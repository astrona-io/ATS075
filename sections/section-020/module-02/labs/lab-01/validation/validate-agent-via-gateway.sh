#!/usr/bin/env bash
# Check: the agent configuration exports to the gateway and no longer to the
# backend, and a span that shuttle posts to the agent reaches the backend.
set -uo pipefail

if ! kubectl -n starfleet rollout status daemonset/otel-agent --timeout=120s >/dev/null 2>&1; then
  echo "FAIL: the otel-agent DaemonSet is not rolled out"
  exit 1
fi

agent_config="$(kubectl -n starfleet get configmap otel-agent-config -o jsonpath='{.data.config\.yaml}' 2>/dev/null || true)"
if ! echo "$agent_config" | grep -q 'otel-gateway'; then
  echo "FAIL: the agent configuration does not export to otel-gateway"
  exit 1
fi
if echo "$agent_config" | grep -q 'otel-backend'; then
  echo "FAIL: the agent configuration still mentions otel-backend"
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

for _ in $(seq 1 25); do
  if kubectl -n starfleet logs deploy/otel-backend --tail=3000 2>/dev/null | grep -q -F "service.name: Str($name)"; then
    echo "PASS: the span reached the backend through the gateway"
    exit 0
  fi
  sleep 1
done
echo "FAIL: the span did not reach the backend within 25 seconds"
exit 1
