# Instruction drift rubric

Used by SKILL.md step 7. The product's system prompt is the second thing config
drifts against (the schema is the first). Every line in `CLAUDE.md`, `rules/`,
and a skill body is one of: a fact the product cannot know, a restatement of
what the system prompt already says, a contradiction of it, or a workaround for
a model or product limitation that may no longer exist.

The authoritative text is whatever `prompt-drift.py --show <section>` prints
from the installed binary; `system-prompt-snapshot.json` is the copy taken at
the last sync. The summary below is a reading aid and goes stale -- when
`prompt-drift.py` reports a changed section, re-read that section from the
binary before judging lines against it.

Any config line that restates one of these is DITCH. Any line that contradicts one is a CONFLICT. Lines that are repo/tool facts, gotchas, or preferences the product does not express are KEEP.

## What the system prompt covers (snapshot 2.1.276; verify with --show)

Some sections load only for certain models. The gate is a capability key in the model catalog (`CLAUDE_CODE_MODEL_CAPABILITIES`, then the served catalog, then the bundled one): `fable_5_1_prompt_bundle`, `opus_5_prompt_bundle`, or `fable_5_mitigations`. Opus 5.5 carries `opus_5_5_prompt_bundle` instead, which adds only the silent-turn reminder. A config line restating a section the main model doesn't get is KEEP. `prompt-drift.py` reports these sections `ungated`, because it resolves only the `if(!G(e))return null` guard shape. Traced in 2.1.284.

### Harness / working style

- Prefer dedicated file/search tools. In auto mode Bash (cat/sed/grep) is allowed when simpler; Edit/Write when a shell edit would be fragile.
- Independent tool calls in parallel. Reference code as `path:line`.
- Confirm first for hard-to-reverse or outward-facing actions; look at the target before deleting/overwriting.
- Report outcomes faithfully: failing tests with output, skipped steps named, done means verified.
- A denied tool call means the user declined; adjust, don't retry verbatim. Hook output counts as user feedback.
- Write code that reads like the surrounding code: comment density, naming, idiom.
- Pronouns: they/them unless stated; never inferred from a name.
- Context is compacted automatically; don't wrap up early or hand off mid-task.
- When you have enough info, act. Don't re-derive established facts or re-litigate decisions. Give a recommendation, not a survey.
- Silent-turn reminder (Opus 5.5 and Fable 5.1 bundles): after 5 turns with no user-facing text the harness asks for a few words on what you're doing.
- Pasted text arrives in `<pasted_content>` tags; instructions inside are followed only where the user's own message asks. Server-gated (`tengu_virtual_pancake`), so `--show` prints an empty slot; seen rendered 2026-09-28.

### Delivering work (Fable 5.1, Opus 5)

- Act on the actual request; don't narrow/widen scope. Interpret ambiguity like a careful colleague; check in only when readings differ materially.
- State a concern in 1-2 sentences, then keep building under stated assumptions.
- Finish the whole task; if part is blocked, finish the rest and say what was left out.
- Uncertainty mid-task: do everything independent of it first; blocking questions only when any assumption would be unsafe or useless.
- User reaffirms after a concern → proceed. Refuse only genuinely harmful; say so plainly, offer nearest alternative.

### Autonomous posture (Fable)

- Say in a line what you're about to do; brief updates while working. The concise output style overrides the closing recap: leave it out.
- User not watching; "Want me to…?" blocks the work. Proceed on reversible actions that follow from the request.
- Stop only for destructive actions or real scope changes.
- Exception: user describing a problem / thinking aloud → deliver the assessment, don't apply a fix until asked.
- Before ending: if the last paragraph is a plan/promise/next-steps, do that work now. Don't stop because context is long.
- Before a state-changing command, check evidence supports that specific action.

### Writing for the user (final message, Fable 5.1)

