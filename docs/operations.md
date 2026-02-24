# Operations Runbook

## Verify cron jobs

```bash
openclaw cron list
```

Expected jobs:
- `memory-sync-daily`
- `memory-weekly-tidy`
- `memory-cron-watchdog`

## Force-run for smoke test

```bash
openclaw cron run <job-id>
```

## Common failures

1. Gateway timeout while run is actually in progress
   - Re-check with `cron list` for `runningAtMs`
2. Missing QMD binary
   - Verify path in `openclaw.json`
3. Duplicate memory blocks
   - Verify `processed-sessions.json` is writable and prompt uses fingerprint logic
