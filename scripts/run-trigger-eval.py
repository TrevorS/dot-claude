#!/usr/bin/env python3
"""Run trigger evaluation for a skill description.

Fixed version that creates proper SKILL.md files in .claude/skills/
instead of command files in .claude/commands/ (which don't auto-trigger).
"""

import argparse
import json
import os
import select
import signal
import subprocess
import sys
import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from contextlib import contextmanager
from pathlib import Path


def find_project_root() -> Path:
    current = Path.cwd()
    for parent in [current, *current.parents]:
        if (parent / ".claude").is_dir():
            return parent
    return current


# Tools that cannot change anything. A session may call these while deciding
# whether to load a skill; any other tool call ends the run before it executes.
READ_ONLY_TOOLS = {"Skill", "Read", "Grep", "Glob", "ToolSearch"}


def kill_session(process: subprocess.Popen) -> None:
    """SIGKILL the claude process and every child it spawned (Bash, hooks)."""
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except (ProcessLookupError, PermissionError):
        pass
    process.wait()


def run_single_query(
    query: str,
    skill_name: str,
    skill_description: str,
    timeout: int,
    project_root: str,
    model: str | None = None,
    skill_path: str | None = None,
) -> bool:
    """Run a single query and return whether the skill was triggered.

    Detects triggering by looking for Skill tool calls matching the skill name.

    Each session is stopped at its first tool call outside READ_ONLY_TOOLS, at
    content_block_start, before the tool's input exists, and as soon as any
    Skill call resolves. Without that cutoff every query ran to completion with
    the user's real permissions: on 2026-09-18 a sweep in ~/.claude pushed a
    branch to origin, squashed local commits, and was mid-way through
    `linear-cli create` queries when it was killed.

    This function must NOT touch SKILL.md. The description swap happens once in
    the parent (see `swapped_description`) before any worker starts. It used to
    happen here, per worker, and that was a data-loss bug: `write_text` truncates
    before writing, so with N workers sharing one file a worker could read the
    empty window mid-write, store it as its `original_content`, and "restore"
    zero bytes at the end. It emptied skills/committing-changes/SKILL.md on
    2026-08-10.
    """
    cmd = [
        "claude",
        "-p", query,
        "--output-format", "stream-json",
        "--verbose",
        "--include-partial-messages",
    ]
    if model:
        cmd.extend(["--model", model])

    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        cwd=project_root,
        env=env,
        start_new_session=True,
    )
    assert process.stdout is not None  # stdout=PIPE

    skills_invoked: set[str] = set()
    got_output = False
    stopped_by = None
    exited = False
    start_time = time.time()
    buffer = ""
    pending_skill = False
    accumulated_json = ""

    try:
        while time.time() - start_time < timeout and stopped_by is None and not exited:
            if process.poll() is not None:
                remaining = process.stdout.read()
                if remaining:
                    buffer += remaining.decode("utf-8", errors="replace")
                exited = True
            else:
                ready, _, _ = select.select([process.stdout], [], [], 1.0)
                if not ready:
                    continue
                chunk = os.read(process.stdout.fileno(), 8192)
                if not chunk:
                    exited = True
                buffer += chunk.decode("utf-8", errors="replace")

            while "\n" in buffer and stopped_by is None:
                line, buffer = buffer.split("\n", 1)
                line = line.strip()
                if not line:
                    continue
                try:
                    event = json.loads(line)
                except json.JSONDecodeError:
                    continue

                etype = event.get("type")
                if etype == "stream_event":
                    got_output = True
                    se = event.get("event", {})
                    se_type = se.get("type", "")
                    if se_type == "content_block_start":
                        cb = se.get("content_block", {})
                        if cb.get("type") == "tool_use":
                            name = cb.get("name", "")
                            if name == "Skill":
                                pending_skill = True
                                accumulated_json = ""
                            elif name not in READ_ONLY_TOOLS:
                                # Input not streamed yet, so the tool cannot run.
                                stopped_by = name
                    elif se_type == "content_block_delta" and pending_skill:
                        delta = se.get("delta", {})
                        if delta.get("type") == "input_json_delta":
                            accumulated_json += delta.get("partial_json", "")
                    elif se_type == "content_block_stop" and pending_skill:
                        try:
                            skills_invoked.add(json.loads(accumulated_json).get("skill", ""))
                        except json.JSONDecodeError:
                            pass
                        pending_skill = False
                        stopped_by = "Skill"
                elif etype == "assistant":
                    got_output = True
                    for item in event.get("message", {}).get("content", []):
                        if item.get("type") == "tool_use" and item.get("name") == "Skill":
                            skills_invoked.add(item.get("input", {}).get("skill", ""))
                elif etype == "result":
                    got_output = True
                    stopped_by = "result"
    finally:
        kill_session(process)

    if not got_output:
        # Never reached the model (logged out, rate limited, crashed): fail loudly
        # instead of scoring a silent False that passes every negative case.
        raise RuntimeError("no model output")
    return any(skill_name in s for s in skills_invoked)


