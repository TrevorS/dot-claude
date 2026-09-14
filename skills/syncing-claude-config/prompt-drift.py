#!/usr/bin/env python3
"""Detect when the product's own system prompt changed since the last sync.

Config rules are written against whatever the Claude Code system prompt said
at the time. When the product prompt moves (a new "Delivering work" block, a
new autonomous-posture paragraph, new writing rules) the config can start
duplicating or contradicting it without any release note saying so. This
script pulls the behavioural sections of the system prompt straight out of the
installed binary, keyed by stable heading anchors, and diffs them against the
snapshot taken at the last sync.

    prompt-drift.py                 # diff installed binary vs snapshot; exit 1 on drift
    prompt-drift.py --update        # rewrite the snapshot from the installed binary
    prompt-drift.py --show harness  # print one section as currently shipped

A changed section is the trigger for re-running the line-by-line config
review (SKILL.md step 7): every KEEP/DITCH verdict in the ledger was made
against the old text.

Some sections ship dormant: the string is in the binary but the function
returning it is guarded (`if(!G(e))return null`). The guard is resolved to a
stable summary ("off", "on", or the flag / model prefix it tests) and stored
beside the text, so a gate flipping on with no text change is still drift.
"""

from __future__ import annotations

import argparse
import difflib
import hashlib
import json
import os
import re
import shutil
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SNAPSHOT = HERE / "system-prompt-snapshot.json"

# Stable opening phrases of the behavioural sections. Each is looked up as raw
# bytes; the section runs to the end of its JS template literal or the next
# "\n# " heading, whichever comes first. Cosmetic/tool-reference sections
# (artifact CDN rules, browser automation) are deliberately not tracked --
# they never overlap with user config.
ANCHORS: dict[str, bytes] = {
    "harness": b"# Harness\n",
    "pronouns": b"When you use a pronoun for someone",
    "irreversible": b"For actions that are hard to reverse or outward-facing",
    "context-management": b"# Context management\n",
    "act-dont-relitigate": b"When you have enough information to act, act.",
    "delivering-work": b"# Delivering work\n",
    "writing-for-user": b"# Writing for the user\n",
    "autonomous": b"You are operating autonomously.",
    "state-change-evidence": b"Before running a command that changes system state",
    "concise-style": b"The user chose brevity over narration.",
    "memory": b"# Memory\n",
    # Dormant in 2.1.272 (gate returns false); tracked so the flip is drift.
    "agreed-task": b"When a task has been agreed, the approval covers it end to end",
    # Agent tool "when to use" guidance; governs delegation that several skills instruct on.
    "agent-when-to-use": b"A fresh agent costs more than it looks.",
}

MAX_SECTION = 8000
GATES: dict[str, str] = {}  # filled by extract(): section -> gate summary


def installed_binary() -> Path:
    exe = shutil.which("claude")
    if not exe:
        sys.exit("claude not on PATH")
    return Path(os.path.realpath(exe))


def unescape(b: bytes) -> str:
    s = b.decode("utf-8", "replace")
    s = re.sub(r"\\u([0-9a-fA-F]{4})", lambda m: chr(int(m.group(1), 16)), s)
    s = s.replace("\\n", "\n").replace("\\`", "`").replace("\\'", "'")
    return normalize(s)


# Minified identifiers inside template interpolations (${dSr(n,"lean")},
# ${To.join(...)}) are renamed on every build. Replace the leading identifier
# so only a change in the interpolation's shape or arguments counts as drift.
_MINIFIED = re.compile(r"\$\{[A-Za-z_$][\w$]*")


def normalize(s: str) -> str:
    return _MINIFIED.sub("${_", s)


def _unescaped_backtick(chunk: bytes) -> int:
    """Offset of the first backtick not preceded by a backslash, or -1."""
    m = re.search(rb"(?<!\\)`", chunk[1:])
    return m.start() + 1 if m else -1


def _closing_brace(chunk: bytes) -> int:
    """Offset of a `"}` that closes the enclosing function body, or -1.

    `"}` also ends a template interpolation such as ${_(e)?"":"..."}, which is
    followed by more prose; only a `"}` followed by a JS keyword or another
    closer is a real section boundary.
    """
    m = re.search(rb'"\}(?=(?:function|var|let|const|return)\b|[});])', chunk[1:])
    return m.start() + 1 if m else -1


_FLAG = re.compile(rb"[A-Z][A-Z0-9_]{5,}")
_MODEL = re.compile(rb'startsWith\("([^"]+)"\)|==="([^"]+)"')


