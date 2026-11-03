#!/usr/bin/env bash
# Check: the agent runs on every node, and its service account can read pods
# and namespaces in all namespaces but nothing more than that.
set -uo pipefail

fail=0
sa="system:serviceaccount:starfleet:otel-agent"

if ! kubectl -n starfleet rollout status daemonset/otel-agent --timeout=120s >/dev/null 2>&1; then
  echo "FAIL: the otel-agent DaemonSet is not rolled out"
  exit 1
fi

desired="$(kubectl -n starfleet get ds otel-agent -o jsonpath='{.status.desiredNumberScheduled}')"
ready="$(kubectl -n starfleet get ds otel-agent -o jsonpath='{.status.numberReady}')"
if [ -z "$desired" ] || [ "$desired" -lt 1 ] || [ "$desired" != "$ready" ]; then
  echo "FAIL: the agent is ready on $ready of $desired nodes"
  fail=1
fi

# can_do <expected yes|no> <verb> <resource> [extra flags]
can_do() {
  local expected="$1" verb="$2" resource="$3"
  local answer
  answer="$(kubectl auth can-i "$verb" "$resource" --all-namespaces --as="$sa" 2>/dev/null || true)"
  if [ "$answer" != "$expected" ]; then
    echo "FAIL: can $sa $verb $resource in all namespaces? expected $expected, got ${answer:-nothing}"
    fail=1
  fi
}

can_do yes list pods
can_do yes watch pods
can_do yes list namespaces
can_do no get secrets
can_do no delete pods
can_do no create deployments.apps

if [ "$fail" -eq 0 ]; then
  echo "PASS: the agent is ready on every node and has read-only access to pods and namespaces"
fi
exit "$fail"
