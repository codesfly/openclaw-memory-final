# openclaw-memory-final

Production-grade, open-source memory architecture for OpenClaw.

> This repository packages a practical memory system we run in production: incremental daily distillation, weekly consolidation, watchdog-based reliability, and QMD indexing.

## Highlights

- **Layered memory pipeline**: daily sync + weekly tidy + watchdog
- **Idempotent capture**: message fingerprint cursor (`processed-sessions.json`)
- **Low-noise alerting**: alert only after **2 consecutive anomalies**
- **Cost-aware indexing**: daily `qmd update`, weekly `qmd update && qmd embed`
- **Open-source ready**: docs, scripts, templates, CI, contribution policy

## Architecture (at a glance)

1. **Daily Sync** (`memory-sync-daily`, 23:00 local time)
   - Distill only new conversations from the last 26h
   - Append structured notes to `memory/YYYY-MM-DD.md`
2. **Weekly Tidy** (`memory-weekly-tidy`, Sunday 22:00)
   - Consolidate and prune `MEMORY.md`
   - Generate weekly summary and archive old daily logs
3. **Watchdog** (`memory-cron-watchdog`, every 2h at :15)
   - Checks stale/error/disabled state
   - Alerts only when anomaly repeats twice

See full design: [`docs/architecture.md`](docs/architecture.md)

## Quick Start

```bash
bash scripts/setup.sh --tz Asia/Shanghai
```

Then:
1. Merge `examples/AGENTS-memory-section.md` into your `~/.openclaw/workspace/AGENTS.md`
2. Merge `examples/openclaw-memory-config.json` into `~/.openclaw/openclaw.json`
3. Restart gateway

```bash
openclaw gateway restart
```

## Repository Layout

```text
.github/                # CI, issue templates, PR template
scripts/                # setup/uninstall/validate
examples/               # config and template files
docs/                   # architecture/ops/prompts/migration
```

## Versioning

This project follows **Semantic Versioning**.

## License

MIT — see [`LICENSE`](LICENSE).

## Chinese README

中文说明见 [`README.zh-CN.md`](README.zh-CN.md)（兼容链接：[`README_CN.md`](README_CN.md)）。