@contextmanager
def swapped_description(skill_file: Path, description: str):
    """Swap the frontmatter description for the duration of the block, once.

    Done in the parent process before any worker spawns, so the file is written
    exactly twice per run (swap, restore) regardless of worker count. Restores on
    any exit path, including KeyboardInterrupt and SIGTERM.
    """
    original = skill_file.read_text()

    lines = original.splitlines()
    new_lines = []
    in_frontmatter = False
    replaced = False
    for line in lines:
        if line.strip() == "---":
            in_frontmatter = not in_frontmatter
            new_lines.append(line)
            continue
        if in_frontmatter and line.startswith("description:") and not replaced:
            new_lines.append(f"description: {description}")
            replaced = True
        else:
            new_lines.append(line)
    # splitlines() drops the trailing newline; put it back so the swapped file
    # differs from the original in the description line and nothing else.
    trailing = "\n" if original.endswith("\n") else ""
    swapped = "\n".join(new_lines) + trailing

    def restore(*_):
        if skill_file.read_text() != original:
            skill_file.write_text(original)

    previous = {sig: signal.signal(sig, restore) for sig in (signal.SIGINT, signal.SIGTERM)}
    try:
        if swapped != original:
            skill_file.write_text(swapped)
        yield
    finally:
        restore()
        for sig, handler in previous.items():
            signal.signal(sig, handler)


def parse_skill_md(skill_path: Path) -> tuple[str, str, str]:
    text = (skill_path / "SKILL.md").read_text()
    if not text.startswith("---"):
        return skill_path.name, "", text
    end = text.index("---", 3)
    frontmatter = text[3:end]
    content = text[end + 3:].strip()
    name = skill_path.name
    description = ""
    for line in frontmatter.splitlines():
        if line.startswith("name:"):
            name = line.split(":", 1)[1].strip()
        elif line.startswith("description:"):
            description = line.split(":", 1)[1].strip()
    return name, description, content


def frontmatter_blocks_trigger(skill_file: Path) -> str | None:
    """Return a reason when SKILL.md frontmatter keeps the model from auto-invoking it."""
    try:
        text = skill_file.read_text()
    except OSError:
        return None
    if not text.startswith("---"):
        return None
    for line in text[3:text.find("---", 3)].splitlines():
        key, _, value = line.partition(":")
        if key == "disable-model-invocation" and value.strip() == "true":
            return "its frontmatter sets disable-model-invocation: true"
        if key == "paths":
            return "its frontmatter sets paths:, so it only loads when a matching file is touched"
    return None


