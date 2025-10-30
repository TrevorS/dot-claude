# Planning Workflow

<!-- ABOUTME: Convert specifications to requirements, tasks, and GitHub issues in a unified workflow -->

<!-- ABOUTME: Complete pipeline from spec to implementation-ready GitHub issues -->

Convert specifications → requirements → tasks → GitHub issues with a unified planning workflow.

Usage: `/planning-workflow spec-to-requirements [file]` or `/planning-workflow requirements-to-tasks [file]` or `/planning-workflow tasks-to-issues [file]`

---

## Step 1: Spec to Requirements

Extract clear functional and non-functional requirements from a specification document.

### Task (Spec → Requirements)

I'll analyze a `spec.md` file and extract clear functional and non-functional requirements.

I will:

1. Analyze the `spec.md` to identify all requirements
2. Categorize requirements as functional vs non-functional
3. Create a structured `requirements.md` with:
   - Clear requirement descriptions
   - Acceptance criteria for each requirement
   - Dependencies between requirements
   - Technical constraints and considerations

### Output Structure

The `requirements.md` will contain:

#### Functional Requirements

- **Feature descriptions** - What the system should do
- **User interactions** - How users will interact with features
- **Data requirements** - What data needs to be managed
- **Integration requirements** - How components work together

#### Non-Functional Requirements

- **Performance requirements** - Speed, throughput, response times
- **Security requirements** - Authentication, authorization, data protection
- **Usability requirements** - User experience standards
- **Reliability requirements** - Error handling, recovery, availability
- **Maintainability requirements** - Code quality, documentation standards

#### Requirement Dependencies

- **Prerequisites** - What must exist before a requirement can be implemented
- **Interdependencies** - Requirements that must be coordinated together
- **Optional dependencies** - Nice-to-have connections between requirements

This focuses purely on **what needs to be built** and **how it should behave** without artificial project scheduling.

### Example

````bash
/planning-workflow spec-to-requirements spec.md
# Outputs: requirements.md with structured requirements
```text

---

## Step 2: Requirements to Tasks

Break requirements into specific, implementable development tasks.

### Task (Requirements → Tasks)

I'll take a `requirements.md` file and break it down into specific, implementable tasks.

I will:

1. Analyze each requirement to understand its implementation scope
2. Break complex requirements into smaller, testable chunks
3. Identify technical implementation approach for each task
4. Create a structured `tasks.md` with clear deliverables
5. Map dependencies between tasks (not timeline phases)

### Task Structure

Each task will include:

#### Core Task Information

- **Task description** - What specific functionality to implement
- **Acceptance criteria** - How to verify the task is complete
- **Implementation approach** - Technical strategy (TDD, refactoring, new feature)
- **Required components** - Files, modules, or systems that need changes

#### Technical Considerations

- **Test requirements** - What tests need to be written/updated
- **Integration points** - How this task connects to existing code
- **Configuration changes** - Any settings or environment updates needed
- **Documentation updates** - What docs need to be created/updated

#### Dependencies

- **Prerequisites** - Tasks that must be completed first
- **Interdependent tasks** - Tasks that need coordination
- **Optional enhancements** - Related improvements that could be done later

### Focus Areas

This approach emphasizes:

- **Functional decomposition** - Breaking features into testable units
- **Clear deliverables** - Specific outcomes that can be verified
- **Technical feasibility** - Realistic implementation chunks
- **Test-driven approach** - Each task includes testing strategy

No timeline creation, phases, or project scheduling - just clean technical task breakdown.

### Example

```bash
/planning-workflow requirements-to-tasks requirements.md
# Outputs: tasks.md with specific, implementable tasks
```text

---

## Step 3: Tasks to GitHub Issues

Convert task breakdowns into properly structured GitHub issues.

### Task (Tasks → Issues)

I'll take a `tasks.md` file and create GitHub issues for each implementable task.

I will:

1. Analyze the `tasks.md` to extract each specific task
2. Create focused GitHub issues for individual deliverables
3. Structure issues with clear acceptance criteria and implementation approach
4. Map task dependencies as issue relationships (not timeline phases)
5. Apply descriptive labels based on task type and components
6. Ensure each necessary label, tag, or project is created before issue creation

### Issue Structure

Each GitHub issue will include:

#### Core Information

- **Clear, specific title** - What exactly will be delivered
- **Task description** - Detailed explanation of the functionality to implement
- **Acceptance criteria** - Specific, testable conditions for completion
- **Implementation approach** - Technical strategy (TDD, refactoring, new feature)

#### Technical Context

- **Required changes** - Files, modules, or systems that need modification
- **Test requirements** - What tests need to be written or updated
- **Integration considerations** - How this connects to existing functionality
- **Documentation needs** - Any docs that need creation or updates

#### Relationships

- **Prerequisite issues** - Tasks that must be completed first
- **Related issues** - Tasks that should be coordinated together
- **Follow-up opportunities** - Optional enhancements that could be done later

### Labels Applied

- **Component labels** - Based on affected systems (frontend, backend, cli, etc.)
- **Type labels** - Implementation approach (feature, refactor, bugfix, test)
- **Complexity labels** - Effort estimation (small, medium, large)

No priority levels (P0, P1, P2), milestone assignments, or timeline scheduling - just clear task organization focused on deliverables and dependencies.

### Example

```bash
/planning-workflow tasks-to-issues tasks.md
# Outputs: GitHub issues created with proper structure and relationships
```text

---

## Complete Workflow Example

```bash
# Step 1: Convert spec to requirements
/planning-workflow spec-to-requirements spec.md
# Review requirements.md

# Step 2: Break requirements into tasks
/planning-workflow requirements-to-tasks requirements.md
# Review tasks.md

# Step 3: Create GitHub issues from tasks
/planning-workflow tasks-to-issues tasks.md
# GitHub issues created and ready for implementation
```text

---

## Quick Reference

| Stage                | Input             | Output            | Focus                            |
| -------------------- | ----------------- | ----------------- | -------------------------------- |
| Spec → Requirements  | `spec.md`         | `requirements.md` | What needs to be built           |
| Requirements → Tasks | `requirements.md` | `tasks.md`        | How to build it (implementation) |
| Tasks → Issues       | `tasks.md`        | GitHub Issues     | Trackable, assignable work items |

---

## File Naming Conventions

- `spec.md` - Initial specification document
- `requirements.md` - Extracted functional & non-functional requirements
- `tasks.md` - Specific implementable development tasks
- GitHub Issues - Final trackable work items

This pipeline ensures:

- ✓ Clear requirements capture
- ✓ Technical feasibility assessment
- ✓ Proper task decomposition
- ✓ Traceable GitHub issues with dependencies
- ✓ No timeline/phase confusion - just deliverables and dependencies
````
