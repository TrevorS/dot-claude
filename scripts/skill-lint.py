#!/usr/bin/env -S uv run --script
"""
Static correctness checks for SKILL.md files and the always-on rules.

Usage:
    scripts/skill-lint.py [paths...]      # defaults to every SKILL.md in the repo

Complements the LLM trigger evals, which only exercise a skill's *description*.
These assertions cover the skill *body* — the layer where a wrong flag or an
inverted revset ships silently because nothing ever executes the snippet.

Every rule below encodes a bug that was actually found in this repo on
2026-08-10, so a regression is a real regression, not a style opinion.

Exits 0 when clean, 1 when any check fails.
"""

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

# --- rules -----------------------------------------------------------------
# Each: (id, compiled pattern, message). Matched per-line against SKILL.md
# bodies and rules/*.md.

BANNED = [
    (
        "jj-parent-revset-stack",
        re.compile(r"jj\s+new\s+[A-Za-z0-9._/-]+-(?:\s|$)"),
        "`jj new <name>-` branches off the PARENT of <name> (`x-` is the parents "
        "revset), creating a sibling instead of stacking on top. Drop the trailing "
        "hyphen.",
    ),
    (
        "jj-bookmark-set-to",
        re.compile(r"jj\s+bookmark\s+set\b[^\n]*--to\b"),
        "`jj bookmark set` takes -r/--revision; `--to` belongs to `jj bookmark move`.",
    ),
    (
        "jj-split-interactive-claim",
        re.compile(r"jj split is interactive|split is interactive, avoid", re.I),
        "`jj split` has a non-interactive form (paths + -m), which "
        "hooks/jj_interactive_guard.sh explicitly allows. Claiming otherwise "
        "contradicts rules/version-control.md.",
    ),
    (
        "gh-body-heredoc",
        re.compile(r"gh\s+(?:pr|issue)\s+create\b[^\n]*<<"),
        "Build gh bodies with the Write tool + --body-file. Heredocs are banned by "
        "CLAUDE.md and break on nested quotes.",
    ),
    (
        "tmp-scratch-path",
        # Only a *write* to /tmp is a problem. Reading or displaying a file that
        # happens to live there is fine, so require a write-ish operator.
        re.compile(
            r"(?:>\s*|-F\s+|-o\s+|--body-file\s+|--output\s+|tee\s+|cp\s+\S+\s+)"
            r"/tmp/(?!\{)"
        ),
        "Write temp files to the session scratchpad directory, not /tmp (CLAUDE.md). "
        "Long-lived cross-session sentinels are the exception — mark them with a "
        "'{' placeholder.",
    ),
]

# Files exempt from a given rule, with the reason.
EXEMPT: dict[str, set[str]] = {
    # Documents the wrong forms in order to ban them.
    "jj-parent-revset-stack": {"skills/using-jj/SKILL.md"},
    "jj-bookmark-set-to": {"rules/version-control.md"},
}


def iter_targets(argv: list[str]) -> list[Path]:
    if argv:
        return [Path(a).resolve() for a in argv]
    return sorted(
        [*REPO.glob("skills/*/SKILL.md")]
        + [*REPO.glob(".claude/skills/*/SKILL.md")]
        + [*REPO.glob("teej-skills/skills/*/SKILL.md")]
        + [*REPO.glob("rules/*.md")]
    )


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO))
    except ValueError:
        return str(path)


def frontmatter(text: str) -> dict[str, str]:
    """Parse the top-level scalar keys of a --- delimited YAML block."""
    if not text.startswith("---\n"):
        return {}
    end = text.find("\n---\n", 3)
    if end == -1:
        return {}
    out = {}
    for line in text[4:end].splitlines():
        m = re.match(r"^([a-zA-Z][\w-]*):\s*(.*)$", line)
        if m:
            out[m.group(1)] = m.group(2).strip()
    return out


def check_banned(path: Path, text: str) -> list[str]:
    failures = []
    name = rel(path)
    in_fence = False
    for lineno, line in enumerate(text.splitlines(), 1):
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
        for rule_id, pattern, message in BANNED:
            if name in EXEMPT.get(rule_id, set()):
                continue
            if pattern.search(line):
                failures.append(f"{name}:{lineno} [{rule_id}] {message}\n    > {line.strip()}")
    return failures


def check_links(path: Path, text: str) -> list[str]:
    """Every relative markdown link and backticked repo path must resolve."""
    failures = []
    name = rel(path)
    skill_dir = path.parent

    for lineno, raw in enumerate(text.splitlines(), 1):
        # Strip inline code spans first — docs quote broken/illustrative markup
        # inside backticks on purpose (see rules/status-marks.md anti-patterns).
        line = re.sub(r"``.+?``|`[^`]*`", "", raw)

        for target in re.findall(r"\]\(([^)]+)\)", line):
            if re.match(r"^(https?:|mailto:|#)", target):
                continue
            resolved = (skill_dir / target.split("#")[0]).resolve()
            if not resolved.exists():
                failures.append(f"{name}:{lineno} [dead-link] {target} does not resolve")

        # Backticked repo-root paths, e.g. `rules/pr-safety.md`. Uses `raw`
        # because these live *inside* the code spans stripped above.
        for target in re.findall(r"`((?:rules|references|hooks|scripts)/[\w./-]+)`", raw):
            if not (REPO / target).exists():
                failures.append(f"{name}:{lineno} [dead-ref] {target} does not exist")
    return failures


def check_frontmatter(path: Path, text: str) -> list[str]:
    failures = []
    name = rel(path)
    if path.name != "SKILL.md":
        return failures

    fm = frontmatter(text)
    if not fm:
        return [f"{name}:1 [frontmatter] missing or malformed --- block"]

    if "description" not in fm:
        failures.append(f"{name}:1 [frontmatter] missing required `description`")

    declared = fm.get("name")
    actual = path.parent.name
    if declared and declared != actual:
        failures.append(
            f"{name}:1 [frontmatter] name `{declared}` != directory `{actual}`; "
            "the invoked command comes from the directory"
        )

    # `background` only has meaning on a forked skill.
    if "background" in fm and fm.get("context") != "fork":
        failures.append(
            f"{name}:1 [frontmatter] `background` applies only with `context: fork`"
        )

    # A forked skill runs detached; a question there parks as needs-input.
    if fm.get("context") == "fork" and fm.get("background", "true") != "false":
        if "AskUserQuestion" not in fm.get("disallowed-tools", ""):
            failures.append(
                f"{name}:1 [frontmatter] backgrounded fork skill should set "
                "`disallowed-tools: AskUserQuestion` so a question cannot park the run"
            )
    return failures


def check_evals(path: Path) -> list[str]:
    if path.name != "SKILL.md":
        return []
    evals = path.parent / "evals"
    if not evals.is_dir() or not any(evals.iterdir()):
        return [f"{rel(path)}:1 [evals] no evals/ directory"]
    return []


def main() -> int:
    targets = iter_targets(sys.argv[1:])
    failures: list[str] = []

    for path in targets:
        text = path.read_text(encoding="utf-8")
        failures += check_banned(path, text)
        failures += check_links(path, text)
        failures += check_frontmatter(path, text)
        failures += check_evals(path)

    if failures:
        print(f"skill-lint: {len(failures)} problem(s) in {len(targets)} file(s)\n")
        for f in failures:
            print(f"  {f}")
        return 1

    print(f"skill-lint: {len(targets)} files clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
