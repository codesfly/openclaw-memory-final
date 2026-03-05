#!/usr/bin/env python3
"""Build a budgeted memory context pack from profile config."""

import argparse
import datetime as dt
import json
from pathlib import Path


def resolve_path(ws: Path, p: str) -> Path:
    now = dt.datetime.now()
    today = now.strftime("%Y-%m-%d")
    yesterday = (now - dt.timedelta(days=1)).strftime("%Y-%m-%d")
    p = p.replace("{today}", today).replace("{yesterday}", yesterday)
    return ws / p


def main() -> int:
    ap = argparse.ArgumentParser(description="Build dynamic memory context pack")
    ap.add_argument("--workspace", default="/home/jiumu/.openclaw/workspace")
    ap.add_argument(
        "--config",
        default="/home/jiumu/.openclaw/workspace/memory/context-profiles.json",
    )
    ap.add_argument("--profile", default="main")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    ws = Path(args.workspace)
    cfg = json.loads(Path(args.config).read_text(encoding="utf-8"))
    if args.profile not in cfg.get("profiles", {}):
        raise SystemExit(f"unknown profile: {args.profile}")

    prof = cfg["profiles"][args.profile]
    defaults = cfg.get("defaults", {})
    max_total = int(prof.get("max_total_chars", defaults.get("max_total_chars", 80000)))
    max_per = int(defaults.get("max_per_file_chars", 20000))

    items = sorted(prof.get("items", []), key=lambda x: x.get("priority", 0), reverse=True)

    chosen = []
    total = 0
    for it in items:
        p = resolve_path(ws, it["path"])
        if not p.exists() or not p.is_file():
            continue
        txt = p.read_text(encoding="utf-8", errors="ignore")
        chars = min(len(txt), max_per)
        if total + chars > max_total:
            continue
        total += chars
        chosen.append({"file": str(p), "chars_used": chars, "priority": it.get("priority", 0)})

    out = {
        "profile": args.profile,
        "max_total": max_total,
        "max_per_file": max_per,
        "total_chars": total,
        "files": chosen,
    }

    if args.json:
        print(json.dumps(out, ensure_ascii=False, indent=2))
    else:
        print(f"profile={args.profile} total={total}/{max_total}")
        for f in chosen:
            print(f"- {f['file']} ({f['chars_used']} chars)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
