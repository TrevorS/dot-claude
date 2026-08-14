---
name: maintaining-claude-code
description: Audit and improve Claude Code hooks, rules, and settings.json. Use when adding/debugging a hook, organizing rules, auditing settings.json (permissions, env vars, stale flags), or deciding between hook vs skill vs rule vs CLAUDE.md. For SKILL.md authoring use the skill-creator plugin; for CLAUDE.md audits use the claude-md-improver plugin.
when_to_use: "Typed as 'my hook is not firing', 'audit settings.json', 'should this be a hook or a skill', 'why does this keep prompting', or when adding a hook event, permission rule, or rules/ file."
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

**Backgrounded forks lose tools.** A fork left at the default `background: true` runs with the
background-subagent tool set: every MCP tool, but only `Read`, `Grep`, `Glob`, `Bash`, `PowerShell`,
`Edit`, `Write`, `NotebookEdit`, `WebFetch`, `WebSearch`, `TodoWrite`, `Skill`, `ToolSearch`,
`EnterWorktree`, `ExitWorktree`, `Monitor`, `TaskStop`, `SendMessage`, `Artifact`. Everything else is
stripped even if named in `tools`, so one definition resolves differently in foreground and
background — set `background: false` if a step needs a tool outside that set. (`Bash` is in it, so
`run_in_background` still works.) A backgrounded fork also writes outside session checkpoints, so
`/rewind` will not undo its edits; git is the undo layer. Claude Code waits for a fork regardless of
`background` under `-p`/the SDK, with `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`, when the same skill is
already running, or when a scheduled task fires it.

## Hooks

### Hook events

