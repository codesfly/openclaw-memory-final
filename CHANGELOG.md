# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2026-02-25

### Added
- AI-friendly workspace skills pack under `examples/skills/`:
  - `memory-task-card.skill`
  - `cron-doctor.skill`
  - `long-task-async.skill`
  - `github-release-flow.skill`
  - `heartbeat-ops-check.skill`
  - `trading-stack-autorepair.skill`
- Combined archive: `openclaw-skills-pack-v2026-02-25.tar.gz`.
- `examples/skills/README.md` with install + verification steps.

### Changed
- README (EN/ZH) now documents optional skills-pack install flow.
- `docs/ai-agent-prompt.md` now includes optional skills-pack bootstrap for AI agents.

## [0.2.0] - 2026-02-25

### Added
- Sub-agent task memory index layer (`memory/tasks/YYYY-MM-DD.md`) for result-only task cards.
- Retrieval-order guidance: task cards first, then semantic memory, then raw session drill-down.
- Setup now creates `memory/tasks` directory and exposes `taskMemoryDir` in JSON install report.

### Changed
- Daily sync prompt intent now includes writing sub-agent result cards while skipping noisy raw logs.
- Docs (architecture, operations, migration, AI prompt, READMEs) updated for task-memory workflow.

## [0.1.0] - 2026-02-24

### Added
- Initial open-source release of production memory architecture
- Daily sync / weekly tidy / watchdog cron design
- Idempotent message-fingerprint cursor template
- Setup/uninstall/validate scripts
- Architecture, prompts, migration, and operations docs
- CI workflow (shell + JSON validation)
- OSS community standards files (CONTRIBUTING, CODE_OF_CONDUCT, SECURITY)
