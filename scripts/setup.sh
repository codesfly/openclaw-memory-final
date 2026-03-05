#!/usr/bin/env bash
set -euo pipefail

TZ_VALUE="${TZ:-Asia/Shanghai}"
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
QMD_PATH="${QMD_PATH:-}"
OPS_CHANNEL="${OPS_CHANNEL:-telegram}"
OPS_ACCOUNT="${OPS_ACCOUNT:-ops}"
OPS_TARGET="${OPS_TARGET:-}"
FORCE_RECREATE=0
CMD_TIMEOUT_SEC="${OPENCLAW_CMD_TIMEOUT_SEC:-25}"
SKIP_HEALTHCHECK=0
PRINT_JSON=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tz)
      TZ_VALUE="$2"; shift 2 ;;
    --workspace)
      WORKSPACE="$2"; shift 2 ;;
    --qmd-path)
      QMD_PATH="$2"; shift 2 ;;
    --ops-channel)
      OPS_CHANNEL="$2"; shift 2 ;;
    --ops-account)
      OPS_ACCOUNT="$2"; shift 2 ;;
    --ops-target)
      OPS_TARGET="$2"; shift 2 ;;
    --force-recreate)
      FORCE_RECREATE=1; shift ;;
    --command-timeout)
      CMD_TIMEOUT_SEC="$2"; shift 2 ;;
    --skip-healthcheck)
      SKIP_HEALTHCHECK=1; shift ;;
    --print-json)
      PRINT_JSON=1; shift ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1 ;;
  esac
done

if ! command -v openclaw >/dev/null 2>&1; then
  echo "openclaw CLI not found" >&2
  exit 1
fi

if ! command -v timeout >/dev/null 2>&1; then
  echo "coreutils timeout not found" >&2
  exit 1
fi

run_oc() {
  timeout "${CMD_TIMEOUT_SEC}s" openclaw "$@"
}

if [[ "$SKIP_HEALTHCHECK" -eq 0 ]]; then
  if ! run_oc status >/dev/null 2>&1; then
    echo "gateway precheck failed: openclaw status timeout/error" >&2
    echo "hint: restart gateway first, then re-run setup." >&2
    exit 1
  fi
fi

if [[ -z "$QMD_PATH" ]]; then
  if command -v qmd >/dev/null 2>&1; then
    QMD_PATH="$(command -v qmd)"
  else
    echo "qmd not found. Pass --qmd-path /absolute/path/to/qmd" >&2
    exit 1
  fi
fi

if [[ ! -x "$QMD_PATH" ]]; then
  echo "qmd path is not executable: $QMD_PATH" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p \
  "$WORKSPACE/memory/weekly" \
  "$WORKSPACE/memory/archive/$(date +%Y)" \
  "$WORKSPACE/memory/state" \
  "$WORKSPACE/memory/tasks" \
  "$WORKSPACE/scripts"

# Baseline/state files
if [[ ! -f "$WORKSPACE/memory/state/processed-sessions.json" ]]; then
  cp "$REPO_ROOT/examples/memory/state/processed-sessions.json" "$WORKSPACE/memory/state/processed-sessions.json"
fi
if [[ ! -f "$WORKSPACE/memory/state/memory-watchdog-state.json" ]]; then
  cp "$REPO_ROOT/examples/memory/state/memory-watchdog-state.json" "$WORKSPACE/memory/state/memory-watchdog-state.json"
fi
if [[ ! -f "$WORKSPACE/memory/CURRENT_STATE.md" ]]; then
  cp "$REPO_ROOT/examples/CURRENT_STATE.md.template" "$WORKSPACE/memory/CURRENT_STATE.md"
fi
if [[ ! -f "$WORKSPACE/memory/INDEX.md" ]]; then
  cp "$REPO_ROOT/examples/memory-INDEX.md.template" "$WORKSPACE/memory/INDEX.md"
fi
if [[ ! -f "$WORKSPACE/memory/context-profiles.json" ]]; then
  cp "$REPO_ROOT/examples/memory/context-profiles.json" "$WORKSPACE/memory/context-profiles.json"