Per-session: `SessionStart`, `SessionEnd`, `Setup`
Per-turn: `UserPromptSubmit`, `UserPromptExpansion`, `Stop`, `StopFailure`
Per-tool: `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `PermissionDenied`, `PostToolBatch`
Async: `FileChanged`, `CwdChanged`, `DirectoryAdded`, `ConfigChange`, `InstructionsLoaded`, `WorktreeCreate`, `WorktreeRemove`, `Notification`, `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`, `PreCompact`, `PostCompact`, `TeammateIdle`, `Elicitation`, `ElicitationResult`, `MessageDisplay`

That is all 31 documented events (verified against the hooks reference, 2026-08-10).

### Exit codes

- `0` — success, continue
- `2` — block action; stderr is shown to Claude
- non-zero (other) — non-blocking warning

### Hook command forms

Shell form (classic): `"command": "shell command string"`
Exec form (avoids quoting issues): `"command": "program"` **plus** `"args": ["arg1", "arg2"]`.
The executable stays in `command`; setting `args` is what switches the hook to exec form, and
`command` is then resolved on `PATH` and spawned directly with no shell. Set `args` whenever the
hook references a path placeholder, since each element is passed as one argument with no quoting.

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

- Prompt cache: `UserPromptSubmit` context is **appended to each user message**, so a value that
  varies per turn costs nothing — it never invalidates an already-built prefix. (CLAUDE.md is
  likewise delivered as a user message after the system prompt.) The cached prefix is the tools
  array, system prompt, CLAUDE.md + eager rules + MEMORY.md, and the skill listing; only a change
  to *those* re-bills. `project-context.sh` emits a date rather than a clock for a different
  reason — a clock invites social commentary about the hour — not for caching.
  The pairing that does matter: `MCP_CONNECTION_NONBLOCKING=1` lets servers connect late, which
  would rewrite the tools array, except deferred tool loading keeps MCP tools out of it until
  `ToolSearch` pulls a schema into a tool result. Safe only while both hold.
- Hook script not executable: `chmod +x` and verify shebang.
- Reading stdin twice: drain once, parse from a variable.
- Forgetting `set -euo pipefail` in bash — but only for **gate** hooks. A gate
  (PreToolUse/TeammateIdle deciding exit 0 vs 2) must fail loudly, or it silently
  stops gating. An **output** hook (statusLine, UserPromptSubmit context injection,
  notifications) should stay fail-soft: under `set -e` one failing segment aborts
  the script before it prints anything, so a partial status line becomes no status
  line. In this repo the three guards under `hooks/` set it; `hooks/status.sh`,
  `hooks/user-prompt-submit/project-context.sh`, `hooks/session-title.sh`, and
  `hooks/stop-failure-notify.sh` deliberately do not.
  Don't "fix" those — the asymmetry is the design.

## Skills — frontmatter reference

`name`, `description`, `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`, `model`, `effort`, `context`, `agent`, `background`, `hooks`, `paths`, `shell`, `metadata`, `license`, `compatibility`.

The last three are accepted but inert in Claude Code: `metadata` is a free-form map for your own tooling (drops a value that is not a map), while `license` and `compatibility` come from the Agent Skills spec and are read by tools outside Claude Code.

`background` applies only with `context: fork` (default `true` since 2.1.218) — set `false` to wait for the result in the invoking turn. `effort` is unsupported on Haiku 4.5, so don't pair it with `model: claude-haiku-4-5`. For backgrounded fork skills, `disallowed-tools: AskUserQuestion` stops a question from parking as a needs-input request.

Dynamic context injection: an exclamation mark immediately followed by a
backtick-quoted command inlines that command's output before Claude sees skill
content. The multi-line form is a fenced code block whose info string is a bare
exclamation mark (three backticks, then `!`), one command per line.

Do **not** write either form literally in a skill body you don't want executed --
including inside an inline code span or a quoted example. The loader scans the raw
text for the trigger and runs it regardless of Markdown context, so a documented
example executes itself when the skill loads. Describe the delimiters in prose
instead, as above.

Variable substitutions: `$ARGUMENTS`, `$ARGUMENTS[N]`, `$N`, `$name`, `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}`, `${CLAUDE_SKILL_DIR}`, `${CLAUDE_PROJECT_DIR}`, and — in plugin skills only — `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PLUGIN_DATA}` (the latter survives plugin updates).

`${CLAUDE_SKILL_DIR}` and `${CLAUDE_PROJECT_DIR}` are substituted in **two** places: the skill body *and* Bash rules in `allowed-tools` (same for the two plugin variables in a plugin skill). Using the same variable in both is what lets a skill run its own bundled script without a permission prompt.

Visibility control in settings.json: `skillOverrides` — set per-skill to `on`, `name-only`, `user-invocable-only`, or `off`. This is the settings-side near-equivalent of frontmatter `disable-model-invocation` / `user-invocable`.

Default to frontmatter so the setting travels with the skill. **Exception — the two are not interchangeable:** `disable-model-invocation: true` *also* blocks the skill from being preloaded into subagents and (since 2.1.196) from running when a scheduled task fires with the skill as its prompt. `skillOverrides: "user-invocable-only"` suppresses auto-triggering without taking those away. So when a skill must stay reachable from a scheduled task or a subagent, use `skillOverrides`.

That is why `syncing-claude-config`, `cleaning-commit-history`, and `executing-test-plans` are pinned in `settings.json` rather than in their own frontmatter.

**Trigger evals and suppressed skills don't mix.** `user-invocable-only`, `name-only`, and `off` all stop a skill from auto-loading, so a trigger eval against one returns a flat 0.0 trigger rate — which reads as a broken description rather than a disabled skill. `scripts/run-trigger-eval.py` now refuses to run in that case (exit 2) and names the override; pass `--allow-disabled` to override. The three eval sets above are kept as-is on purpose: they describe what those skills *would* serve, so they become meaningful again the moment an override is dropped.

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
- **Hook wiring**: matcher *syntax* is uniform, but **the field it matches against varies by
  event** — tool name for `PreToolUse`/`PostToolUse`/`PermissionRequest`, start reason for
  `SessionStart`, notification type for `Notification`, error type for `StopFailure`, config
  source for `ConfigChange`, agent type for `SubagentStart`, literal filenames for `FileChanged`.
  `""`, `"*"`, or omitting the field all match everything; `"Write|Edit|Bash"` is the common
  write-side filter. Several events take no matcher at all and always fire.

## Audit a config

1. Validate YAML frontmatter on every SKILL.md and rules/*.md
2. Cross-check each `Skill(...)` and `mcp__...` permission rule against the installed plugins/servers
3. Strings-grep the claude binary for env vars and settings keys to flag dead ones
4. Test each hook script standalone with synthetic stdin before wiring