def gate_state(data: bytes, pos: int) -> str:
    """Summarise the guard on the prompt string starting at pos.

    Handles the shape function X(e){if(!G(e))return null;return"..."} and
    resolves G to a stable summary: "off"/"on" for constant bodies, the flag or
    model-prefix names it tests otherwise. Minified helper names are dropped so
    only a change in what the gate tests counts as drift.
    """
    head = data[max(0, pos - 100) : pos]
    m = re.search(rb'if\((!?)(\w+)\(e\)\)return null;return"$', head)
    if not m:
        return "ungated"
    neg, g = m.group(1) == b"!", m.group(2)
    b = re.search(rb"function " + re.escape(g) + rb"\(e\)\{(.{0,240}?)\}(?=function|var|let|const|;)", data, re.S)
    if not b:
        return "gate unresolved"
    body = b.group(1)
    if body == b"return!1":
        return "off" if neg else "on"
    if body == b"return!0":
        return "on" if neg else "off"
    names = sorted(set(_FLAG.findall(body)) | {x for t in _MODEL.findall(body) for x in t if x})
    return "gate: " + ", ".join(n.decode() for n in names) if names else "gate: other"


def extract(data: bytes) -> dict[str, str]:
    """Pull each anchored section out of the binary.

    The prompt text appears more than once (JS source plus a compiled
    constant pool with NUL terminators), so every occurrence is tried and the
    longest cleanly terminated one wins.
    """
    out: dict[str, str] = {}
    GATES.clear()
    for key, anchor in ANCHORS.items():
        best = ""
        for m in re.finditer(re.escape(anchor), data):
            g = gate_state(data, m.start())
            if g != "ungated":
                GATES[key] = g
            chunk = data[m.start() : m.start() + MAX_SECTION]
            ends = [
                p
                for p in (
                    _unescaped_backtick(chunk),
                    chunk.find(b'",', 1),
                    chunk.find(b'";', 1),
                    _closing_brace(chunk),
                    chunk.find(b"\x00", 1),
                    chunk.find(b"\n# ", len(anchor)),
                )
                if p > 0
            ]
            if not ends:
                continue  # ran off the cap: not a real section boundary
            raw = chunk[: min(ends)]
            try:
                raw.decode("utf-8")
            except UnicodeDecodeError as e:
                raw = raw[: e.start]  # constant-pool copies run into the next entry's length prefix
            text = unescape(raw).strip()
            if len(text) > len(best):
                best = text
        out[key] = best
    return out


def digest(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()[:12]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--binary", type=Path, help="claude binary (default: resolved from PATH)")
    ap.add_argument("--snapshot", type=Path, default=SNAPSHOT)
    ap.add_argument("--update", action="store_true", help="rewrite the snapshot")
    ap.add_argument("--show", metavar="SECTION", help="print one section and exit")
    args = ap.parse_args()

    binary = args.binary or installed_binary()
    data = binary.read_bytes()
    current = extract(data)
    version = re.search(rb'"version":"(2\.\d+\.\d+)"', data)
    ver = version.group(1).decode() if version else binary.name

    if args.show:
        if args.show not in current:
            sys.exit(f"unknown section; choose from {', '.join(ANCHORS)}")
        print(current[args.show])
        print(f"\n[gate: {GATES.get(args.show, 'ungated')}]")
        return 0

    missing = [k for k, v in current.items() if not v]
    if missing:
        print(f"anchor not found in {ver}: {', '.join(missing)} (anchor text may have moved)")

    if args.update:
        args.snapshot.write_text(
            json.dumps({"claudeCodeVersion": ver, "sections": current, "gates": dict(GATES)}, indent=2, ensure_ascii=False) + "\n"
        )
        print(f"snapshot written for {ver}: {len(current)} sections -> {args.snapshot}")
        return 0

    if not args.snapshot.exists():
        print(f"no snapshot at {args.snapshot}; run with --update to take one")
        return 2

    snap = json.loads(args.snapshot.read_text())
    old = snap.get("sections", {})
    old_gates = snap.get("gates", {})
    changed = 0
    for key in ANCHORS:
        ga, gb = old_gates.get(key, "ungated"), GATES.get(key, "ungated")
        if ga != gb and key in old:
            changed += 1
            print(f"\n== {key}: gate {ga} -> {gb}")
        a, b = old.get(key, ""), current.get(key, "")
        if a == b:
            continue
        changed += 1
        kind = "added" if not a else "removed" if not b else "changed"
        print(f"\n== {key}: {kind} ({digest(a)} -> {digest(b)})")
        for line in difflib.unified_diff(
            a.splitlines(), b.splitlines(), fromfile=f"snapshot {snap.get('claudeCodeVersion')}", tofile=f"installed {ver}", lineterm="", n=1
        ):
            print(line)

    if changed:
        print(f"\n{changed} section(s) drifted since {snap.get('claudeCodeVersion')} -> re-run the config line review (SKILL.md step 7)")
        return 1
    print(f"system prompt unchanged since {snap.get('claudeCodeVersion')} ({len(ANCHORS)} sections, installed {ver})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
