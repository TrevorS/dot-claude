#!/usr/bin/env python3
"""PostToolUse hook: flag AI-slop words in docs, commits, and PRs.

These words aren't categorically forbidden — they show up in legitimate prose.
But when they appear in generated content (docs, commit messages, PR bodies),
they often signal vapid AI-speak: "leverage", "robust", "seamless" stacking
into vacuous filler. This hook surfaces them informationally so the model can
re-read and ask "is this word earning its keep, or am I padding with
buzzwords?" — not to block or fail the tool call.

Output: emits `hookSpecificOutput.additionalContext` so the suggestion lands
as context for the next turn, not as a tool failure.
"""

import json
import re
import sys
from pathlib import Path

FENCED_CODE_BLOCK = re.compile(
    r"^(?P<fence>`{3,}|~{3,}).*?\n.*?^(?P=fence)\s*$",
    re.MULTILINE | re.DOTALL,
)

# Words that flag vapid AI-speak when they show up in generated prose.
# Not categorically forbidden — flagged for a sanity check that the word is
# doing real work rather than padding.
FLAGGED_WORDS = [
    "leverage", "robust", "streamline", "comprehensive", "utilize",
    "facilitate", "seamless", "ensure", "enhance", "cutting-edge",
    "holistic", "delve", "pivotal", "foster", "elevate",
    "bolster", "cornerstone", "realm", "tapestry", "landscape",
    "multifaceted", "intricate", "meticulous", "endeavor", "testament",
    "paramount", "furthermore", "moreover", "notably", "essentially",
    "fundamentally", "encompasses", "empower", "synergy", "spearhead",
    "amplify", "orchestrate", "architected", "scalable", "innovative",
    "optimal", "proactive", "ecosystem", "additionally", "subsequently",
    "consequently", "accordingly", "nonetheless", "underscore", "embark",
    "navigate", "unpack", "uncover", "unveil", "unlock", "unleash",
    "revolutionize", "cultivate", "ascertain", "garner", "exemplify",
    "resonate", "transcend", "groundbreaking", "transformative",
    "unprecedented", "nuanced", "dynamic", "vibrant", "profound",
    "compelling", "state-of-the-art", "bespoke", "mission-critical",
    "unwavering", "paradigm", "interplay", "beacon", "crucible",
    "labyrinth", "mosaic", "underpinnings", "frontier", "game-changer",
    "disruptive", "world-class", "renowned", "breathtaking",
]

DOC_EXTENSIONS = {".md", ".txt", ".rst", ".mdx", ".adoc"}
TEMP_MSG_PATTERNS = re.compile(r"(commit|msg|message|pr[-_]body)", re.IGNORECASE)

JJ_MSG = re.compile(
    r"""jj\s+(?:describe|commit|squash|new)\s+.*?-m\s+(['"])(.*?)\1""",
    re.DOTALL,
)
GIT_MSG_FLAG = re.compile(
    r"""git\s+commit\s+.*?-m\s+(['"])(.*?)\1""",
    re.DOTALL,
)
GIT_MSG_HEREDOC = re.compile(
    r"""git\s+commit\s+.*?-m\s+"\$\(cat\s+<<'?EOF'?\s*\n(.*?)\nEOF""",
    re.DOTALL,
)
GIT_MSG_FILE = re.compile(r"""git\s+commit\s+.*?-F\s+(\S+)""")
GH_PR_TITLE = re.compile(
    r"""gh\s+pr\s+create\s+.*?--title\s+(['"])(.*?)\1""",
    re.DOTALL,
)
GH_PR_BODY = re.compile(
    r"""gh\s+pr\s+create\s+.*?--body\s+['"]?\$\(cat\s+<<'?EOF'?\s*\n(.*?)\nEOF""",
    re.DOTALL,
)
GH_PR_BODY_SIMPLE = re.compile(
    r"""gh\s+pr\s+create\s+.*?--body\s+(['"])(.*?)\1""",
    re.DOTALL,
)


def build_pattern(words: list[str]) -> re.Pattern | None:
    if not words:
        return None
    escaped = [re.escape(w) for w in words]
    return re.compile(r"\b(" + "|".join(escaped) + r")\b", re.IGNORECASE)


def strip_fenced_code_blocks(text: str) -> str:
    return FENCED_CODE_BLOCK.sub("", text)


def find_flagged(text: str, pattern: re.Pattern) -> list[str]:
    prose = strip_fenced_code_blocks(text)
    matches = pattern.findall(prose)
    seen = set()
    result = []
    for m in matches:
        lower = m.lower()
        if lower not in seen:
            seen.add(lower)
            result.append(lower)
    return result


def is_doc_file(file_path: str) -> bool:
    p = Path(file_path)
    if p.suffix.lower() in DOC_EXTENSIONS:
        return True
    if TEMP_MSG_PATTERNS.search(p.name):
        return True
    return False


def extract_bash_text(command: str) -> str:
    chunks = []

    for match in JJ_MSG.finditer(command):
        chunks.append(match.group(2))

    for match in GIT_MSG_HEREDOC.finditer(command):
        chunks.append(match.group(1))

    if not chunks:
        for match in GIT_MSG_FLAG.finditer(command):
            chunks.append(match.group(2))

    for match in GIT_MSG_FILE.finditer(command):
        path = match.group(1)
        try:
            chunks.append(Path(path).read_text())
        except (FileNotFoundError, PermissionError):
            pass

    for match in GH_PR_BODY.finditer(command):
        chunks.append(match.group(1))

    if not any("pr" in c for c in chunks):
        for match in GH_PR_BODY_SIMPLE.finditer(command):
            chunks.append(match.group(2))

    for match in GH_PR_TITLE.finditer(command):
        chunks.append(match.group(2))

    return "\n".join(chunks)


def main() -> None:
    hook_input = json.load(sys.stdin)
    tool_name = hook_input.get("tool_name", "")
    tool_input = hook_input.get("tool_input", {})

    pattern = build_pattern(FLAGGED_WORDS)
    if pattern is None:
        return

    text_to_check = ""

    if tool_name == "Write":
        file_path = tool_input.get("file_path", "")
        if is_doc_file(file_path):
            text_to_check = tool_input.get("content", "")

    elif tool_name == "Edit":
        file_path = tool_input.get("file_path", "")
        if is_doc_file(file_path):
            text_to_check = tool_input.get("new_string", "")

    elif tool_name == "Bash":
        command = tool_input.get("command", "")
        text_to_check = extract_bash_text(command)

    if not text_to_check:
        return

    flagged = find_flagged(text_to_check, pattern)
    if not flagged:
        return

    word_list = ", ".join(f'"{w}"' for w in flagged)
    suggestion = (
        f"Heads up — the prose you just wrote contains {word_list}. "
        "These words aren't forbidden, but they often signal vapid AI-speak "
        "when they show up in generated content. Re-read the affected section "
        "and ask whether each instance is doing real work or padding with "
        "buzzwords; plain, direct language usually reads better. "
        "(Full list: hooks/flagged-words.py.)"
    )
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": suggestion,
            },
        },
        sys.stdout,
    )


if __name__ == "__main__":
    main()
