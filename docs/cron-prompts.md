# Cron Prompt Reference

This repository ships prompt templates through `scripts/setup.sh`.

## Daily Sync prompt (intent)

- Pull recent sessions
- Filter low-signal sessions
- Compute message fingerprint
- Append concise memory block to today's file
- Update cursor state
- Run `qmd update`

## Weekly Tidy prompt (intent)

- Read last 7 days + current `MEMORY.md`
- Keep only long-term, action-relevant facts
- Prune stale entries
- Generate weekly summary + archive old logs
- Run `qmd update && qmd embed`

## Watchdog prompt (intent)

- Check `memory-sync-daily` and `memory-weekly-tidy`
- Detect stale/error/disabled states
- Require two consecutive anomalies before alerting
- Include `last3` snapshots in alert payload
