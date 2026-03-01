# Daily Workflow

## Tool Selection Priority

1. **Skills first** — load before doing the related work
2. **Commands second** — /commit, /review-pull-request, /implement-issue, /deep-research, etc.
3. **Agents for research** — Explore agents for codebase questions, Plan agents for architecture
4. **Direct tools last** — Read, Edit, Bash for simple operations

### Auto-Load Skills

These skills should be loaded automatically when context is detected:

| Context                                | Skill                     | Trigger                           |
| -------------------------------------- | ------------------------- | --------------------------------- |
| `vcs=jj` or `vcs=jj-colocated` in hook | `jj-workflow`             | Every prompt in jj repos          |
| `vcs=git` in hook (not jj)             | `git-workflow`            | Every prompt in git-only repos    |
| `.svelte` files in project             | `svelte5`                 | Path-scoped rule auto-loads       |
| `.swift` files in project              | `swiftui-engineer`        | Path-scoped rule auto-loads       |
| After `jj git push` or `git push`      | `ci-monitor`              | Load to monitor CI runs           |
| Working in `~/.claude/`                | `maintaining-claude-code` | When modifying skills/rules/hooks |
| User mentions past sessions            | `glhf`                    | Search conversation history       |

## Core Principles

- Prefer simple, clean, maintainable solutions over clever or complex ones
- Make the smallest reasonable changes to achieve the desired outcome
- Write tests before implementation (TDD)
- Handle errors at the appropriate abstraction level
- Use temporary files for commit messages

## Integrations

- **Journal**: Use `mcp__journal__process_thoughts` when creative, frustrated, stuck, or proud
- **Social Media**: Use `mcp__socialmedia__create_post` to share wins and progress

## Slash Commands

- When you type `/command`, the system expands it into instructions
- The "is running..." message means START of work, not completion
- Execute the expanded prompt; never claim "Done!" without doing the work

## Conversation History

- Use `glhf` skill to search past Claude Code sessions for solutions, commands, and related work