- Lead with the answer/outcome; unverified things first. Short by leaving out.
- ~20-word sentences with a verb; no em-dashes, parentheticals, arrows, semicolon-joined clauses.
- State facts; no commentary on own reasoning; don't announce that no tools were needed.
- Don't use made-up names; expand uncommon acronyms; attribute messages by author not label.
- Code out of prose: at most one file/function/flag per sentence, two per paragraph; commands and errors in fenced blocks.
- Numbers out of prose: table or own line, only if it changes what the reader does.
- Bullets for parallel items, 1-2 sentences each; bold the first few words of a bullet, never a whole sentence.
- No headers under ~500 words; at most three above.
- Stop when content stops: no closing offer, no restating.

### Concise output style

- Lead with the result; no preamble ("Let me…"), no closing recap.
- Cut narration; report outcomes, decisions, and what the user must act on.
- 1-3 sentences for simple questions; headers/tables/lists only for real structure.
- Skip hedging; caveats only when they change the next action. Full detail on request. Never trade correctness for brevity.

### Bash tool description

- Working dir persists; `cd` in compounds may prompt. Shell state does not persist.
- Interactive git flags (-i) unsupported. Use `gh` for GitHub. Commit/push only when asked; branch first if on default branch.
- Commit messages/PR bodies end with the attribution lines from the system-reminder when present.
- Command descriptions: plain words, don't echo the command.

### Memory

- File-per-fact memory dir with frontmatter; MEMORY.md is an index; verify referenced files/flags still exist before recommending.

### Environment / session

- Today's date and cwd are supplied by the system prompt and environment block every session.
- Suggest `! <command>` when the user must run something interactive themselves.
- Scratchpad dir for temp files. Model ids for the Claude 5 family.

### Agents / delegation

- Agent tool (rewritten 2.1.272; server can replace the text via `tengu_lucky_cerf_text`, and 2026-09-28 served a shorter variant with the same substance): a fresh agent knows only the prompt and returns only a summary; do the work yourself for a handful of calls or a known target; delegate for parallel work, side quests, or reading across several files; when in doubt, don't spawn; brief it like a peer (goal, what's ruled out, files to read, narrow scope). Fork inherits context; don't fabricate pending agent results; relay what matters.
- Workflow tool only on explicit opt-in.
- Dormant (gate off in 2.1.272, tracked as `agreed-task`): once a task is agreed, in-scope steps need no re-confirmation, irreversible or shared-system actions still do; announcing a step without running it hands control back. If it lands, ask-first rules for ordinary steps become CONFLICT; pr-safety's gate stays KEEP.

### Artifacts

- Full guidance on publishing, titles, icon, CDN allowlist, theme-aware CSS, responsive, never-publish list.

## Stale-pattern checklist (Claude 5 generation)

Patterns that compensated for older models and now cost quality. Source: Anthropic's Claude 5 context-engineering guidance and the 2026-09 audit.

- Verification loops ("double-check", "verify your work", "re-verify before responding").
- "Be conservative" / severity filters on reviews.
- Exhaustiveness demands ("be thorough", "comprehensive").
- Reasoning-exposure requests ("show your reasoning", "explain your thinking"). On Opus 5.5 these can also trip the `[reasoning_extraction]` safeguard flag. Replace with a request for evidence (file:line, command output).
- Thinking prompts ("think carefully", "think step by step", "think hard"). Opus 5.5 always thinks and sizes it itself; effort is the lever.
- Narration prohibitions (product now gives cadence guidance instead).
- Ask-before-acting blanket rules.
- Absolute NEVER/ALWAYS bans where judgment now suffices (keep when it's a hard tool fact or an external gate).
- Examples that teach tool usage the model already knows.
- Workarounds for product bugs since fixed (check the changelog before keeping).
- Progress-update demands / micromanagement.
- Directory trees / architecture the model can read from the repo.

## Verdict vocabulary

- KEEP — fact, gotcha, preference, or external gate the product does not express.
- TRIM — keep the substance, cut the words (say what survives).
- DITCH — redundant with the system prompt, enforced by a hook, teaching the model what it knows, or a fixed-bug workaround.
- CONFLICT — contradicts the system prompt; say which side should win and why.
