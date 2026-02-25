# Workspace Skills Pack (AI-Friendly)

This folder contains custom OpenClaw skills used by this memory architecture workflow.

## Included skills

- `memory-task-card.skill`
- `cron-doctor.skill`
- `long-task-async.skill`
- `github-release-flow.skill`
- `heartbeat-ops-check.skill`
- `trading-stack-autorepair.skill`

## One-file bundle

- `openclaw-skills-pack-v2026-02-25.tar.gz`

## Install (manual)

1. Extract skills into your workspace skills directory:

```bash
mkdir -p ~/.openclaw/workspace/skills
cd ~/.openclaw/workspace/skills
# copy and extract from this repo bundle
tar -xzf openclaw-skills-pack-v2026-02-25.tar.gz
```

2. Verify skills are visible:

```bash
openclaw skills list
openclaw skills list --eligible
```

3. Start a new session (skill snapshot refresh on new session).

## AI-agent instruction

If an AI agent is applying this repository, ask it to:
- copy `.skill` files (or extract the tarball) into `<workspace>/skills`
- run `openclaw skills list --eligible`
- continue with memory setup flow (`scripts/install-ai.sh` + docs/ai-agent-prompt.md)

## Notes

- Workspace skills have highest precedence over bundled/managed skills.
- Keep skill names stable to avoid triggering drift.
