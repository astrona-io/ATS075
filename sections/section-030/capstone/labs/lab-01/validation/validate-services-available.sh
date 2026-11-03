#!/usr/bin/env bash
# Check: the gateway, both sampler pods and both scraper pods are available after the changes.
set -u
fail() { echo "FAIL: $*"; exit 1; }

ready_of() {
  kubectl -n starfleet get "$1" "$2" -o jsonpath="{.status.$3}" 2>/dev/null
}

gateway=$(ready_of deployment gateway availableReplicas)
sampler=$(ready_of deployment sampler availableReplicas)
scraper=$(ready_of statefulset scraper readyReplicas)

[ "${gateway:-0}" -ge 1 ] || fail "the gateway Deployment has no available replica"
[ "${sampler:-0}" -ge 2 ] || fail "the sampler Deployment must keep 2 available replicas, found ${sampler:-0}"
[ "${scraper:-0}" -ge 2 ] || fail "the scraper StatefulSet must keep 2 ready replicas, found ${scraper:-0}"
echo "PASS: gateway, samplers and scrapers are available"
