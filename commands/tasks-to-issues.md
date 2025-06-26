# ABOUTME: Converts task breakdowns into GitHub issues without timeline artifacts

## ABOUTME: Focuses on clear deliverables and dependencies rather than project scheduling

Convert tasks to GitHub issues: $ARGUMENTS

I'll take a `tasks.md` file and create GitHub issues for each implementable task.

I will:

1. Analyze the `tasks.md` to extract each specific task
2. Create focused GitHub issues for individual deliverables
3. Structure issues with clear acceptance criteria and implementation approach
4. Map task dependencies as issue relationships (not timeline phases)
5. Apply descriptive labels based on task type and components

## Issue Structure

Each GitHub issue will include:

### Core Information

- **Clear, specific title** - What exactly will be delivered
- **Task description** - Detailed explanation of the functionality to implement
- **Acceptance criteria** - Specific, testable conditions for completion
- **Implementation approach** - Technical strategy (TDD, refactoring, new feature)

### Technical Context

- **Required changes** - Files, modules, or systems that need modification
- **Test requirements** - What tests need to be written or updated
- **Integration considerations** - How this connects to existing functionality
- **Documentation needs** - Any docs that need creation or updates

### Relationships

- **Prerequisite issues** - Tasks that must be completed first
- **Related issues** - Tasks that should be coordinated together
- **Follow-up opportunities** - Optional enhancements that could be done later

## Labels Applied

- **Component labels** - Based on affected systems (frontend, backend, cli, etc.)
- **Type labels** - Implementation approach (feature, refactor, bugfix, test)
- **Complexity labels** - Effort estimation (small, medium, large)

No priority levels (P0, P1, P2), milestone assignments, or timeline scheduling - just clear task organization focused on deliverables and dependencies.