fi

# Helper scripts
for f in mem-log.sh memory-reflect.sh \
  memory_context_budget_guard.py memory_context_pack.py memory_conflict_check.py memory_retrieval_watchdog.py; do
  if [[ ! -f "$WORKSPACE/scripts/$f" ]]; then
    cp "$REPO_ROOT/scripts/$f" "$WORKSPACE/scripts/$f"
  fi
done
chmod +x \
  "$WORKSPACE/scripts/mem-log.sh" \
  "$WORKSPACE/scripts/memory-reflect.sh" \
  "$WORKSPACE/scripts/memory_context_budget_guard.py" \
  "$WORKSPACE/scripts/memory_context_pack.py" \
  "$WORKSPACE/scripts/memory_conflict_check.py" \
  "$WORKSPACE/scripts/memory_retrieval_watchdog.py"

list_jobs_json() {
  run_oc cron list --json 2>/dev/null || echo '{"jobs":[]}'
}

get_job_ids_by_name() {
  local name="$1"
  local json
  json="$(list_jobs_json)"
  LIST_JOBS_JSON="$json" python3 - "$name" <<'PY'
import json, os, sys
name = sys.argv[1]
raw = os.environ.get("LIST_JOBS_JSON", "").strip() or '{"jobs":[]}'
try:
    data = json.loads(raw)
except Exception:
    data = {"jobs": []}
for job in data.get("jobs", []):
    if job.get("name") == name and job.get("id"):
        print(job["id"])
PY
}

remove_jobs_by_name() {
  local name="$1"
  local ids
  ids="$(get_job_ids_by_name "$name" || true)"
  if [[ -n "$ids" ]]; then
    while IFS= read -r id; do
      [[ -z "$id" ]] && continue
      run_oc cron remove "$id" >/dev/null 2>&1 || true
    done <<<"$ids"
  fi
}

job_exists() {
  local name="$1"
  local ids
  ids="$(get_job_ids_by_name "$name" || true)"
  [[ -n "$ids" ]]
}

DAILY_MSG="MEMORY DAILY SYNC — 你是每日记忆蒸馏 agent。读取最近26小时会话，跳过<2条用户消息和isolated噪音会话。使用最后用户消息timestamp+文本前120字符作为fingerprint；若与memory/state/processed-sessions.json中lastFingerprint一致则跳过。仅将新增会话摘要追加到memory/YYYY-MM-DD.md（3-8条要点）。若存在子agent任务，只将结果卡（目标/边界/验收/关键动作/产物路径/最终状态/下一步）写入memory/tasks/YYYY-MM-DD.md，不写全过程日志。更新state后执行 QMD_GPU=cpu $QMD_PATH update。完成回复ANNOUNCE_SKIP。"

WEEKLY_MSG="MEMORY WEEKLY TIDY — 你是每周记忆巩固 agent。聚合近7天daily日志，精炼MEMORY.md（<=80行/5KB），生成memory/weekly/YYYY-MM-DD.md并归档覆盖的旧daily。执行 QMD_GPU=cpu $QMD_PATH update && QMD_GPU=cpu $QMD_PATH embed。无变更回复ANNOUNCE_SKIP。"

if [[ -n "$OPS_TARGET" ]]; then
  WATCHDOG_NOTIFY="若confirmed anomaly，使用message工具发送到 $OPS_CHANNEL（accountId=$OPS_ACCOUNT, target=$OPS_TARGET），并附异常项/连续次数/自愈动作/最近3次快照。"
  RETRIEVAL_NOTIFY="仅当 confirmed=true 时，用message工具发送到 $OPS_CHANNEL（accountId=$OPS_ACCOUNT, target=$OPS_TARGET），并附 anomalies / consecutive_anomalies / pending_embeddings。"
  NIGHTLY_NOTIFY="失败时用message工具发送到 $OPS_CHANNEL（accountId=$OPS_ACCOUNT, target=$OPS_TARGET），包含失败步骤、错误摘要、pending值。"
