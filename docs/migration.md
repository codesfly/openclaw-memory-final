# Migration Guide

## From ad-hoc memory notes to this architecture

1. Backup your workspace memory files.
2. Install this repo with `scripts/setup.sh`.
3. Merge AGENTS memory section and QMD config snippet.
4. Disable old overlapping memory cron jobs.
5. Run watchdog once and verify status.

## Backward compatibility notes

- Existing `processed-sessions.json` v1 can be migrated to v2 by your daily prompt logic.
- Keep historical daily logs; weekly tidy will archive incrementally.
