# openclaw-memory-final

面向生产的 OpenClaw 记忆架构开源模板。

> 这套方案来自真实运行环境：日增量蒸馏、周度精炼、watchdog 稳定性守护、QMD 成本优化索引。

## 核心能力

- **三层链路**：daily sync + weekly tidy + watchdog
- **幂等去重**：消息指纹游标（`processed-sessions.json`）
- **低噪告警**：连续 2 次异常才告警
- **成本控制**：日常只 `qmd update`，周任务才 `embed`
- **开源标准化**：文档、脚本、模板、CI、贡献规范完整

## 快速安装

```bash
bash scripts/setup.sh --tz Asia/Shanghai
```

安装后请完成三步：

1. 将 `examples/AGENTS-memory-section.md` 合并到 `~/.openclaw/workspace/AGENTS.md`
2. 将 `examples/openclaw-memory-config.json` 合并到 `~/.openclaw/openclaw.json`
3. 重启 gateway：

```bash
openclaw gateway restart
```

## 文档入口

- 架构设计：[`docs/architecture.md`](docs/architecture.md)
- Cron Prompt：[`docs/cron-prompts.md`](docs/cron-prompts.md)
- 迁移指南：[`docs/migration.md`](docs/migration.md)
- 运维手册：[`docs/operations.md`](docs/operations.md)

## 许可证

MIT，见 [`LICENSE`](LICENSE)。
