# Async Code Review with Sub-Agents

## Core Concept

After implementing code, spawn **reviewer sub-agents** using the Task tool. These agents get isolated context (file + purpose only) to provide fresh perspective without implementation bias.

## Natural Integration Points

- During Feature Development
- After Refactoring
- Before Merging Pull Requests

## Task Tool Patterns

### Basic Review Task

```text
Task: "Code review of [file] - [brief purpose]. You are a code reviewer with
NO implementation history. Evaluate for: correctness, security, maintainability,
and adherence to project conventions. Provide specific feedback with line numbers."
```

### Multi-File Reviews

```text
Task: "Architecture review of src/auth/ directory. Evaluate the overall
authentication system design for: separation of concerns, code organization,
module interfaces, and potential design issues. No implementation context."
```

## Context Isolation Techniques

### What Reviewers GET

- Target file(s) content only
- Brief functional description
- Project conventions from CLAUDE.md
- Standard review criteria
- Specific focus areas (security, performance, etc.)

### What Reviewers DON'T GET

- Implementation history or iterations
- Trade-offs and constraints considered
- Alternative approaches that were tried
- Timeline or deadline pressures
- Writer's reasoning or decision process

### Reviewer Prompt Template

```text
"You are a [specialized] code reviewer performing an independent assessment.

CONTEXT ISOLATION:
- You have ZERO knowledge of how this code was implemented
- You don't know what approaches were considered or rejected
- You have no timeline or constraint context
- Focus purely on code quality and [specialization]

FILE TO REVIEW: [file path]
PURPOSE: [brief description]
FOCUS AREAS: [specific criteria]

Provide structured feedback with:
1. Overall assessment (score 1-10)
2. Specific issues with line references
3. Security/performance/quality concerns
4. Actionable improvement suggestions

Be objective and thorough - catch issues the implementer might have missed."
```

## Feedback Integration Patterns

### Immediate High-Priority Issues

```text
Reviewer finds: "Critical security issue in auth.py:45 - JWT secret hardcoded"
Action: Fix immediately before continuing
```

### Medium Priority Improvements

```text
Reviewer finds: "Performance issue in data.py:123 - O(n²) algorithm"
Action: Add to todo list for next iteration
```

### Low Priority Cleanup

```text
Reviewer finds: "Missing documentation in api.py - add JSDoc comments"
Action: Add to documentation todo list
```

### Validation of Implementation

```text
Reviewer finds: "Code quality is excellent, good error handling, clear logic"
Action: Confidence boost, continue with implementation
```

## Common Review Triggers

### Always Review

- Authentication/authorization code
- Payment/financial processing
- Data validation and sanitization
- Public API endpoints
- Security-sensitive operations

### Often Review

- Complex business logic
- Performance-critical sections
- Error handling implementations
- Third-party integrations
- Database operations

### Consider Reviewing

- Refactored legacy code
- Configuration changes
- Build/deployment scripts
- Non-trivial bug fixes

## Anti-Patterns to Avoid

### ❌ Reviewer with Too Much Context

```text
Task: "Review auth.py. I implemented JWT because OAuth was too complex for
our timeline, and I had to work around the existing user model limitations..."
```

### ❌ Implementation Justification in Review

```text
"The reviewer suggested using bcrypt, but I chose SHA256 because of performance
requirements..."
```

### ❌ Reviewing Trivial Changes

```text
Task: "Review this typo fix in comments"
```

### ✅ Clean Isolated Review

```text
Task: "Security review of auth.py authentication system. You have no
implementation context. Focus on JWT handling, password security, and
potential vulnerabilities."
```

## Success Metrics

- **Issues Caught**: Real problems identified by fresh perspective
- **False Positives**: Minimal suggestions that don't apply
- **Specificity**: Line-number references and actionable feedback
- **Coverage**: Different types of issues (security, performance, logic)
- **Integration Speed**: How quickly you can address feedback

The goal is leveraging isolated context to catch real issues while maintaining development velocity.
