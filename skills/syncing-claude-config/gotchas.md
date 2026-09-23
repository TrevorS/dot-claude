# syncing-claude-config gotchas

Failure modes seen on past runs, grouped by the workflow step they bite. Read the section for the step you are on.

## Sources disagree (every step)

- When the binary, the docs key index, schemastore and the release notes conflict, the binary wins. On 2026-08-24 alone: schemastore documented `voice.{enabled,mode,autoSubmit}` while the binary's feature-gate shape registered only `voiceEnabled` (both spellings are accepted; the main settings schema carries the nested object), and schemastore's `voiceEnabled` description linked to `settings#available-settings`, an anchor that no longer exists because the key reference moved to its own page.
- `strings(1)` misses some embedded JS. Use Python `re` over the raw binary bytes with a fixed-string anchor, then widen the window around the hit.
- If the releases API is unreachable, fall back to `https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md` (same bullets, no dates).
- The weekly digests (`https://code.claude.com/docs/en/whats-new/2026-w<NN>.md`) are a verification source, not a primary one: they surfaced nothing the releases API missed on 2026-08-24, but they cheaply confirm the ledger caught a window. `https://code.claude.com/docs/llms.txt` indexes every docs page.

## Prompt drift (steps 1 and 7)

- Tracked sections can be dormant. The prompt string sits behind `function X(e){if(!G(e))return null;return"..."}`; `prompt-drift.py` resolves `G` and stores `off`/`on`/the flag or model prefix beside the text. The "approval covers the task end to end" block sat at `off` through 2.1.269–2.1.272, so text-only diffing would have called the day it landed "unchanged".
- For prompt changes outside the tracked anchors, `prose-diff.py OLD NEW` (runs of 22+ words, set-differenced between two installed versions in `~/.local/share/claude/versions/`) takes about 13 s. On 2.1.269→2.1.272 it surfaced the Agent tool rewrite no anchor covered; on 2.1.272→2.1.273, the Artifact tool's publishing wording and the bundled commit skills' git refusal list, neither in the release notes.

## Schema audit (step 6)

- The `suspect` check exists because some palette keys are named like surfaces but are accent foregrounds: `background` is cyan in every built-in, not a fill, so a dark surface color there is valid, accepted, invisible text. The script separates the two without assuming a terminal background: surfaces invert between the light and dark built-ins (`userMessageBackground` 240→55), accents keep their hue and brighten (`background` 153→204). This caught `background: #313244` at 6.3:1 off-target on 2026-08-26.
- The script does not flag env vars without a Claude-owned prefix (`JJ_EDITOR` is a legitimate pass-through) or free-form maps whose keys are user data (`enabledPlugins`, `skillOverrides`, `extraKnownMarketplaces`). Free-form maps are detected (under half their children resolve to zod entries), not blacklisted, so new maps don't produce a wall of false positives.
- Undocumented is not stale. Keys tagged `@internal` in their zod `.describe()` are excluded from the docs but live: `skipWorkflowUsageWarning` is one; `autoDreamEnabled` is undocumented without the tag. Never propose deleting a key on doc-absence alone.
- The doc-index `comm` drops nested keys via `grep -v '\.'`. Drop that filter to audit nested objects, but flatten both sides first, or `comm` compares third-level keys (`sandbox.network.tlsTerminate`) against a second-level list.
- Half-wired config: a key can be live and valid yet inert because its gate is set at another scope. Check where the gate is set before calling dependents dead, and use `if has(...) then ... else`, not `//`: jq's alternative operator treats `false` as empty, so `.sandbox.enabled // "unset"` reports a disabled sandbox as unset.
- A setting at its default is noise, and a default can differ from what the docs imply: `alwaysThinkingEnabled` is on when absent (binary describe), so `true` was a no-op even for the Sonnet fallback hops.

## Release window blind spot (steps 2–5)

- Steps 2–5 only propose what a release note in the window names, so a feature that predates the first sync stays invisible. Once per sync, diff the docs' hook handler fields, skill frontmatter table and settings key index against what the config actually uses. On 2026-09-15 the hooks reference surfaced the handler-level `if` filter (2.1.85, six months pre-baseline), worth a 13× cut in guard spawns.
- A bullet can expose an older surface without introducing it: the 2.1.239 `voice.enabled` mention, when the nested object was already in 2.1.238. Before recording an `adopted` entry, check whether the anchor predates the baseline and say so in the note.

## Hooks (steps 6 and 7)

- Verify a hook `if` filter against the binary, not the docs: `claude -p '<prompt forcing one Bash command>' --debug-file F`, then grep F for `Skipping hook due to if condition`. One line per skipped handler, none for handlers that ran. The filter strips leading `VAR=value` only; `timeout`, `nice`, `env`, `bash -c` and absolute paths never reach the hook.
- Zero hook fires is a finding, not reassurance. Measure per hook over 30 days (`hook error: [$HOME/.claude/hooks/<name>.sh]` is the PreToolUse block signature), then probe it with harness-shaped payloads. `branch_protection.sh` had 0 fires for months because jj renders an ahead-of-remote bookmark as `master*`; `git_dangerous_flags.sh` had 0 because the workflow is jj. Same number, opposite conclusions.
- Hook scripts that call `jj log` without `--ignore-working-copy` snapshot the working copy. `project-context.sh` keeps exactly one such call on purpose (per-prompt restore point, since `fileCheckpointingEnabled` is false); any other snapshotting call clutters `jj op log`.

## Plugins and skills

- LSP plugins can load as empty shells: cached artifacts from before `lspServers` moved into `marketplace.json` carry no server config, `claude plugin update` reports them current, and `claude plugin details` still shows the server (it reads the marketplace entry). Only the debug log tells the truth: grep `claude -p ... --debug-file F` output for `Total LSP servers loaded`. Fix with `claude plugin uninstall` then `install` (anthropics/claude-code#78604, #93474). Re-enabling a disabled LSP plugin needs the same reinstall.
- Synced claude.ai skills come from whichever org you are logged into; `skills/synced/` holds one folder per org, and `/login` switches the set. `skillOverrides` applies to them by full name (`anthropic-skills:<name>`), so one entry covers every org that ships that name.
- `/skill-doctor` runs headless (`claude -p '/skill-doctor' --no-session-persistence`); `/doctor` prints nothing under `-p`.
- Measure before proposing context-budget keys (`skillListingBudgetFraction`, `skillListingMaxDescChars`, `autoCompactWindow`). `/skill-doctor` gives per-skill usage and resident cost; paste its totals into the proposal row. The 2026-08-24 decline held only because the numbers were counted.

## Applying changes (step 9)

- The auto-mode classifier blocks some settings edits as [Self-Modification] and allows others. Blocked on 2026-09-23: removing deny rules, removing `switchModelsOnFlag`, editing guard hooks' logic, `.claude/settings.local.json`, and `prompt-drift.py --update`. Allowed: adding deny rules, removing or narrowing allow rules, `skillOverrides`, `enabledPlugins`, `fallbackModel`, `env` renames. For a blocked edit, write a script that anchors each change exactly once and hand Teej one command to run with `!`; don't retry through another tool.
- Never propose `enforceAvailableModels`, `requiredMinimumVersion` or other managed/enterprise keys for this single-user config unless Teej asks.
