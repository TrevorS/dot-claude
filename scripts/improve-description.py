#!/usr/bin/env python3
"""Improve a skill description using the Agent SDK (works with OAuth auth).

Replaces the skill-creator's improve_description.py which requires a raw API key.
Uses claude agent SDK to call claude -p under the hood, leveraging native OAuth.
"""

import argparse
import json
import re
import sys
from pathlib import Path

import anyio
from claude_agent_sdk import query, ClaudeAgentOptions, ResultMessage


def build_prompt(
    skill_name: str,
    skill_content: str,
    current_description: str,
    eval_results: dict,
    history: list[dict],
) -> str:
    failed_triggers = [
        r for r in eval_results["results"] if r["should_trigger"] and not r["pass"]
    ]
    false_triggers = [
        r for r in eval_results["results"] if not r["should_trigger"] and not r["pass"]
    ]

    score = f"{eval_results['summary']['passed']}/{eval_results['summary']['total']}"

    prompt = f"""You are optimizing a skill description for a Claude Code skill called "{skill_name}".

The description appears in Claude's "available_skills" list. Claude decides whether to invoke the skill based solely on this description. Write a description that triggers for relevant queries and doesn't trigger for irrelevant ones.

Current description:
"{current_description}"

Current score: {score}

"""
    if failed_triggers:
        prompt += "FAILED TO TRIGGER (should have triggered but didn't):\n"
        for r in failed_triggers:
            prompt += f'  - "{r["query"]}" (triggered {r["triggers"]}/{r["runs"]} times)\n'
        prompt += "\n"

    if false_triggers:
        prompt += "FALSE TRIGGERS (triggered but shouldn't have):\n"
        for r in false_triggers:
            prompt += f'  - "{r["query"]}" (triggered {r["triggers"]}/{r["runs"]} times)\n'
        prompt += "\n"

    if history:
        prompt += "PREVIOUS ATTEMPTS (try something structurally different):\n"
        for h in history:
            s = f"{h.get('passed', 0)}/{h.get('total', 0)}"
            prompt += f'  Score {s}: "{h["description"]}"\n'
        prompt += "\n"

    prompt += f"""Skill content (for context):
{skill_content[:2000]}

Write a new description (100-200 words max, under 1024 chars). Focus on user intent, not implementation. Be "pushy" — describe when to trigger broadly. Use imperative form.

Respond with ONLY the new description text wrapped in <new_description> tags."""

    return prompt


async def improve(
    skill_name: str,
    skill_content: str,
    current_description: str,
    eval_results: dict,
    history: list[dict],
) -> str:
    prompt = build_prompt(
        skill_name, skill_content, current_description, eval_results, history
    )

    result_text = ""
    async for message in query(
        prompt=prompt,
        options=ClaudeAgentOptions(max_turns=1),
    ):
        if isinstance(message, ResultMessage):
            result_text = message.result

    match = re.search(r"<new_description>(.*?)</new_description>", result_text, re.DOTALL)
    return match.group(1).strip().strip('"') if match else result_text.strip().strip('"')


def parse_skill_md(skill_path: Path) -> tuple[str, str, str]:
    text = (skill_path / "SKILL.md").read_text()
    if not text.startswith("---"):
        return skill_path.name, "", text

    end = text.index("---", 3)
    frontmatter = text[3:end]
    content = text[end + 3 :].strip()

    name = skill_path.name
    description = ""
    for line in frontmatter.splitlines():
        if line.startswith("name:"):
            name = line.split(":", 1)[1].strip()
        elif line.startswith("description:"):
            description = line.split(":", 1)[1].strip()

    return name, description, content


async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--skill-path", required=True)
    parser.add_argument("--eval-results", required=True)
    parser.add_argument("--history", default=None)
    args = parser.parse_args()

    skill_path = Path(args.skill_path)
    name, _, content = parse_skill_md(skill_path)
    eval_results = json.loads(Path(args.eval_results).read_text())
    history = json.loads(Path(args.history).read_text()) if args.history else []

    current_description = eval_results["description"]
    new_description = await improve(
        name, content, current_description, eval_results, history
    )

    output = {
        "description": new_description,
        "history": history
        + [
            {
                "description": current_description,
                "passed": eval_results["summary"]["passed"],
                "total": eval_results["summary"]["total"],
            }
        ],
    }
    print(json.dumps(output, indent=2))


anyio.run(main)
