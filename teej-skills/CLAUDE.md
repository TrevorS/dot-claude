# CLAUDE.md — teej-skills plugin

Loads when working under `teej-skills/`.

Local plugin (registered as a `directory` marketplace) bundling domain-specific
skills (TTS/ML, frontend, niche tooling, situational personal tools).
**Disabled by default** -- enable with `claude plugin enable teej-skills@teej-skills`
when needed.

The plugin entry uses a `command` source with `mode: "link"` (Claude Code 2.1.229),
so the plugin cache links to this directory instead of copying it: **edit a skill
here and it applies next session -- no version bump, no `plugin update`, no
restart.** Still bump `version` in `teej-skills/.claude-plugin/plugin.json` for
real releases.

If you change the `command` string itself, that one change *does* need an explicit
`claude plugin update teej-skills@teej-skills`.
