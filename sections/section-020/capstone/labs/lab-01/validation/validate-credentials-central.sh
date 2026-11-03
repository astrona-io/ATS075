#!/usr/bin/env bash
# Check: the backend password exists only in the Secret and in the gateway.
# The agent ConfigMap and the agent DaemonSet do not contain it, the gateway
# ConfigMap does not contain it as a literal, and the gateway reads it from the
# Secret backend-credentials.
set -uo pipefail

fail=0
password="$(kubectl -n starfleet get secret backend-credentials -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || true)"
if [ -z "$password" ]; then
  echo "FAIL: the Secret backend-credentials with the key password is missing (do not delete it)"
  exit 1
fi

if ! kubectl -n starfleet get deployment otel-gateway >/dev/null 2>&1; then
  echo "FAIL: there is no Deployment otel-gateway in starfleet"
  exit 1
fi

agent_cm="$(kubectl -n starfleet get configmap otel-agent-config -o json 2>/dev/null)"
agent_ds="$(kubectl -n starfleet get daemonset otel-agent -o json 2>/dev/null)"
gateway_cm="$(kubectl -n starfleet get configmap otel-gateway-config -o json 2>/dev/null || true)"
gateway_deploy="$(kubectl -n starfleet get deployment otel-gateway -o json)"

if echo "$agent_cm" | grep -q -F "$password"; then
  echo "FAIL: the agent ConfigMap still contains the backend password"
  fail=1
fi
if echo "$agent_ds" | grep -q -F "$password"; then
  echo "FAIL: the agent DaemonSet contains the backend password"
  fail=1
fi
if echo "$agent_ds" | grep -q 'backend-credentials'; then
  echo "FAIL: the agent DaemonSet reads the Secret backend-credentials; only the gateway may"
  fail=1
fi
if [ -n "$gateway_cm" ] && echo "$gateway_cm" | grep -q -F "$password"; then
  echo "FAIL: the gateway ConfigMap contains the password as a literal; read it from the Secret with an environment variable"
  fail=1
fi
if echo "$gateway_deploy" | grep -q -F "$password"; then
  echo "FAIL: the gateway Deployment contains the password as a literal value"
  fail=1
fi
if ! echo "$gateway_deploy" | jq -e '[.spec.template.spec.containers[].env[]? | select(.valueFrom.secretKeyRef.name == "backend-credentials")] | length > 0' >/dev/null 2>&1; then
  echo "FAIL: the gateway container does not take an environment variable from the Secret backend-credentials"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: only the gateway reads the backend password, and it reads it from the Secret"
fi
exit "$fail"
