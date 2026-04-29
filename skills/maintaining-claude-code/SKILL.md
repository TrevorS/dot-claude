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
| Heavy isolated workflow | **Skill with `context: fork`** |
| Always-on behavioral guidance | **CLAUDE.md** (use claude-md-improver) |
| Path-specific rules | **rules/** with `paths:` frontmatter |
| External integration | **MCP server** |

## Hooks

### Events you'll actually use

- `PreToolUse` — block/allow a tool call (exit 2 to block, write to stderr)
- `PostToolUse` — react to a completed tool call; can inject `additionalContext`
- `UserPromptSubmit` — inject context on every prompt (rounded timestamps to preserve prompt cache)
- `Stop` / `Notification` — desktop or audio notifications
- `PostCompact` — log compaction events
- `SessionStart` / `SubagentStop` — pre-load context or capture subagent output

### Exit codes

- `0` — success, continue
- `2` — block action; stderr is shown to Claude
- non-zero (other) — non-blocking warning

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

### Common pitfalls

- Cache busting: minute-precision timestamps in `UserPromptSubmit` invalidate prompt cache. Round to the hour.
- Hook script not executable: `chmod +x` and verify shebang.
- Reading stdin twice: drain once, parse from a variable.
- Forgetting `set -euo pipefail` in bash — silent failures otherwise.

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