else
  WATCHDOG_NOTIFY="若confirmed anomaly，记录状态并回复ANNOUNCE_SKIP（未配置外部告警目标）。"
  RETRIEVAL_NOTIFY="仅当 confirmed=true 时记录状态并回复ANNOUNCE_SKIP（未配置外部告警目标）。"
  NIGHTLY_NOTIFY="失败时记录状态并回复ANNOUNCE_SKIP（未配置外部告警目标）。"
fi

WATCHDOG_MSG="你是memory watchdog。检查 memory-sync-daily / memory-weekly-tidy / memory-retrieval-watchdog-v1 / memory-qmd-nightly-maintain 是否 enabled、lastStatus 非 error/failed、且未 stale。维护 memory/state/memory-watchdog-state.json 的 consecutiveAnomalies 与 last3 快照。仅连续2次异常才算 confirmed anomaly；首轮异常只计数不告警。$WATCHDOG_NOTIFY 完成回复ANNOUNCE_SKIP。"

RETRIEVAL_WATCHDOG_MSG="你是 memory retrieval watchdog。执行：python3 $WORKSPACE/scripts/memory_retrieval_watchdog.py --qmd-path $QMD_PATH。读取 $WORKSPACE/memory/state/memory-retrieval-watchdog-state.json。规则：healthy 或 FIRST_ANOMALY（未confirmed）时回复 ANNOUNCE_SKIP；$RETRIEVAL_NOTIFY 发送后回复 ANNOUNCE_SKIP。"

NIGHTLY_MAINTAIN_MSG="你是 memory maintenance agent。每天执行一次 QMD 维护（低噪声）：1) QMD_GPU=cpu $QMD_PATH update；2) QMD_GPU=cpu $QMD_PATH status 并解析 Pending；3) 若 Pending>=30 再执行 QMD_GPU=cpu $QMD_PATH embed；4) 再次 status 复查。成功且无异常则 ANNOUNCE_SKIP。$NIGHTLY_NOTIFY 完成后回复 ANNOUNCE_SKIP。"

ensure_job() {
  local name="$1"
  shift

  if job_exists "$name"; then
    if [[ "$FORCE_RECREATE" -eq 1 ]]; then
      [[ "$PRINT_JSON" -eq 0 ]] && echo "recreate existing job: $name"
      remove_jobs_by_name "$name"
    else
      [[ "$PRINT_JSON" -eq 0 ]] && echo "keep existing job: $name (use --force-recreate to replace)"
      return 0
    fi
  fi

  run_oc cron add "$@" >/dev/null
}

ensure_job "memory-sync-daily" \
  --name "memory-sync-daily" \
  --cron "0 23 * * *" \
  --tz "$TZ_VALUE" \
  --session isolated \
  --agent main \
  --timeout-seconds 300 \
  --no-deliver \
  --message "$DAILY_MSG"

ensure_job "memory-weekly-tidy" \
  --name "memory-weekly-tidy" \
  --cron "0 22 * * 0" \
  --tz "$TZ_VALUE" \
  --session isolated \
  --agent main \
  --timeout-seconds 600 \
  --no-deliver \
  --message "$WEEKLY_MSG"

ensure_job "memory-cron-watchdog" \
  --name "memory-cron-watchdog" \
  --cron "15 */2 * * *" \
  --tz "$TZ_VALUE" \
  --session isolated \
  --agent main \
  --timeout-seconds 180 \
  --no-deliver \
  --message "$WATCHDOG_MSG"

ensure_job "memory-retrieval-watchdog-v1" \
  --name "memory-retrieval-watchdog-v1" \
  --cron "*/30 * * * *" \
  --tz "$TZ_VALUE" \
  --session isolated \
  --agent main \
  --timeout-seconds 300 \
  --no-deliver \
  --message "$RETRIEVAL_WATCHDOG_MSG"

ensure_job "memory-qmd-nightly-maintain" \
  --name "memory-qmd-nightly-maintain" \
  --cron "20 3 * * *" \
  --tz "$TZ_VALUE" \
  --session isolated \
  --agent main \
  --timeout-seconds 1800 \
  --no-deliver \
  --message "$NIGHTLY_MAINTAIN_MSG"

