---
name: syncing-claude-config
description: Sync this Claude Code config against new release notes — find config features added since the pinned baseline that this config should adopt. Use when Claude Code has been updated, when the user asks what's new / what changed / whether to adopt new settings or hooks, after a version bump, or when checking config currency against the latest release. Reports adoptable settings/hooks/env-vars/permissions as a risk-tiered proposal, then bumps the baseline. Do NOT use for auditing existing config quality, debugging hooks, or organizing rules — that is `maintaining-claude-code`.
argument-hint: "[check]"
---

# Syncing Claude Code Config

Diff this config against Claude Code release notes published since the pinned baseline, surface the config-relevant changes worth adopting, apply the ones Teej picks, and bump the baseline. The relevance filter is computed live each run — there is no hand-maintained catalog.

`check` (or a bare invocation) is **report-only**: never write to config or to `baseline.json` until Teej approves the proposal.

State lives in `~/.claude/skills/syncing-claude-config/baseline.json`:

```json
{ "claudeCodeVersion": "2.1.193", "syncedDate": "2026-06-25", "adopted": [...], "declined": [...] }
```

## Boundary

This skill answers *"what did new releases add that I'd want?"* — forward drift against release notes. It does **not** judge whether existing config is well-formed; hand any "is this edit correct / well-shaped" question to the `maintaining-claude-code` skill after applying.

## Workflow

### 1. Establish the version window

```bash
jq -r .claudeCodeVersion ~/.claude/skills/syncing-claude-config/baseline.json   # pinned baseline
claude --version                                                                 # installed
```

If installed == baseline, report `❨✓❩ Config targets <version> — up to date` and stop. Nothing to sync.

### 2. Fetch release notes for the window

Sync off the **releases API**, not `CHANGELOG.md` — it carries per-release `published_at` dates and clean record boundaries the markdown lacks.

```bash
gh api 'repos/anthropics/claude-code/releases?per_page=100' \
  --jq '.[] | {tag: .tag_name, date: .published_at, body: .body}'
```

Keep only releases whose `tag` (strip the `v`) is `>` the baseline version and `<=` installed. Each `body` is a flat markdown bullet list.

### 3. Pre-filter to config-relevant bullets (cheap, high-recall)

Most bullets are UI / streaming / MCP-reliability fixes with no config surface — drop them. Keep a bullet if it matches any of:

- An **env var**: `\b(CLAUDE_CODE_|CLAUDE_|ANTHROPIC_|OTEL_)[A-Z0-9_]+\b` — this pattern is ~100% precise; never drop one of these.
- A backtick token **plus** one of the words: `setting`, `settings.json`, `environment variable`, `env var`, `frontmatter`, `hook`, `permission`, `matcher`.
- A `dotted.camelCase` identifier in backticks (e.g. `sandbox.credentials`, `autoMode.classifyAllShell`).

Backticks are overloaded — slash commands (`/rewind`), tool names (`ExitWorktree`), CLI subcommands (`claude mcp login`), and UI strings are also backticked. Backtick-presence **alone** over-selects; require identifier *shape*, not just any backtick. Typical survivors: **0–2 bullets per release**, zero on patch-only releases.

### 4. Classify each survivor

For each surviving bullet, determine — reading the prose, not just the token:

- **Surface**: settings.json key · nested key · env var · hook event/matcher · skill frontmatter field · permission syntax · CLI-only (skip CLI-only).
- **Anchor**: the exact identifier(s) it adds/changes. Watch multi-anchor bullets (`display-name`, `default-enabled`, … in one line) and wildcards (`metadata.*`).
- **Change kind**: added · changed · deprecated/removed. A bullet can promote one key and deprecate another (`CLAUDE_CODE_MAX_RETRIES` → `CLAUDE_CODE_RETRY_WATCHDOG`).

### 5. Intersect with the live config — relevance = anchor ∩ usage

Read the current config and keep only changes that touch a surface Teej actually uses, or that he plausibly should:

```bash
jq 'keys' ~/.claude/settings.json                       # top-level keys
jq '.env | keys' ~/.claude/settings.json                # env vars in use
jq '.hooks | keys' ~/.claude/settings.json              # wired hook events
jq '.permissions' ~/.claude/settings.json               # allow/deny/ask
rg -l '^---' ~/.claude/skills/*/SKILL.md                # skill frontmatter surfaces
```

Demote, never delete: changes that don't intersect go into a collapsed **"other release changes"** bucket so nothing silently vanishes. Drop anything already in `baseline.json`'s `declined` list (don't re-nag).

### 6. Present the proposal (two-zone)

Lead with a scannable table, risk-tiered, safest first:

| Setting | Current → Proposed | Risk | Why |
| --- | --- | --- | --- |

Risk tiers:
- **additive-safe** — new optional key/flag, no behavior change. Candidate for quick approval.
- **behavioral** — changes how something already behaves. Propose; gate on Teej hitting the symptom.
- **breaking** — renamed/removed key in use. Always preview the before/after diff; never auto-apply.

Under each row, cite the **exact changelog line** that justifies it, with the version. Then the collapsed "other release changes" bucket. End with the version window covered and the bump that will be recorded.

### 7. Apply (only on approval)

For each accepted change, edit the real config (`~/.claude/settings.json`, hooks, skill frontmatter). Leave a self-documenting breadcrumb on non-obvious edits (e.g. `// added <key> — <version>: <one-line reason>`). One logical change per edit so git is the undo layer. After applying, hand the result to `maintaining-claude-code` for a well-formedness pass if any edit was non-trivial.

### 8. Bump the baseline

Update `~/.claude/skills/syncing-claude-config/baseline.json`: set `claudeCodeVersion` to installed, `syncedDate` to today (from the environment context, not a guess), append accepted changes to `adopted` (with the version that introduced them) and rejected ones to `declined`. The `declined` list is what stops the same proposal resurfacing next run.

## Notes

- Patch-only releases legitimately yield zero config changes — reporting "nothing to adopt" is a correct, expected outcome, not a failure.
- If the releases API is unreachable, fall back to `https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md` (same bullets, no dates).
- Never propose `enforceAvailableModels`, `requiredMinimumVersion`, or other managed/enterprise keys for this single-user config unless Teej asks — they target shared/managed deployments.
