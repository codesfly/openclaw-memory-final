#!/usr/bin/env bash
set -euo pipefail

CMD_TIMEOUT_SEC="${OPENCLAW_CMD_TIMEOUT_SEC:-25}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --command-timeout)
      CMD_TIMEOUT_SEC="$2"; shift 2 ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1 ;;
  esac
done

if ! command -v openclaw >/dev/null 2>&1; then
  echo "openclaw CLI not found" >&2
  exit 1
fi

run_oc() {
  timeout "${CMD_TIMEOUT_SEC}s" openclaw "$@"
}

get_ids() {
  local name="$1"
  local json
  json="$(run_oc cron list --json 2>/dev/null || echo '{"jobs":[]}')"
  LIST_JOBS_JSON="$json" python3 - "$name" <<'PY'
import json, os, sys
name=sys.argv[1]
raw=os.environ.get("LIST_JOBS_JSON", "").strip() or '{"jobs":[]}'
try:
    data=json.loads(raw)
except Exception:
    data={"jobs":[]}
for j in data.get("jobs",[]):
    if j.get("name")==name and j.get("id"):
        print(j["id"])
PY
}

for name in memory-sync-daily memory-weekly-tidy memory-cron-watchdog; do
  ids="$(get_ids "$name" || true)"
  for id in $ids; do
    run_oc cron remove "$id" >/dev/null 2>&1 || true
    echo "removed $name ($id)"
  done
done

echo "✅ memory cron jobs removed"
