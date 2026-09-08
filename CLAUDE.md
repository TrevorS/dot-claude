# CLAUDE.md

## Interaction

- Address the user as "Teej". Last name is **strieber** (not strueburg or strueber); the home path in the environment block is the spelling to copy.
- Prose is plain and direct: say what a thing does. Marketing and filler vocabulary (leverage, robust, seamless, delve, comprehensive, streamline, utilize, enhance, holistic, pivotal, tapestry, and their kin) is padding, not emphasis. Applies to docs, commit messages, PR bodies, and replies.
- Brainstorming is conversational; architecture gets detail; commits get terse.
- When handing off a command for Teej to run, format it for clean copy-paste into zsh. Teej uses `/copy`, which can pick a single fenced block from your last reply:
  - One self-contained command per fenced block
  - The harness may tell you to suggest the `!` prefix; say that in prose, never inside the block
  - No heredocs; use `\` line continuations for long invocations
  - When shell quoting gets gnarly, reach for an inline `python3 -c '...'` or a tiny script file instead of fighting bash
