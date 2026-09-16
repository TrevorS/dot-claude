#!/usr/bin/env python3
"""Whole-binary prose diff between two installed Claude Code builds.

Extracts runs of 22+ words from each binary's strings dump and prints the set
difference: prose the new build added and prose it dropped. Catches system-prompt
and tool-description changes outside the anchors prompt-drift.py tracks (the
2.1.269->2.1.272 Agent tool rewrite, the 2.1.273 Artifact publishing wording).

Usage:
    python3 prose-diff.py OLD NEW            # paths to binaries or strings dumps
    python3 prose-diff.py 2.1.272 2.1.273    # bare versions resolve under
                                             # ~/.local/share/claude/versions/

Embedded changelog bullets ("\\n- Fixed ...") show up here too when the bundled
changelog rotates; check them against the releases API before treating them as
unreleased changes.
"""
import os
import re
import signal
import subprocess
import sys

VERSIONS = os.path.expanduser("~/.local/share/claude/versions")
RUN = re.compile(r"(?:[A-Za-z][A-Za-z'’\-]*[,.;:!?]?\s+){21,}[A-Za-z][A-Za-z'’\-]*[.!?]?")


def resolve(arg: str) -> str:
    if os.path.exists(arg):
        return arg
    cand = os.path.join(VERSIONS, arg)
    if os.path.exists(cand):
        return cand
    sys.exit(f"not found: {arg}")


def runs(path: str) -> set[str]:
    with open(path, "rb") as f:
        head = f.read(4)
    if head[:2] == b"MZ" or head == b"\x7fELF" or head[:4] in (b"\xcf\xfa\xed\xfe", b"\xca\xfe\xba\xbe"):
        text = subprocess.run(["strings", path], capture_output=True, text=True, errors="replace").stdout
    else:
        text = open(path, errors="replace").read()
    # Per line: strings(1) emits one string per line, and a run that crossed two
    # unrelated strings would be noise.
    return {m.group(0).strip() for line in text.splitlines() for m in RUN.finditer(line)}


def main() -> None:
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    old = runs(resolve(sys.argv[1]))
    new = runs(resolve(sys.argv[2]))
    added: list[str] = sorted(new - old, key=lambda r: len(r), reverse=True)
    removed: list[str] = sorted(old - new, key=lambda r: len(r), reverse=True)
    print(f"runs: old={len(old)} new={len(new)} added={len(added)} removed={len(removed)}\n")
    print("=== ADDED in new ===")
    for s in added:
        print("+", s[:600], "\n")
    print("=== REMOVED from old ===")
    for s in removed:
        print("-", s[:600], "\n")


if __name__ == "__main__":
    main()
