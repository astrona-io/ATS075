#!/usr/bin/env bash
# Check: the agent adds deployment.environment.name=lab from the environment of
# its own pod (env detector), and keeps the service.name that the sender set.
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

if echo "$block" | grep -q -F "deployment.environment.name: Str(lab)"; then
  echo "PASS: the span carries deployment.environment.name=lab and the sender's service.name"
  exit 0
fi
echo "FAIL: the span has no deployment.environment.name=lab (use the env detector and OTEL_RESOURCE_ATTRIBUTES)"
exit 1