def auto_trigger_disabled(skill_name: str, skill_path: Path) -> str | None:
    """Return a reason string when this skill cannot auto-trigger at all.

    Two independent causes, both of which produce a uniform 0.0 trigger rate that
    reads as a broken description rather than a disabled skill:

    1. `skillOverrides` set to user-invocable-only / name-only / off, or the
       frontmatter sets `disable-model-invocation: true` or `paths:` (a `claude -p`
       eval never touches a matching file, so a path-scoped skill never loads).
    2. The skill belongs to a plugin that is disabled in `enabledPlugins`.

    Guarding both is the difference between "your description needs work" and
    "this measurement was never capable of passing".
    """
    frontmatter_reason = frontmatter_blocks_trigger(skill_path / "SKILL.md")
    if frontmatter_reason:
        return frontmatter_reason

    settings = Path.home() / ".claude" / "settings.json"
    if not settings.exists():
        return None
    try:
        cfg = json.loads(settings.read_text())
    except (json.JSONDecodeError, OSError):
        return None

    mode = cfg.get("skillOverrides", {}).get(skill_name)
    if mode in ("user-invocable-only", "name-only", "off"):
        return f'settings.json skillOverrides sets it to "{mode}"'

    # Walk up for a plugin manifest, then check whether that plugin is enabled.
    for parent in [skill_path.resolve(), *skill_path.resolve().parents]:
        manifest = parent / ".claude-plugin" / "plugin.json"
        if not manifest.exists():
            continue
        try:
            plugin_name = json.loads(manifest.read_text()).get("name")
        except (json.JSONDecodeError, OSError):
            return None
        if not plugin_name:
            return None
        for key, enabled in cfg.get("enabledPlugins", {}).items():
            if key.split("@")[0] == plugin_name and enabled is False:
                return f'it belongs to plugin "{key}", which is disabled in enabledPlugins'
        return None
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--eval-set", required=True)
    parser.add_argument("--skill-path", required=True)
    parser.add_argument("--description", default=None)
    parser.add_argument("--num-workers", type=int, default=5)
    parser.add_argument("--timeout", type=int, default=60)
    parser.add_argument("--runs-per-query", type=int, default=1)
    parser.add_argument("--trigger-threshold", type=float, default=0.5)
    parser.add_argument("--model", default=None)
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument(
        "--allow-disabled",
        action="store_true",
        help="run even when skillOverrides blocks auto-triggering (results will be all-zero)",
    )
    args = parser.parse_args()

    eval_set = json.loads(Path(args.eval_set).read_text())
    skill_path = Path(args.skill_path)
    name, original_description, _ = parse_skill_md(skill_path)
    description = args.description or original_description
    project_root = find_project_root()

    blocked = auto_trigger_disabled(name, skill_path)
    if blocked and not args.allow_disabled:
        print(
            f"refusing to run: `{name}` cannot auto-trigger ({blocked}), so every\n"
            f"should_trigger=true case is guaranteed to fail and the result says\n"
            f"nothing about description quality.\n\n"
            f"Fix one of:\n"
            f"  - re-enable the skill (drop the skillOverrides entry, or\n"
            f"    `claude plugin enable <plugin>`) if it is meant to auto-trigger\n"
            f"  - set every should_trigger to false in {args.eval_set}\n"
            f"  - pass --allow-disabled to measure the description anyway",
            file=sys.stderr,
        )
        return 2

    if args.verbose:
        print(f"Evaluating: {description}", file=sys.stderr)

    results: list[dict] = []
    query_triggers: dict[str, list[bool]] = {}
    query_items: dict[str, dict] = {}

    # Swap once, in the parent, around the whole pool — never per worker.
    with swapped_description(skill_path / "SKILL.md", description):
        with ProcessPoolExecutor(max_workers=args.num_workers) as executor:
            future_to_info = {}
            for item in eval_set:
                for run_idx in range(args.runs_per_query):
                    future = executor.submit(
                        run_single_query,
                        item["query"],
                        name,
                        description,
                        args.timeout,
                        str(project_root),
                        args.model,
                        str(skill_path),
                    )
                    future_to_info[future] = (item, run_idx)

            for future in as_completed(future_to_info):
                item, _ = future_to_info[future]
                q = item["query"]
                query_items[q] = item
                if q not in query_triggers:
                    query_triggers[q] = []
                try:
                    query_triggers[q].append(future.result())
                except Exception as e:
                    print(f"Warning: {e}", file=sys.stderr)

    for q, triggers in query_triggers.items():
        item = query_items[q]
        should = item["should_trigger"]
        if not triggers:
            results.append({"query": q, "should_trigger": should, "trigger_rate": None,
                            "triggers": 0, "runs": 0, "pass": False, "error": True})
            continue
        rate = sum(triggers) / len(triggers)
        passed = rate >= args.trigger_threshold if should else rate < args.trigger_threshold
        results.append({
            "query": q,
            "should_trigger": should,
            "trigger_rate": rate,
            "triggers": sum(triggers),
            "runs": len(triggers),
            "pass": passed,
        })

    output = {
        "skill_name": name,
        "description": description,
        "results": results,
        "summary": {
            "total": len(results),
            "passed": sum(1 for r in results if r["pass"]),
            "failed": sum(1 for r in results if not r["pass"] and not r.get("error")),
            "errors": sum(1 for r in results if r.get("error")),
        },
    }

    if args.verbose:
        s = output["summary"]
        print(f"Results: {s['passed']}/{s['total']} passed", file=sys.stderr)
        for r in output["results"]:
            status = "ERROR" if r.get("error") else ("PASS" if r["pass"] else "FAIL")
            print(f"  [{status}] rate={r['triggers']}/{r['runs']} expected={r['should_trigger']}: {r['query'][:70]}", file=sys.stderr)

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    sys.exit(main() or 0)
