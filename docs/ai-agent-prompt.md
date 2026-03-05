# AI Agent Bootstrap Prompt (One-Link Friendly)

Paste this prompt to OpenClaw with the repository URL.

```text
请在当前机器按“可审计、可回滚”的方式部署：
https://github.com/codesfly/openclaw-memory-final

严格按以下步骤执行：
1) clone 仓库到临时目录
2) 执行（单命令安装，AI 友好）：
   bash scripts/install-ai.sh --tz Asia/Shanghai
   （该命令会自动初始化 `memory/CURRENT_STATE.md`、`memory/INDEX.md`、`scripts/mem-log.sh`、`scripts/memory-reflect.sh`）
3) 若返回 `AI_INSTALL_ERROR qmd_not_found`：
   - 先安装：`npm install -g @tobilu/qmd`
   - 用 `qmd --version` 验证
   - 再重试：`bash scripts/install-ai.sh --tz Asia/Shanghai --qmd-path "$(command -v qmd)"`
4) 若成功，必须输出 install-ai.sh 返回的 JSON 原文
5) 再执行一次核验：
   - openclaw cron list（确认存在 memory-sync-daily / memory-weekly-tidy / memory-cron-watchdog / memory-retrieval-watchdog-v1 / memory-qmd-nightly-maintain）
   - 检查 `~/.openclaw/workspace/memory/state/processed-sessions.json`
   - 检查 `~/.openclaw/workspace/memory/state/memory-watchdog-state.json`
   - 检查 `~/.openclaw/workspace/memory/context-profiles.json`
   - 执行 `python3 ~/.openclaw/workspace/scripts/memory_context_budget_guard.py --profile main`
6) 若存在子 agent 任务，补充生成结果卡：`~/.openclaw/workspace/memory/tasks/YYYY-MM-DD.md`
   - 仅写结论，不粘贴完整执行日志
   - 字段至少包含：任务目标、边界、验收、关键动作、产物路径、最终状态、下一步
7) 最终回报格式：
   - Result: OK/FAIL
   - Jobs: 名称 -> id
   - Next Runs:
   - QMD Path:
   - Warnings:

约束：
- 不修改任何非 memory-* 任务
- 不执行外发消息（除非我明确提供 ops target）
- 不做全量 config.apply 覆盖
- 子 agent 原始执行过程保留在会话历史；长期记忆仅沉淀 task card 结论
- 必须启用“记忆注入预算”硬约束（每文件/总量双阈值）

可选增强（AI 友好）：
- 优先执行 `bash scripts/install-skills-pack.sh` 安装 skills 包。
- 若脚本不可用，再回退为手动解压 `examples/skills/openclaw-skills-pack-*.tar.gz` 到 `<workspace>/skills`。
- 执行 `openclaw skills list --eligible` 验证技能可见。
- 提醒用户：skills 在新会话生效（session snapshot）。
```

## Why this is AI-friendly

- Single command (`install-ai.sh`) for deterministic install
- Structured success/error markers (`AI_INSTALL_OK` / `AI_INSTALL_ERROR`)
- Machine-readable JSON output for automated verification
