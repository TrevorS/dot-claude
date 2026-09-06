---
name: syncing-claude-config
description: Sync this Claude Code config against the shipped product — find config features added since the pinned baseline that this config should adopt, and audit silently-validating surfaces (themes, settings) for keys that are missing, dropped, or invalid. Use when Claude Code has been updated, when the user asks what's new / what changed / whether to adopt new settings or hooks, after a version bump, when checking config currency, or when a custom theme or settings block looks stale or isn't taking effect. Reports adoptable settings/hooks/env-vars/permissions plus schema drift as a risk-tiered proposal, then bumps the baseline. Do NOT use for judging whether config is well-shaped, debugging hooks, or organizing rules — that is `maintaining-claude-code`.
argument-hint: "[check]"
---

# Syncing Claude Code Config

Diff this config against Claude Code release notes published since the pinned baseline, surface the config-relevant changes worth adopting, apply the ones Teej picks, and bump the baseline. The relevance filter is computed live each run — there is no hand-maintained catalog.

`check` (or a bare invocation) is **report-only**: never write to config or to `baseline.json` until Teej approves the proposal.

State lives in `~/.claude/skills/syncing-claude-config/baseline.json`:

```json
{ "claudeCodeVersion": "2.1.234", "syncedDate": "2026-08-17", "adopted": [...], "declined": [...] }
```

## Boundary

This skill answers *"where has my config drifted from the product?"* — in two directions:

- **Forward drift** (steps 2–5) — what new releases added that this config should adopt.
- **Schema drift** (step 6) — where the config no longer matches the shipped schema in either direction, regardless of whether any release note mentioned it.

Both are drift *against the product*. It does **not** judge whether config is well-*shaped* — whether a hook belongs as a rule, whether a permission is too broad, whether the file is organized well. Hand any "is this edit correct / sensibly structured" question to the `maintaining-claude-code` skill after applying.

## Sources of truth

Four sources describe the same settings surface and they **routinely disagree**. In descending authority:

1. **The installed binary** — the only source that decides what actually runs. `strings "$(readlink -f "$(which claude)")"` then grep for the identifier. Zod shapes carry `.describe()` prose, so grepping `<key>:` usually yields the type, default, and a sentence.
2. **The docs key index** — `https://code.claude.com/docs/en/settings-reference.md` (~210 keys, with type / default / scope / example each). The best *breadth* source; use it to enumerate, then confirm anything surprising against the binary.
3. **schemastore** — `https://www.schemastore.org/claude-code-settings.json`. Useful for spotting `"Legacy alias for …"` wording, but drifts both ahead of and behind the binary.
4. **Release notes** — accurate about the *change*, often loose about the *identifier*.

When they conflict, the binary wins. Two conflicts seen on 2026-08-24 alone: schemastore documented `voice.{enabled,mode,autoSubmit}` while the binary's feature-gate shape registered only `voiceEnabled` (both spellings are accepted — the main settings schema carries the nested object); and schemastore's `voiceEnabled` description linked to `settings#available-settings`, an anchor that no longer exists because the key reference moved to its own page.

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

### 6. Audit the silently-validating surfaces

Steps 2–5 only find drift a release note *mentions*. That misses an entire failure class: config that no changelog line ever names, on surfaces that reject bad input **without saying so**. Run this every time — it is not conditional on the release window, and it is the step that catches four-month-old rot.

The two surfaces validate very differently:

| surface | validation | failure mode |
| --- | --- | --- |
| `settings.json` | zod → raises `unrecognized_keys` | loud; a bad key can't survive |
| `themes/*.json` | `Object.hasOwn(basePalette, k) && isValidColor(v)` | **silent**; unknown keys and invalid values are dropped with no warning, no error, no `--debug` line |

A silent surface rots in both directions at once — a key you never added falls back to the built-in base, and a key that was renamed away just stops applying. Neither shows up anywhere.

```bash
python3 ~/.claude/skills/syncing-claude-config/schema-completeness.py --strings "$SCRATCHPAD/bin-strings.txt"
```