if [[ "$SKIP_HEALTHCHECK" -eq 0 ]]; then
  if ! run_oc status >/dev/null 2>&1; then
    echo "⚠ gateway postcheck failed: openclaw status timeout/error" >&2
    echo "建议: openclaw gateway restart && openclaw doctor --non-interactive" >&2
    exit 2
  fi
fi

JOBS_JSON="$(list_jobs_json)"
if [[ "$PRINT_JSON" -eq 1 ]]; then
  LIST_JOBS_JSON="$JOBS_JSON" python3 - "$TZ_VALUE" "$WORKSPACE" "$QMD_PATH" "$OPS_CHANNEL" "$OPS_ACCOUNT" "$OPS_TARGET" <<'PY'
import json, os, sys

tz, workspace, qmd, ops_channel, ops_account, ops_target = sys.argv[1:]
raw = os.environ.get("LIST_JOBS_JSON", "").strip() or '{"jobs":[]}'
try:
    data = json.loads(raw)
except Exception:
    data = {"jobs": []}
want = {
    "memory-sync-daily",
    "memory-weekly-tidy",
    "memory-cron-watchdog",
    "memory-retrieval-watchdog-v1",
    "memory-qmd-nightly-maintain",
}
installed = []
for job in data.get("jobs", []):
    if job.get("name") in want:
        state = job.get("state", {})
        installed.append(
            {
                "name": job.get("name"),
                "id": job.get("id"),
                "enabled": job.get("enabled"),
                "nextRunAtMs": state.get("nextRunAtMs"),
                "lastStatus": state.get("lastStatus"),
            }
        )

result = {
    "ok": len(installed) == 5,
    "timezone": tz,
    "workspace": workspace,
    "qmdPath": qmd,
    "watchdogTarget": {
        "channel": ops_channel,
        "accountId": ops_account,
        "target": ops_target if ops_target else None,
    },
    "stateFiles": {
        "processedSessions": os.path.isfile(os.path.join(workspace, "memory/state/processed-sessions.json")),
        "watchdogState": os.path.isfile(os.path.join(workspace, "memory/state/memory-watchdog-state.json")),
        "taskMemoryDir": os.path.isdir(os.path.join(workspace, "memory/tasks")),
        "currentState": os.path.isfile(os.path.join(workspace, "memory/CURRENT_STATE.md")),
        "memoryIndex": os.path.isfile(os.path.join(workspace, "memory/INDEX.md")),
        "contextProfiles": os.path.isfile(os.path.join(workspace, "memory/context-profiles.json")),
        "memLogScript": os.path.isfile(os.path.join(workspace, "scripts/mem-log.sh")),
        "memoryReflectScript": os.path.isfile(os.path.join(workspace, "scripts/memory-reflect.sh")),
        "contextBudgetGuard": os.path.isfile(os.path.join(workspace, "scripts/memory_context_budget_guard.py")),
        "contextPack": os.path.isfile(os.path.join(workspace, "scripts/memory_context_pack.py")),
        "conflictCheck": os.path.isfile(os.path.join(workspace, "scripts/memory_conflict_check.py")),
        "retrievalWatchdog": os.path.isfile(os.path.join(workspace, "scripts/memory_retrieval_watchdog.py")),
    },
    "jobs": sorted(installed, key=lambda x: x["name"]),
}
print(json.dumps(result, ensure_ascii=False))
PY
  exit 0
fi

echo "✅ Installed memory architecture jobs"
echo "timezone=$TZ_VALUE workspace=$WORKSPACE qmd=$QMD_PATH timeout=${CMD_TIMEOUT_SEC}s"
if [[ -n "$OPS_TARGET" ]]; then
  echo "watchdog alert target: $OPS_CHANNEL/$OPS_ACCOUNT/$OPS_TARGET"
else
  echo "watchdog alert target: disabled"
fi
run_oc cron list
