#!/usr/bin/env bash
# Check: each of the three scrape targets is scraped by exactly one scraper pod. Without sharding, both pods scrape every target and every series is duplicated.
set -u
fail() { echo "FAIL: $*"; exit 1; }

TARGETS="gateway.starfleet.svc.cluster.local:8888 sampler.starfleet.svc.cluster.local:8888 scraper.starfleet.svc.cluster.local:8888"

pods=$(kubectl -n starfleet get pods -l app=scraper -o jsonpath='{.items[*].metadata.name}')
count=$(printf '%s\n' $pods | grep -c .)
[ "$count" -ge 2 ] || fail "expected at least 2 scraper pods, found $count (do not scale the scraper down to remove the duplicates)"

# Let the scraper pods finish at least two scrape intervals (15s) after a restart.
sleep 35

logs_dir=$(mktemp -d)
trap 'rm -rf "$logs_dir"' EXIT
for pod in $pods; do
  kubectl -n starfleet logs "$pod" --since=40s > "$logs_dir/$pod.log" 2>/dev/null
done

bad=0
for target in $TARGETS; do
  holders=0
  for log in "$logs_dir"/*.log; do
    if grep -F 'service.instance.id' "$log" | grep -qF "$target"; then
      holders=$((holders + 1))
    fi
  done
  if [ "$holders" -eq 0 ]; then
    echo "target $target is not scraped by any pod"
    bad=1
  elif [ "$holders" -gt 1 ]; then
    echo "target $target is scraped by $holders pods (duplicates)"
    bad=1
  fi
done

[ "$bad" -eq 0 ] || fail "the scrape targets are not split over the scraper pods exactly once (restart the StatefulSet after you change the ConfigMap)"
echo "PASS: every target is scraped by exactly one scraper pod"