It diffs each surface against the **installed binary** (source of truth #1) in both directions and exits non-zero on any finding:

- `missing` — in the schema, absent from your file → silent fallback to the base value
- `unknown` — in your file, absent from the schema → silently dropped
- `invalid` — value the surface's own validator rejects → silently dropped
- `suspect` — present and valid but semantically wrong (see below)

Reuse the strings dump from step 4 via `--strings` or it re-extracts; drop the flag if you haven't taken one yet.

**The `suspect` check.** Some palette keys are named like surfaces but are actually **accent foregrounds** — `background` is cyan in every built-in, not a fill. Assigning it a dark surface color yields valid, accepted, invisible text. The script tells the two apart without assuming a terminal background: **surfaces invert between the light and dark built-ins** (`userMessageBackground` 240→55), **accents keep their hue and brighten** (`background` 153→204). It then flags any accent sitting far from its own built-in value. This is what caught `background: #313244` at 6.3:1 off-target on 2026-08-26.

Findings here are **reported, never auto-applied** — they flow into the step 7 proposal table like everything else. Note that a missing key is not automatically a defect: the fallback may be the value you want. Propose the catppuccin-correct value and let Teej choose.

Two things the script deliberately does **not** flag: env vars without a Claude-owned prefix (`JJ_EDITOR` is a legitimate pass-through), and free-form maps whose keys are user data (`enabledPlugins`, `skillOverrides`, `extraKnownMarketplaces`). Free-form maps are *detected* — under half their children resolve to zod entries — rather than blacklisted, so new maps in future versions don't produce a wall of false positives.

**Doc-index cross-check** (breadth, for `settings.json` only). The docs key index is a faster enumerator than the binary when you want the whole surface at once:

```bash
S="$SCRATCHPAD"   # session scratchpad directory, from the environment context
curl -sL https://code.claude.com/docs/en/settings-reference.md -o "$S/settings-ref.md"
grep -oE '^#{3,4} `[^`]+`' "$S/settings-ref.md" | sed 's/^#* `//; s/`$//' | grep -v '\.' | sort -u > "$S/doc-keys.txt"
jq -r 'keys[]' ~/.claude/settings.json | grep -v '^\$' | sort | comm -23 - "$S/doc-keys.txt"
```

The `grep -v '\.'` drops nested `parent.child` entries, leaving the ~156 top-level keys. Drop it to audit nested objects too — but note `comm` then reports third-level keys (`sandbox.network.tlsTerminate`) against a second-level list, so flatten both sides before comparing.

Anything `comm` prints is **undocumented, not necessarily dead** — see the `@internal` note below. Confirm each against the binary before proposing removal.

**Half-wired config.** A key can be live, valid, and still inert because the switch that activates it lives at another scope. Check where a gate is actually set before calling its dependents dead:

```bash
grep -rl '"sandbox"' --include='settings*.json' ~/Projects ~/.claude 2>/dev/null \
  | while read f; do printf '%s\t%s\n' "$(jq -c 'if has("sandbox") and (.sandbox|has("enabled")) then .sandbox.enabled else "unset" end' "$f")" "$f"; done
```

Use `if has(...) then ... else` — **not** `//`. jq's alternative operator treats `false` as empty, so `.sandbox.enabled // "unset"` reports a disabled sandbox as unset and inverts the finding.

### 7. Present the proposal (two-zone)

Lead with a scannable table, risk-tiered, safest first:

| Setting | Current → Proposed | Risk | Why |
| --- | --- | --- | --- |

Risk tiers:
- **additive-safe** — new optional key/flag, no behavior change. Candidate for quick approval.
- **behavioral** — changes how something already behaves. Propose; gate on Teej hitting the symptom.
- **breaking** — renamed/removed key in use. Always preview the before/after diff; never auto-apply.

Under each row, cite the **exact changelog line** that justifies it, with the version. Then the collapsed "other release changes" bucket. End with the version window covered and the bump that will be recorded.

### 8. Apply (only on approval)

For each accepted change, edit the real config (`~/.claude/settings.json`, hooks, skill frontmatter). Record the rationale for every non-obvious edit in `baseline.json`, **not** as a comment in the config. `settings.json` is parsed by `jq` in steps 5-6 and by `check-json` in this repo's pre-commit, and both reject `//` comments — a breadcrumb in the file would fail `make validate`. One logical change per edit so git is the undo layer. After applying, hand the result to `maintaining-claude-code` for a well-formedness pass if any edit was non-trivial.

### 9. Bump the baseline

Update `~/.claude/skills/syncing-claude-config/baseline.json`: set `claudeCodeVersion` to installed, `syncedDate` to today (from the environment context, not a guess), append accepted changes to `adopted` (with the version that introduced them) and rejected ones to `declined`. The `declined` list is what stops the same proposal resurfacing next run.

## Notes

- Patch-only releases legitimately yield zero config changes — reporting "nothing to adopt" is a correct, expected outcome, not a failure.
- If the releases API is unreachable, fall back to `https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md` (same bullets, no dates).
- Never propose `enforceAvailableModels`, `requiredMinimumVersion`, or other managed/enterprise keys for this single-user config unless Teej asks — they target shared/managed deployments.
- **Undocumented ≠ stale.** Keys tagged `@internal` in their zod `.describe()` are deliberately excluded from the docs but fully live. `skipWorkflowUsageWarning` is one (*"@internal Whether the user has accepted the multi-agent workflow usage warning"*); `autoDreamEnabled` is undocumented without the tag. Never propose deleting a key on doc-absence alone.
- **Pre-baseline drift.** A bullet can *expose* an older surface without introducing it — the 2.1.239 `voice.enabled` mention is the case in point, since the nested object was already in the 2.1.238 binary. Before recording an `adopted` entry, check whether the anchor predates the baseline, and say so in the note; the ledger is only useful if provenance is honest.
- **Measure before proposing context-budget keys.** Anything that trades context for fidelity (`skillListingBudgetFraction`, `skillListingMaxDescChars`, `autoCompactWindow`) needs the actual corpus measured first, not estimated — the 2026-08-24 decline held up only because the numbers were counted. `/skill-doctor` (2.1.261+) is the direct instrument: it lists every loaded skill with its usage count and estimated resident context cost, so an unused-and-expensive entry is a number, not a hunch. `/doctor` covers the same ground under its "unused skills, MCP servers, and plugins" check, plus the ~1% listing budget beyond which entries truncate and skill routing degrades. Run one of them before touching any listing-budget key, and paste the totals into the proposal row.
- **Loud vs silent validation is the whole reason step 6 exists.** `settings.json` goes through zod and raises `unrecognized_keys`, so a bad key there cannot survive a single launch. `themes/*.json` filters overrides through `Object.hasOwn(basePalette, key) && isValidColor(value)` and drops the rest in total silence. That asymmetry is why the theme sat 4 keys behind with 1 dead key for four months while `settings.json` stayed clean the entire time. Before trusting *any* surface to self-report, check which kind it is — and if it's silent, it needs a completeness diff, not a spot check.
- **`jq`'s `//` operator treats `false` as empty.** `.sandbox.enabled // "unset"` reports a *disabled* sandbox as unset, which inverts the conclusion. Use `if has("enabled") then .enabled else "unset" end` whenever the value being probed can legitimately be `false` — which is most feature gates.
- **A live key can still be inert.** `sandbox.*` rules at user scope do nothing until something sets `sandbox.enabled: true`, and that switch is commonly written per-project into `.claude/settings.local.json` by the `/sandbox` panel. Before reporting a block of config as dead, grep the other scopes for the gate. Rules and their switch living at different scopes is a real state, not a contradiction.
- **Cross-check completeness against the weekly digests.** `https://code.claude.com/docs/en/whats-new/2026-w<NN>.md` groups releases into themed summaries with an "Other wins" list. It is a *verification* source, not a primary one — it surfaced nothing the releases API had missed on 2026-08-24 — but it is a cheap way to confirm the ledger caught everything in a window. `https://code.claude.com/docs/llms.txt` indexes every docs page.
