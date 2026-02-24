#!/usr/bin/env bash
set -euo pipefail

if ! command -v openclaw >/dev/null 2>&1; then
  echo "openclaw CLI not found" >&2
  exit 1
fi

for name in memory-sync-daily memory-weekly-tidy memory-cron-watchdog; do
  ids=$(openclaw cron list --json 2>/dev/null | sed 's/[{}]/\n/g' | grep -E '"id"|"name"' | awk -v n="$name" '
    /"id"/ {gsub(/[",]/,"",$2); id=$2}
    /"name"/ {if(index($0,n)>0) print id}
  ')
  for id in $ids; do
    openclaw cron remove "$id" >/dev/null 2>&1 || true
    echo "removed $name ($id)"
  done
done

echo "✅ memory cron jobs removed"
