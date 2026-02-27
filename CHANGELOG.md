# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- MVP memory baseline assets:
  - `examples/CURRENT_STATE.md.template`
  - `examples/memory-INDEX.md.template`
  - `scripts/mem-log.sh`
  - `scripts/memory-reflect.sh`

### Changed
- README (EN/ZH): streamlined install flow to one-link usage; `install-ai.sh` now auto-bootstraps MVP baseline files.
- README (EN/ZH): architecture overview now explicitly includes multi-agent memory handoff (main session curation + sub-agent task cards).
- `docs/architecture.md`: included short-term `CURRENT_STATE` layer and explicit multi-agent memory model in pipeline/system docs, with updated diagram for sub-agent isolation/handoff.
- `docs/operations.md`: updated baseline section to use installed workspace scripts directly.
- `docs/ai-agent-prompt.md`: clarified that one-command install also initializes baseline memory files/scripts.
- `examples/AGENTS-memory-section.md`: added short-term workspace + multi-agent handoff guidance.
- `scripts/setup.sh`: now auto-initializes MVP baseline files/scripts into target workspace and reports them in JSON output.
- `scripts/validate.sh`: now validates shell syntax for new helper scripts.

## [0.2.3] - 2026-02-25

### Fixed
- Fixed `scripts/setup.sh` JSON parsing bug caused by heredoc + here-string conflict (`NameError: true`) in Python helpers.
- Fixed `scripts/uninstall.sh` same parsing pattern causing potential job-id lookup failure.

### Impact
- `setup.sh --print-json` now works reliably.
- `setup.sh --force-recreate` no longer risks duplicate `memory-*` cron jobs from false-negative existence checks.
- `uninstall.sh` now removes target memory cron jobs deterministically.

## [0.2.2] - 2026-02-25

### Added
- `scripts/install-skills-pack.sh` for one-command installation of the AI-friendly workspace skills bundle.
- JSON-style success output (`SKILLS_INSTALL_OK`) for deterministic agent automation.

### Changed
- README (EN/ZH) now recommends one-command skills installation.
- `docs/ai-agent-prompt.md` now prefers installer script and falls back to manual extraction.

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
