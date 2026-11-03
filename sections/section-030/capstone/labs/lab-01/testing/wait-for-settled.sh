#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until both
# sampler pods are listed by the headless Service, then lets the scraper pods
# complete a few scrape intervals.
set -u

for _ in $(seq 1 60); do
  ready=$(kubectl -n starfleet get endpoints sampler-headless -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w | tr -d ' ')
  if [ "$ready" -ge 2 ]; then
    break
  fi
  sleep 3
done
sleep 45
echo "[testing] Settled."
