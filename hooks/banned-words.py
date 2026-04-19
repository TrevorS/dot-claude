#!/usr/bin/env python3
"""PostToolUse hook: flag banned AI-slop words in docs, commits, and PRs.

Checks Write/Edit tool calls for doc-like files and Bash commands that
carry commit messages or PR descriptions. Emits a suggestion via stderr
(exit 2) so Claude can rewrite; does not block the tool call.

The word list is embedded below (was previously in rules/banned-words.md,
removed to cut ~420 tokens of per-session context).
"""

import json
import re
import sys
from pathlib import Path

# Regex to match fenced code blocks (``` or ~~~) so we can skip them
FENCED_CODE_BLOCK = re.compile(
    r"^(?P<fence>`{3,}|~{3,}).*?\n.*?^(?P=fence)\s*$",
    re.MULTILINE | re.DOTALL,
)

BANNED_WORDS = [
    "leverage", "robust", "streamline", "comprehensive", "utilize",
    "facilitate", "seamless", "ensure", "enhance", "cutting-edge",
    "holistic", "delve", "harness", "pivotal", "foster", "elevate",
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

# Patterns for extracting message text from Bash commands
# jj describe/commit/squash/new -m "..."
JJ_MSG = re.compile(
    r"""jj\s+(?:describe|commit|squash|new)\s+.*?-m\s+(['"])(.*?)\1""",
    re.DOTALL,
)
# git commit -m "..." or git commit -m "$(cat <<'EOF' ... EOF)"
GIT_MSG_FLAG = re.compile(
    r"""git\s+commit\s+.*?-m\s+(['"])(.*?)\1""",
    re.DOTALL,
)
GIT_MSG_HEREDOC = re.compile(
    r"""git\s+commit\s+.*?-m\s+"\$\(cat\s+<<'?EOF'?\s*\n(.*?)\nEOF""",
    re.DOTALL,
)
# git commit -F <path>
GIT_MSG_FILE = re.compile(r"""git\s+commit\s+.*?-F\s+(\S+)""")
# gh pr create --title "..." --body "..."
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
    """Build a compiled regex that matches any banned word at word boundaries."""
    if not words:
        return None
    escaped = [re.escape(w) for w in words]
    return re.compile(r"\b(" + "|".join(escaped) + r")\b", re.IGNORECASE)


def strip_fenced_code_blocks(text: str) -> str:
    """Remove fenced code blocks so their contents aren't checked."""
    return FENCED_CODE_BLOCK.sub("", text)


def find_violations(text: str, pattern: re.Pattern) -> list[str]:
    """Return deduplicated list of banned words found in prose (outside code blocks)."""
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
    """Check if a file path looks like documentation or a temp commit message."""
    p = Path(file_path)
    if p.suffix.lower() in DOC_EXTENSIONS:
        return True
    if TEMP_MSG_PATTERNS.search(p.name):
        return True
    return False


def extract_bash_text(command: str) -> str:
    """Extract message text from known Bash command patterns."""
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

    pattern = build_pattern(BANNED_WORDS)
    if pattern is None:
        json.dump(hook_input, sys.stdout)
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
        json.dump(hook_input, sys.stdout)
        return

    violations = find_violations(text_to_check, pattern)
    if not violations:
        json.dump(hook_input, sys.stdout)
        return

    word_list = ", ".join(f'"{w}"' for w in violations)
    print(
        f"Suggestion: found banned AI-slop words: {word_list}. "
        "Consider rewriting using plain, direct language "
        "(edit the file or amend the commit/PR message). "
        "See hooks/banned-words.py for the full list.",
        file=sys.stderr,
    )
    sys.exit(2)


if __name__ == "__main__":
    main()
