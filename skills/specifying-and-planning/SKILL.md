---
name: specifying-and-planning
description: Plan project implementation -- extract requirements from specs, break into tasks, create GitHub issues, set up project boards, or generate agent team configurations. Use when planning a project, extracting requirements, breaking down tasks, creating issues from a spec, setting up GitHub projects, or generating team plans.
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

Analyze a spec file and produce structured `requirements.md`:

- **Functional Requirements**: Features, user interactions, data, integrations
- **Non-Functional Requirements**: Performance, security, usability, reliability
- **Requirement Dependencies**: Prerequisites, interdependencies, optional links

Each requirement gets clear acceptance criteria.

### requirements-to-tasks

**Trigger**: "break into tasks", "create task breakdown", references to `requirements.md`

Convert requirements into implementable `tasks.md`:

- **Task description** -- specific functionality to implement
- **Acceptance criteria** -- how to verify completion
- **Implementation approach** -- TDD, refactoring, new feature
- **Required components** -- files, modules, systems needing changes
- **Test requirements** -- what tests to write/update
- **Dependencies** -- prerequisite tasks, interdependent tasks

Focus on functional decomposition. No timeline or phases -- clean technical breakdown.

### tasks-to-issues

**Trigger**: "create issues", "convert tasks to issues", references to `tasks.md`

Create GitHub issues from task breakdown:

```bash
gh issue create --title "Clear title" --body "$(cat <<'EOF'
## Description
Task description

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Implementation Approach
Technical strategy

## Dependencies
- Requires #<issue>
EOF
)"
```

Apply labels: component (frontend, backend), type (feature, refactor), complexity (small, medium, large).

### setup-github-project

**Trigger**: "set up project", "create project board", references to `issues.md`

Create complete GitHub project infrastructure:

1. Parse issues file for labels, milestones, relationships
2. Create labels with smart color coding
3. Set up milestones with due dates
4. Create project board with custom fields
5. Generate all issues with proper labels and milestones
6. Link issue dependencies

### tasks-to-team

**Trigger**: "generate team plan", "create agent team", "parallelize work"

Design agent team configuration from tasks:

1. Read tasks for dependencies and scope
2. Identify parallel work groups (no cross-dependencies)
3. Design teammate roles with distinct file ownership
4. Define coordination strategy and phase gates
5. Write `docs/team.md` with kickoff prompt

Target 3-5 teammates, 5-6 tasks per teammate. Prefer fewer focused teammates over many scattered ones.

**Model selection per teammate.** Agent teams run ~7x tokens vs a single session, so the temptation is to downgrade aggressively. Resist it. A teammate that fails still burned input + output tokens, and a failed parallel branch blocks its dependents — the real cost of a bad model choice is retries + debugging + lost time, not the initial API spend. When in doubt, go one tier up.

Guidance, not a rule:

- `claude-opus-4-7` — roles that drive architectural decisions, gnarly debugging, cross-cutting refactors with high blast radius, or where a single mistake cascades. Use here freely; this is where Opus earns its keep.
- `claude-sonnet-4-5` — default for implementation work: most writing-code, refactoring, integration, review. Strong tool use, reliable enough for parallel execution.
- `claude-haiku-4-5` — only roles where the failure mode is cheap and obvious: shell-command runners, file movers, status reporters, well-specified doc generation. Not for anything requiring judgment.

Set `model:` explicitly in each teammate's frontmatter — unset inherits the parent model silently. If a role sits on the Sonnet/Opus boundary, pick Opus. If a role sits on the Haiku/Sonnet boundary, pick Sonnet.

**Context discipline**: instruct each teammate to return a **≤1500-token summary** to the root agent, not raw tool output. The root agent's context is the scarce resource; teammates that dump full output defeat the parallelism benefit.

## General Principles

- No artificial timelines or phases (except team coordination)
- Focus on deliverables and dependencies
- Each requirement/task/issue should be independently verifiable
- Use TDD approach in task descriptions
- Cache project information in CLAUDE.md
