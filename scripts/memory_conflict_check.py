#!/usr/bin/env python3
"""Lightweight conflict checker for MEMORY.md durable rules."""

import argparse
import json
import re
from pathlib import Path


def extract_bullets(path: Path):
    return [ln.strip() for ln in path.read_text(encoding="utf-8", errors="ignore").splitlines() if ln.strip().startswith("-")]


def find_models(lines):
    vals = set()
    for ln in lines:
        if "模型" in ln or "model" in ln.lower():
            vals.update(re.findall(r"`([^`]+)`", ln))
    return sorted(vals)


def find_route_ids(lines):
    vals = set()
    for ln in lines:
        if any(k in ln for k in ["通知", "路由", "群", "私聊", "target", "channel"]):
            vals.update(re.findall(r"-?\d{6,}", ln))
    return sorted(vals)


def main() -> int:
    ap = argparse.ArgumentParser(description="Detect memory conflicts")
    ap.add_argument("--memory", default="/home/jiumu/.openclaw/workspace/MEMORY.md")
    ap.add_argument(
        "--out",
        default="/home/jiumu/.openclaw/workspace/memory/state/memory-conflict-report.json",
    )
    args = ap.parse_args()

    p = Path(args.memory)
    lines = extract_bullets(p)

    models = find_models(lines)
    routes = find_route_ids(lines)

    findings = []
    # informational signal: multiple model hints exist
    if len(models) >= 4:
        findings.append(
            {
                "type": "model_multi_declared",
                "severity": "info",
                "detail": f"检测到多个模型声明（可能正常）：{models}",
            }
        )

    # warning signal: too many route/chat ids may indicate conflicting routing rules
    if len(routes) > 2:
        findings.append(
            {
                "type": "route_multi_declared",
                "severity": "warn",
                "detail": f"检测到多个通知/会话ID声明，建议核对是否冲突：{routes}",
            }
        )

    out = {
        "ok": len([f for f in findings if f["severity"] in ("warn", "error")]) == 0,
        "findings": findings,
        "memory_file": str(p),
    }

    outp = Path(args.out)
    outp.parent.mkdir(parents=True, exist_ok=True)
    outp.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if out["ok"]:
        print("OK no warn/error conflicts")
        return 0
    print("WARN " + " | ".join(f["detail"] for f in findings))
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
