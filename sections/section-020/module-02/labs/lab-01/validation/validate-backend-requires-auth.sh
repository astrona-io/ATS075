#!/usr/bin/env bash
# Check: the backend still refuses a request without credentials, and still
# accepts one with the right user name and password. This check passes on the
# starting state and fails if a fix weakens or breaks the backend.
set -uo pipefail

if ! kubectl -n starfleet rollout status deployment/otel-backend --timeout=120s >/dev/null 2>&1; then
  echo "FAIL: the otel-backend Deployment is not available"
  exit 1
fi

payload='{"resourceSpans":[]}'
url="http://otel-backend.starfleet.svc:4318/v1/traces"

anonymous="$(kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}' --max-time 5 \
  -X POST -H 'Content-Type: application/json' -d "$payload" "$url" 2>/dev/null || true)"
if [ "$anonymous" != "401" ]; then
  echo "FAIL: the backend answered ${anonymous:-nothing} to a request without credentials, expected 401"
  exit 1
fi

password="$(kubectl -n starfleet get secret backend-credentials -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || true)"
authenticated="$(kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}' --max-time 5 \
  -u "gateway:$password" -X POST -H 'Content-Type: application/json' -d "$payload" "$url" 2>/dev/null || true)"
if [ "$authenticated" != "200" ]; then
  echo "FAIL: the backend answered ${authenticated:-nothing} to a request with the right credentials, expected 200"
  exit 1
fi

echo "PASS: the backend refuses anonymous requests and accepts the gateway credentials"
exit 0
