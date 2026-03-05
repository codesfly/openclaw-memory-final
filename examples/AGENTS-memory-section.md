## Memory (Production Pattern)

You wake up fresh each session. Files are your memory.

### Session startup sequence

1. Read `SOUL.md`
2. Read `USER.md`
3. Read today's and yesterday's daily memory logs
4. In direct/private main session only: read `MEMORY.md`

### Three-layer memory model

- Short-term workspace: `memory/CURRENT_STATE.md`
- Daily logs: `memory/YYYY-MM-DD.md`
- Weekly summaries: `memory/weekly/YYYY-MM-DD.md` (Monday key)
- Long-term memory: `MEMORY.md` (strictly curated)

### Multi-agent memory handoff

- Main session is the memory curator.
- Sub-agents keep raw execution in isolated session history.
- Share outcomes via result-only task cards: `memory/tasks/YYYY-MM-DD.md`.

### Long-term memory constraints

- Keep `MEMORY.md` concise and actionable
- Recommended hard cap: 80 lines / 5KB
- Compress/merge before adding if near cap

### Sub-agent task memory (result-only)

- Keep sub-agent raw process in isolated session history.
- Persist only reusable outcomes into `memory/tasks/YYYY-MM-DD.md`.
- Suggested fields: goal, boundary, acceptance, key actions, artifact paths, final status, next step.

### Retrieval order

1. Check `memory/tasks/*.md` first
2. Then run semantic memory search
3. Drill into raw session history only when needed

### Context budget + dynamic profile (V1)

- Enforce hard budget before injecting memory/context into prompts:
  - `max_per_file_chars=20000`
  - `max_total_chars=80000`
- Use `memory/context-profiles.json` to pick minimal context by profile (`main/ops/btc/quant`).
- Run `scripts/memory_context_budget_guard.py` periodically and persist its state.
- Run `scripts/memory_conflict_check.py` before writing durable long-term memory rules.

### Write-now rule

When key decisions or durable user preferences appear, append to today's daily memory immediately.
Do not rely on cron alone.

### Safety

Never write tokens/secrets/private identifiers into memory files.
