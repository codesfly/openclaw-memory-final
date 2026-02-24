#!/usr/bin/env bash
set -euo pipefail

# shell syntax
bash -n scripts/setup.sh
bash -n scripts/uninstall.sh

# json validity
jq empty examples/openclaw-memory-config.json
jq empty examples/memory/state/processed-sessions.json
jq empty examples/memory/state/memory-watchdog-state.json

echo "✅ validation passed"
