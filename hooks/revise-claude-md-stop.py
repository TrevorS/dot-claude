#!/usr/bin/env python3
"""Stop hook: propose CLAUDE.md updates when a session changed enough to be worth capturing.

Two modes (CLAUDE_REVISE_MODE):
    hint   (default) - emits systemMessage; surfaces a note to the user that the session
                       changed enough to be worth a CLAUDE.md revision. Non-blocking.
    block            - emits decision:block so Claude refuses to stop and runs the skill
                       before ending. Intrusive; use with strict thresholds.

Tuning (env vars; override anywhere - shell, ~/.local.zsh, settings.json env, etc.):
    CLAUDE_REVISE_ENABLED=1             kill switch (default 1)
    CLAUDE_REVISE_MODE=hint             hint | block
    CLAUDE_REVISE_MIN_DURATION_SEC=900  min session age (default 15 min)
    CLAUDE_REVISE_MIN_CHANGED_FILES=3   min dirty files in cwd (default 3)
    CLAUDE_REVISE_COOLDOWN_SEC=7200     per-project cooldown (default 2 h)
    CLAUDE_REVISE_INCLUDE_REGEX=""      optional regex; only fire if cwd matches

State: ~/.claude/cache/revise-claude-md/<sha1(cwd)>.last  (epoch of last fire)

Self-test: `python3 revise-claude-md-stop.py --selftest` runs threshold logic against
fixtures without touching the cache or shelling out.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

CACHE_DIR = Path.home() / ".claude" / "cache" / "revise-claude-md"
HINT_TEMPLATE = (
    "[revise-claude-md] This session changed {n} file(s). Consider invoking the "
    "claude-md-management:revise-claude-md skill to capture any learnings "
    "(new conventions, surprising gotchas, useful commands) into CLAUDE.md "
    "while context is fresh."
)


@dataclass
class Config:
    enabled: bool
    mode: str
    min_duration_sec: int
    min_changed_files: int
    cooldown_sec: int
    include_regex: str

    @classmethod
    def from_env(cls, env: dict[str, str]) -> Config:
        return cls(
            enabled=env.get("CLAUDE_REVISE_ENABLED", "1") == "1",
            mode=env.get("CLAUDE_REVISE_MODE", "hint"),
            min_duration_sec=int(env.get("CLAUDE_REVISE_MIN_DURATION_SEC", "900")),
            min_changed_files=int(env.get("CLAUDE_REVISE_MIN_CHANGED_FILES", "3")),
            cooldown_sec=int(env.get("CLAUDE_REVISE_COOLDOWN_SEC", "7200")),
            include_regex=env.get("CLAUDE_REVISE_INCLUDE_REGEX", ""),
        )


def parse_session_start(payload: dict) -> int:
    """Extract session start epoch from Stop payload; 0 if unknown."""
    iso = payload.get("session_start_time")
    if not iso:
        return 0
    iso_clean = iso.split(".")[0].rstrip("Z")
    try:
        return int(datetime.fromisoformat(iso_clean).timestamp())
    except ValueError:
        return 0


def count_changed_files(cwd: Path) -> int:
    """Count dirty files in cwd. Prefers jj over git (we run jj-colocated)."""
    if (cwd / ".jj").is_dir():
        cmd = ["jj", "diff", "--summary"]
    elif (cwd / ".git").is_dir():
        cmd = ["git", "status", "--porcelain"]
    else:
        return 0
    try:
        out = subprocess.run(
            cmd, cwd=cwd, capture_output=True, text=True, timeout=5, check=False
        )
        return len([line for line in out.stdout.splitlines() if line.strip()])
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return 0


def cooldown_path(cwd: Path) -> Path:
    return CACHE_DIR / (hashlib.sha1(str(cwd).encode()).hexdigest() + ".last")


def in_cooldown(cwd: Path, now: int, cooldown_sec: int) -> bool:
    p = cooldown_path(cwd)
    if not p.exists():
        return False
    try:
        last = int(p.read_text().strip())
    except ValueError:
        return False
    return now - last < cooldown_sec


def record_fire(cwd: Path, now: int) -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cooldown_path(cwd).write_text(str(now))


def should_fire(
    cfg: Config, cwd: Path, now: int, payload: dict, changed: int
) -> bool:
    if not cfg.enabled:
        return False
    if cfg.include_regex and not re.search(cfg.include_regex, str(cwd)):
        return False
    if in_cooldown(cwd, now, cfg.cooldown_sec):
        return False
    start = parse_session_start(payload)
    if start > 0 and now - start < cfg.min_duration_sec:
        return False
    return changed >= cfg.min_changed_files


def build_output(mode: str, changed: int) -> dict:
    msg = HINT_TEMPLATE.format(n=changed)
    if mode == "block":
        return {"decision": "block", "reason": msg}
    return {"systemMessage": msg}


def main(argv: list[str], env: dict[str, str], stdin_text: str) -> int:
    if "--selftest" in argv:
        return selftest()

    cfg = Config.from_env(env)
    try:
        payload = json.loads(stdin_text) if stdin_text.strip() else {}
    except json.JSONDecodeError:
        payload = {}

    cwd = Path.cwd()
    now = int(time.time())
    changed = count_changed_files(cwd)

    if not should_fire(cfg, cwd, now, payload, changed):
        return 0

    record_fire(cwd, now)
    print(json.dumps(build_output(cfg.mode, changed)))
    return 0


def selftest() -> int:
    """Quick inline tests; exits 0 on pass, 1 on fail."""
    failures: list[str] = []

    def check(name: str, cond: bool) -> None:
        if not cond:
            failures.append(name)

    cfg_default = Config.from_env({})
    check("default enabled", cfg_default.enabled)
    check("default mode hint", cfg_default.mode == "hint")
    check("default min_duration", cfg_default.min_duration_sec == 900)

    cfg_off = Config.from_env({"CLAUDE_REVISE_ENABLED": "0"})
    check("kill switch", not cfg_off.enabled)

    cfg_block = Config.from_env({"CLAUDE_REVISE_MODE": "block"})
    check("block mode", cfg_block.mode == "block")

    # should_fire matrix
    cwd = Path("/tmp/nonexistent-for-selftest")
    now = 10_000
    check(
        "fires when changed >= min and no cooldown",
        should_fire(cfg_default, cwd, now, {}, changed=5),
    )
    check(
        "does not fire when changed < min",
        not should_fire(cfg_default, cwd, now, {}, changed=1),
    )
    check(
        "does not fire when disabled",
        not should_fire(cfg_off, cwd, now, {}, changed=99),
    )
    check(
        "respects include regex (match)",
        should_fire(
            Config.from_env({"CLAUDE_REVISE_INCLUDE_REGEX": "nonexistent"}),
            cwd, now, {}, changed=5,
        ),
    )
    check(
        "respects include regex (no match)",
        not should_fire(
            Config.from_env({"CLAUDE_REVISE_INCLUDE_REGEX": "wontmatch"}),
            cwd, now, {}, changed=5,
        ),
    )

    # session duration short-circuit
    short_payload = {"session_start_time": datetime.fromtimestamp(now - 60).isoformat()}
    check(
        "skips when session too short",
        not should_fire(cfg_default, cwd, now, short_payload, changed=5),
    )

    # output shape
    out_hint = build_output("hint", 7)
    check("hint output shape", "systemMessage" in out_hint)
    out_block = build_output("block", 7)
    check("block output shape", out_block.get("decision") == "block")

    if failures:
        print(f"FAIL: {', '.join(failures)}", file=sys.stderr)
        return 1
    print("ok")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:], dict(os.environ), sys.stdin.read()))
