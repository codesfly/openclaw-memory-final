#!/usr/bin/env bash
set -euo pipefail

# shell syntax
bash -n scripts/setup.sh
bash -n scripts/uninstall.sh
bash -n scripts/install-ai.sh
bash -n scripts/mem-log.sh
bash -n scripts/memory-reflect.sh

# python syntax
python3 -m py_compile scripts/memory_context_budget_guard.py
python3 -m py_compile scripts/memory_context_pack.py
python3 -m py_compile scripts/memory_conflict_check.py
python3 -m py_compile scripts/memory_retrieval_watchdog.py

# json validity
jq empty examples/openclaw-memory-config.patch.json
jq empty examples/memory/state/processed-sessions.json
jq empty examples/memory/state/memory-watchdog-state.json
jq empty examples/memory/context-profiles.json

echo "✅ validation passed"
