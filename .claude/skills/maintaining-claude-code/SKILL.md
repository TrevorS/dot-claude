---
name: maintaining-claude-code
description: Audit and improve Claude Code hooks, rules, and settings.json. Use when adding/debugging a hook, organizing rules, auditing settings.json (permissions, env vars, stale flags), or deciding between hook vs skill vs rule vs CLAUDE.md. For SKILL.md authoring use the skill-creator plugin; for CLAUDE.md audits use the claude-md-improver plugin.
---

# Maintaining Claude Code

Covers hooks, rules, settings.json, and the entity-type decision tree. Delegates to plugins for the things they do better.

## Entity-type decision

Pick the right home before writing anything:

| Need | Use |
| --- | --- |
| Run automatically before/after a tool call | **Hook** |
| Auto-detected capability for a recurring task | **Skill** (use skill-creator) |
| Heavy isolated workflow, environment-driven | **Skill with `context: fork`** (see caveat) |
| Always-on behavioral guidance | **CLAUDE.md** (use claude-md-improver) |
| Path-specific rules | **rules/** with `paths:` frontmatter |
| External integration | **MCP server** |

**`context: fork` caveat:** a forked skill is isolated from the conversation **and** does not receive the user's message as `$ARGUMENTS` on auto-trigger (only an explicit `/skill <args>` invocation passes them). So use fork only for **environment-driven** work that reads everything from cwd/git/CI (validate, monitor CI, clean history). For any **input-dependent** skill — one that needs the user's words (a search query, an issue title, a plan path) — keep it **inline**, or it will fire with an empty query and bounce the question back. If a forked skill keeps asking "what would you like to search for?", this is why.

## Hooks

### Hook events

Per-session: `SessionStart`, `SessionEnd`, `Setup`
Per-turn: `UserPromptSubmit`, `UserPromptExpansion`, `Stop`, `StopFailure`
Per-tool: `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `PermissionDenied`, `PostToolBatch`
Async: `FileChanged`, `CwdChanged`, `ConfigChange`, `InstructionsLoaded`, `WorktreeCreate`, `WorktreeRemove`, `Notification`, `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`, `PreCompact`, `PostCompact`, `TeammateIdle`, `Elicitation`, `ElicitationResult`, `MessageDisplay`

### Exit codes

- `0` — success, continue
- `2` — block action; stderr is shown to Claude
- non-zero (other) — non-blocking warning

### Hook command forms

Shell form (classic): `"command": "shell command string"`
Exec form (new, avoids quoting issues): `"args": ["program", "arg1", "arg2"]`

### Output shape

Inject context with JSON on stdout:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "<EventName>",
    "additionalContext": "..."
  }
}
```

Additional output fields: `updatedToolOutput` (replace tool output, all tools), `terminalSequence` (emit OSC sequences for desktop notifications), `sessionTitle` (set session title, SessionStart only), `reloadSkills: true` (re-scan skill dirs, SessionStart only). `duration_ms` is now included in hook input for all tool events.

### Common pitfalls

- Cache busting: minute-precision timestamps in `UserPromptSubmit` invalidate prompt cache. Round to the hour.
- Hook script not executable: `chmod +x` and verify shebang.
- Reading stdin twice: drain once, parse from a variable.
- Forgetting `set -euo pipefail` in bash — silent failures otherwise.

## Skills — frontmatter reference

`name`, `description`, `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`, `model`, `effort`, `context`, `agent`, `background`, `hooks`, `paths`, `shell`.

`background` applies only with `context: fork` (default `true` since 2.1.218) — set `false` to wait for the result in the invoking turn. `effort` is unsupported on Haiku 4.5, so don't pair it with `model: claude-haiku-4-5`. For backgrounded fork skills, `disallowed-tools: AskUserQuestion` stops a question from parking as a needs-input request.

Dynamic context injection: `` !`command` `` inlines command output before Claude sees skill content. Multi-line: `` ```! \n cmd \n ``` ``.

Variable substitutions: `$ARGUMENTS`, `$ARGUMENTS[N]`, `$N`, `$name`, `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}`, `${CLAUDE_SKILL_DIR}`.

Visibility control in settings.json: `skillOverrides` — set per-skill to `on`, `name-only`, `user-invocable-only`, or `off`. This is the settings-side near-equivalent of frontmatter `disable-model-invocation` / `user-invocable`.

Default to frontmatter so the setting travels with the skill. **Exception — the two are not interchangeable:** `disable-model-invocation: true` *also* blocks the skill from being preloaded into subagents and (since 2.1.196) from running when a scheduled task fires with the skill as its prompt. `skillOverrides: "user-invocable-only"` suppresses auto-triggering without taking those away. So when a skill must stay reachable from a scheduled task or a subagent, use `skillOverrides`.

That is why `syncing-claude-config`, `cleaning-commit-history`, and `executing-test-plans` are pinned in `settings.json` rather than in their own frontmatter.

## Rules

`.claude/rules/*.md` files. Each can have `paths:` frontmatter to load only when matching files are touched. Smaller, narrower files load less context per session.

```yaml
---
paths:
  - "**/*.py"
---
# Python
- guidance...
```

When to keep something in CLAUDE.md instead: cross-cutting interaction style, project-wide commands, or rules that apply regardless of file path.

## Settings.json

Audit checklist:

- **Env vars**: verify each is referenced in the current claude binary (`strings ~/.local/share/claude/versions/<v> | grep VAR`). Undocumented does not mean dead — many flags are intentionally unlisted.
- **Permissions**: prefer narrow over broad. `Bash(<cmd>:*)` allows everything; `Bash(<cmd> <safe-args>)` is tighter. Always carry a deny list for secrets (`~/.ssh/**`, `**/*.pem`, `~/.env*`).
- **Plugin allow rules**: `Skill(<plugin-name>)` must match the actual plugin/skill identifier; typos silently fail.
- **Hook wiring**: matchers are regex against tool names — `""` matches all, `"Write|Edit|Bash"` is the common write-side filter.

## Audit a config

1. Validate YAML frontmatter on every SKILL.md and rules/*.md
2. Cross-check each `Skill(...)` and `mcp__...` permission rule against the installed plugins/servers
3. Strings-grep the claude binary for env vars and settings keys to flag dead ones
4. Test each hook script standalone with synthetic stdin before wiring
