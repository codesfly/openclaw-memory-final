#!/usr/bin/env bash
set -euo pipefail

TZ_VALUE="${TZ:-Asia/Shanghai}"
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tz)
      TZ_VALUE="$2"; shift 2 ;;
    --workspace)
      WORKSPACE="$2"; shift 2 ;;
    *)
      echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if ! command -v openclaw >/dev/null 2>&1; then
  echo "openclaw CLI not found" >&2
  exit 1
fi

mkdir -p "$WORKSPACE/memory/weekly" "$WORKSPACE/memory/archive/$(date +%Y)" "$WORKSPACE/memory/state"

if [[ ! -f "$WORKSPACE/memory/state/processed-sessions.json" ]]; then
  cp examples/memory/state/processed-sessions.json "$WORKSPACE/memory/state/processed-sessions.json"
fi
if [[ ! -f "$WORKSPACE/memory/state/memory-watchdog-state.json" ]]; then
  cp examples/memory/state/memory-watchdog-state.json "$WORKSPACE/memory/state/memory-watchdog-state.json"
fi

# Remove old jobs if same names exist (idempotent install)
for name in memory-sync-daily memory-weekly-tidy memory-cron-watchdog; do
  if openclaw cron list --json 2>/dev/null | grep -q "\"name\":\"$name\"\|\"name\": \"$name\""; then
    id=$(openclaw cron list --json | sed 's/[{}]/\n/g' | grep -E '"id"|"name"' | awk -v n="$name" '
      /"id"/ {gsub(/[",]/,"",$2); id=$2}
      /"name"/ {if(index($0,n)>0) print id}
    ' | tail -1)
    [[ -n "$id" ]] && openclaw cron remove "$id" >/dev/null 2>&1 || true
  fi
done

openclaw cron add \
  --name "memory-sync-daily" \
  --cron "0 23 * * *" \
  --tz "$TZ_VALUE" \
  --session isolated \
  --agent main \
  --timeout-seconds 300 \
  --no-deliver \
  --message 'MEMORY DAILY SYNC — 你是每日记忆蒸馏 agent。读取最近26小时会话，跳过<2条用户消息和isolated噪音会话。使用最后用户消息timestamp+文本前120字符作为fingerprint；若与memory/state/processed-sessions.json中lastFingerprint一致则跳过。仅将新增会话摘要追加到memory/YYYY-MM-DD.md（3-8条要点）。更新state后执行 QMD_GPU=cpu /path/to/qmd update。完成回复ANNOUNCE_SKIP。'

openclaw cron add \
  --name "memory-weekly-tidy" \
  --cron "0 22 * * 0" \
  --tz "$TZ_VALUE" \
  --session isolated \
  --agent main \
  --timeout-seconds 600 \
  --no-deliver \
  --message 'MEMORY WEEKLY TIDY — 你是每周记忆巩固 agent。聚合近7天daily日志，精炼MEMORY.md（<=80行/5KB），生成memory/weekly/YYYY-MM-DD.md并归档覆盖的旧daily。执行 QMD_GPU=cpu /path/to/qmd update && QMD_GPU=cpu /path/to/qmd embed。无变更回复ANNOUNCE_SKIP。'

openclaw cron add \
  --name "memory-cron-watchdog" \
  --cron "15 */2 * * *" \
  --tz "$TZ_VALUE" \
  --session isolated \
  --agent main \
  --timeout-seconds 180 \
  --no-deliver \
  --message '你是memory watchdog。检查memory-sync-daily与memory-weekly-tidy是否enabled、lastStatus非error/failed、且未stale。维护memory/state/memory-watchdog-state.json中的consecutiveAnomalies和last3快照。仅连续2次异常才告警到ops群；首轮异常只计数不告警。完成回复ANNOUNCE_SKIP。'

echo "✅ Installed memory architecture jobs"
openclaw cron list
