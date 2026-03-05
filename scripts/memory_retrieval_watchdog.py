#!/usr/bin/env python3
"""Watchdog for memory retrieval health (QMD status/search)."""

import argparse
import json
import subprocess
import time
from pathlib import Path


def run(cmd, timeout=40):
    proc = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        timeout=timeout,
        check=False,
    )
    return proc.returncode, proc.stdout


def parse_pending(status_text: str) -> int:
    for ln in status_text.splitlines():
        if "Pending:" in ln and "need embedding" in ln:
            digits = "".join(ch for ch in ln if ch.isdigit())
            if digits:
                return int(digits)
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="Watchdog for memory retrieval health")
    ap.add_argument("--qmd-path", default="qmd")
    ap.add_argument("--collection", default="workspace")
    ap.add_argument("--query", default="记忆")
    ap.add_argument(
        "--state",
        default="/home/jiumu/.openclaw/workspace/memory/state/memory-retrieval-watchdog-state.json",
    )
    ap.add_argument("--confirm", type=int, default=2, help="consecutive anomalies before confirmed")
    ap.add_argument("--pending-threshold", type=int, default=120)
    args = ap.parse_args()

    state_p = Path(args.state)
    state_p.parent.mkdir(parents=True, exist_ok=True)
    try:
        state = json.loads(state_p.read_text(encoding="utf-8")) if state_p.exists() else {}
    except Exception:
        state = {}

    consecutive = int(state.get("consecutive_anomalies", 0))
    anomalies = []

    rc, status_out = run([args.qmd_path, "status"], timeout=40)
    if rc != 0:
        anomalies.append("qmd_status_failed")
    pending = parse_pending(status_out)
    if pending > args.pending_threshold:
        anomalies.append(f"embedding_backlog_high:{pending}")

    rc, search_out = run(
        [args.qmd_path, "search", args.query, "-c", args.collection, "-n", "1", "--json"],
        timeout=40,
    )
    if rc != 0:
        anomalies.append("qmd_search_failed")
    else:
        try:
            arr = json.loads(search_out)
            if not isinstance(arr, list) or len(arr) == 0:
                anomalies.append("qmd_search_empty")
        except Exception:
            anomalies.append("qmd_search_non_json")

    if anomalies:
        consecutive += 1
        confirmed = consecutive >= args.confirm
    else:
        consecutive = 0
        confirmed = False

    new_state = {
        "ts": int(time.time()),
        "consecutive_anomalies": consecutive,
        "last_anomalies": anomalies,
        "pending_embeddings": pending,
        "confirmed": confirmed,
        "qmd_path": args.qmd_path,
        "collection": args.collection,
        "query": args.query,
    }
    state_p.write_text(json.dumps(new_state, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if not anomalies:
        print("OK retrieval healthy")
        return 0

    if confirmed:
        print("CONFIRMED_ANOMALY " + " | ".join(anomalies))
        return 2

    print("FIRST_ANOMALY " + " | ".join(anomalies))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
