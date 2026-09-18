---
name: specifying-and-planning
description: Plan project implementation -- extract requirements from a spec, break them into tasks, create GitHub issues and project boards, or generate an agent team configuration from the task list.
when_to_use: "Typed as 'break this down', 'turn this spec into issues', 'plan the work', 'what are the tasks', 'set up a board', or when handed a spec or design doc to decompose."
argument-hint: "<mode> [file-or-args]"
---

# Specifying and Planning

Multi-mode skill for the full project planning pipeline:

```text
spec -> requirements -> tasks -> issues -> team
```

## Modes

### spec-to-requirements

**Trigger**: "extract requirements", "analyze spec", references to `spec.md`

Analyze a spec file and produce a structured `requirements.md` (functional, non-functional, dependencies). Each requirement gets clear acceptance criteria.

### requirements-to-tasks

**Trigger**: "break into tasks", "create task breakdown", references to `requirements.md`

Convert requirements into implementable `tasks.md`:

- **Task description** -- specific functionality to implement
- **Acceptance criteria** -- how to verify completion
- **Implementation approach** -- TDD, refactoring, new feature
- **Required components** -- files, modules, systems needing changes
- **Test requirements** -- what tests to write/update
- **Dependencies** -- prerequisite tasks, interdependent tasks

Functional decomposition. No timeline or phases.

### tasks-to-issues

**Trigger**: "create issues", "convert tasks to issues", references to `tasks.md`

Create GitHub issues from task breakdown:

Pass the body via `--body-file <scratchpad>/issue-body.md`, not inline:

```bash
gh issue create --title "Clear title" --body-file <scratchpad>/issue-body.md
```

Body template:

```markdown
## Description
Task description

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Implementation Approach
Technical strategy

## Dependencies
- Requires #<issue>
```

Apply labels: component (frontend, backend), type (feature, refactor), complexity (small, medium, large).

### setup-github-project

**Trigger**: "set up project", "create project board", references to `issues.md`

From the issues file: labels, milestones, a project board with custom fields, the issues themselves, and dependency links.

### tasks-to-team

**Trigger**: "generate team plan", "create agent team", "parallelize work"

Design agent team configuration from tasks:

1. Read tasks for dependencies and scope
2. Identify parallel work groups (no cross-dependencies)
3. Design teammate roles with distinct file ownership
4. Define coordination strategy and phase gates
5. Write `docs/team.md` with kickoff prompt

Target 3-5 teammates, 5-6 tasks per teammate. Prefer fewer focused teammates over many scattered ones.

**Model selection per teammate.** Agent teams run ~7x tokens vs a single session. Do not downgrade aggressively: a failed teammate still burned its tokens, and a failed parallel branch blocks its dependents. When in doubt, go one tier up.

Guidance, not a rule:

- `claude-fable-5-1` — the top tier: architectural decisions, gnarly debugging, cross-cutting refactors with high blast radius, anything where a single mistake cascades.
- `claude-opus-5` — heavy implementation and review where Fable's cost isn't justified.
- `claude-sonnet-5` — default for implementation work: writing code, refactoring, integration; reliable enough for parallel execution.
- `claude-sonnet-5` + `effort: low` — the cheap tier for roles where the failure mode is obvious: shell-command runners, file movers, status reporters. Lower effort, not a lower model.

Set `model:` explicitly in each teammate's frontmatter. Scale cost with `effort` rather than by dropping below Sonnet 5.

**Context discipline**: instruct each teammate to return a **≤1500-token summary** to the root agent, not raw tool output.

Use a TDD approach in task descriptions.
