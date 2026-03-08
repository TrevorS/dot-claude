# Generate agent team configuration from tasks

Generate agent team plan: $ARGUMENTS

I'll analyze the project's `docs/tasks.md` (and supporting docs) to design a targeted agent team configuration and write it to `docs/team.md`.

I will:

1. Read `docs/tasks.md` to understand all implementable tasks and their dependencies
2. Read `docs/spec.md` and `docs/requirements.md` for architectural context
3. Read any `CLAUDE.md` files for project conventions and constraints
4. Identify **parallel work groups** — clusters of tasks with no cross-dependencies
5. Design **teammate roles** — each role owns a distinct set of files and tasks
6. Define **coordination strategy** — task ordering, dependency gates, and communication patterns
7. Generate a **kickoff prompt** that can be pasted directly into Claude Code to launch the team
8. Write the complete configuration to `docs/team.md`

## Analysis Strategy

### Task Clustering

- Group tasks by **layer** (shared, container, gateway, infra, etc.)
- Identify tasks that can run in **true parallel** (no shared file edits)
- Flag tasks with **cross-cutting dependencies** that need sequencing
- Map which files each task touches to prevent teammate conflicts

### Role Design

Each teammate role includes:

- **Name** — short identifier (e.g., `shared-layer`, `hooks-author`, `gateway-builder`)
- **Responsibility** — which tasks from `tasks.md` this teammate owns
- **File ownership** — directories/files this teammate will create or modify (no overlaps)
- **Tools needed** — Read, Write, Edit, Bash, Grep, Glob, WebSearch, etc.
- **Context brief** — task-specific prompt with acceptance criteria pulled from tasks.md
- **Estimated complexity** — based on task count and interdependencies

### Coordination Strategy

- **Phase gates** — which tasks must complete before the next wave of teammates can start
- **Dependency handoffs** — when one teammate's output is another's input
- **File conflict prevention** — explicit file ownership boundaries
- **Quality checkpoints** — where the lead should review before proceeding
- **Plan approval** — which teammates should require plan approval before implementing

### Team Sizing

- Target **3-5 teammates** for most projects (balances parallelism with coordination overhead)
- Target **5-6 tasks per teammate** for productive work units
- Prefer fewer focused teammates over many scattered ones
- Consider task complexity — some teammates may need fewer but harder tasks

## Output Structure (docs/team.md)

The generated `docs/team.md` will contain:

### Team Overview

- **Project summary** — one-paragraph context from spec.md
- **Team size** — number of teammates and rationale
- **Estimated phases** — how many waves of parallel work

### Teammate Definitions

For each teammate:

- **Role name and description**
- **Assigned tasks** (by ID from tasks.md)
- **Owned files/directories** (no overlaps between teammates)
- **Required tools**
- **Context brief** — self-contained prompt the lead passes at spawn time
- **Dependencies** — which other teammates must finish first

### Phase Plan

- **Phase 1**: teammates that can start immediately (no blockers)
- **Phase 2**: teammates that depend on Phase 1 outputs
- **Phase N**: subsequent waves as dependencies resolve

### Kickoff Prompt

A ready-to-paste prompt for Claude Code that:

- Requests team creation with the right number of teammates
- Defines each teammate's role, tasks, and file boundaries
- Sets up the task list with dependency ordering
- Specifies plan approval requirements where appropriate
- Includes quality gates and coordination instructions

### Coordination Rules

- File ownership map (which teammate owns which paths)
- Communication triggers (when teammates should message each other)
- Completion criteria (how the lead knows the team is done)

## Design Principles

- **No file conflicts** — every file has exactly one owner
- **Self-contained briefs** — each teammate gets everything it needs in its spawn prompt (no inherited conversation history)
- **Minimal coordination** — prefer independent work over frequent check-ins
- **Progressive unlocking** — later phases start only when dependencies are met
- **Right-sized roles** — match teammate count to actual parallelism, not task count
