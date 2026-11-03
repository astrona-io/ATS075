#!/usr/bin/env bash
# Check: the receiver otlp still accepts traces on port 4318 after the merge.
set -uo pipefail

AGENT="otelcol.starfleet.svc.cluster.local"

# Build an OTLP/HTTP JSON request body for one signal. The marker is the span
# name, the metric name or the log body, so the check can find it later.
payload() {
  local signal="$1" marker="$2"
  local resource='{"attributes":[{"key":"service.name","value":{"stringValue":"scout"}}]}'
  case "$signal" in
    traces)
      printf '{"resourceSpans":[{"resource":%s,"scopeSpans":[{"scope":{"name":"lab"},"spans":[{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"eee19b7ec3c1b174","name":"%s","kind":1,"startTimeUnixNano":"1700000000000000000","endTimeUnixNano":"1700000001000000000"}]}]}]}' "$resource" "$marker" ;;
    metrics)
      printf '{"resourceMetrics":[{"resource":%s,"scopeMetrics":[{"scope":{"name":"lab"},"metrics":[{"name":"%s","gauge":{"dataPoints":[{"asDouble":0.5,"timeUnixNano":"1700000000000000000"}]}}]}]}]}' "$resource" "$marker" ;;
    logs)
      printf '{"resourceLogs":[{"resource":%s,"scopeLogs":[{"scope":{"name":"lab"},"logRecords":[{"timeUnixNano":"1700000000000000000","severityText":"INFO","body":{"stringValue":"%s"}}]}]}]}' "$resource" "$marker" ;;
  esac
}

# Send one request from the shuttle pod and print the HTTP status code
# (000 when the connection fails).
send_request() {
  local signal="$1" marker="$2" port="$3"
  payload "$signal" "$marker" | kubectl -n starfleet exec -i deploy/shuttle -- \
    curl -s -o /dev/null -w '%{http_code}' --max-time 5 -X POST \
    -H 'Content-Type: application/json' -d @- \
    "http://${AGENT}:${port}/v1/${signal}" 2>/dev/null || true
}

# Send a request with a new marker until the gateway logs show the marker.
# Retries cover a rollout that is still running. Sets MARKER and LAST_CODE.
deliver_to_gateway() {
  local signal="$1" port="$2" attempt wait
  MARKER="lab-${signal}-$(date +%s)-${RANDOM}"
  LAST_CODE=""
  for attempt in 1 2 3 4 5 6 7 8; do
    LAST_CODE="$(send_request "$signal" "$MARKER" "$port")"
    for wait in 1 2 3 4; do
      sleep 1
      if kubectl -n outpost logs deploy/gateway --tail=-1 2>/dev/null | grep -qF "$MARKER"; then
        return 0
      fi
    done
  done
  return 1
}

# Check one signal end to end and print PASS or FAIL.
check_signal() {
  local signal="$1" port="$2"
  if deliver_to_gateway "$signal" "$port"; then
    echo "PASS: a $signal request sent to port $port of the agent reached the gateway"
    return 0
  fi
  echo "FAIL: a $signal request sent to port $port of the agent did not reach the gateway (last HTTP status: ${LAST_CODE:-none})"
  return 1
}

# Print the Deployment image and available replicas problems.
check_agent_ready() {
  local ready image
  ready="$(kubectl -n starfleet get deployment otelcol -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
  image="$(kubectl -n starfleet get deployment otelcol -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
  if [ -z "$ready" ] || [ "$ready" -lt 1 ]; then
    echo "FAIL: deployment otelcol in starfleet has no available replica (read the pod log with kubectl logs)"
    return 1
  fi
  if [ "$image" != "otel/opentelemetry-collector-contrib:0.162.0" ]; then
    echo "FAIL: deployment otelcol runs image '$image', expected the original contrib image"
    return 1
  fi
  echo "PASS: deployment otelcol is available with the original image"
  return 0
}

# All text of the agent ConfigMap, every key.
configmap_text() {
  kubectl -n starfleet get configmap otelcol-config -o json 2>/dev/null | jq -r '.data // {} | to_entries[] | .value'
}

# Check that the span attribute deployment.environment on the gateway has the
# value outpost-test, read next to the marker of a new request.
check_environment_value() {
  local marker logs value
  if ! deliver_to_gateway traces 4318; then
    echo "FAIL: a traces request did not reach the gateway (last HTTP status: ${LAST_CODE:-none})"
    return 1
  fi
  marker="$MARKER"
  logs="$(kubectl -n outpost logs deploy/gateway --tail=-1 2>/dev/null)"
  value="$(printf '%s\n' "$logs" | awk -v m="$marker" '/ResourceSpans #/ {env=""} /deployment.environment: Str\(/ {env=$0} index($0, m) {print env; exit}')"
  if printf '%s' "$value" | grep -qF 'Str(outpost-test)'; then
    echo "PASS: the span carries deployment.environment = outpost-test"
    return 0
  fi
  echo "FAIL: the span on the gateway has deployment.environment line '${value:-none}', expected Str(outpost-test)"
  return 1
}

# Static check: the value comes from the variable, not from a literal.
check_environment_wiring() {
  local text
  text="$(configmap_text)"
  if ! printf '%s' "$text" | grep -qF '${env:DEPLOY_ENV}'; then
    echo 'FAIL: the configuration does not use ${env:DEPLOY_ENV} for the environment value'
    return 1
  fi
  if printf '%s' "$text" | grep -qF 'outpost-test'; then
    echo "FAIL: the value outpost-test is written into the configuration as a literal"
    return 1
  fi
  return 0
}

check_secret_from_env() {
  local text ref
  text="$(configmap_text)"
  if printf '%s' "$text" | grep -qF 's3cr3t-lab-token'; then
    echo "FAIL: the token is still written in the ConfigMap"
    return 1
  fi
  if ! printf '%s' "$text" | grep -qF '${env:BACKEND_TOKEN}'; then
    echo 'FAIL: the configuration does not read the token with ${env:BACKEND_TOKEN}'
    return 1
  fi
  ref="$(kubectl -n starfleet get deployment otelcol -o json 2>/dev/null | jq -r '[.spec.template.spec.containers[0].env[]? | select(.name=="BACKEND_TOKEN") | .valueFrom.secretKeyRef.name] | first // ""')"
  if [ "$ref" != "gateway-token" ]; then
    echo "FAIL: BACKEND_TOKEN no longer comes from the Secret gateway-token"
    return 1
  fi
  echo "PASS: the token is read from the Secret through BACKEND_TOKEN and is not in the ConfigMap"
  return 0
}

check_health() {
  local code attempt
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    code="$(kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}' --max-time 3 "http://${AGENT}:13133/" 2>/dev/null || true)"
    if [ "$code" = "200" ]; then
      echo "PASS: the health_check extension answers HTTP 200 on port 13133"
      return 0
    fi
    sleep 2
  done
  echo "FAIL: port 13133 of the agent did not answer HTTP 200 (last status: ${code:-none}); is health_check listed under service extensions?"
  return 1
}

fail=0
check_signal traces 4318 || fail=1
exit "$fail"
