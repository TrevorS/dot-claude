# Maintaining Claude Code - Reference

Detailed examples and troubleshooting for Claude Code configuration.

## Entity Type Comparison

### CLAUDE.md

**Purpose**: Global behavioral guidelines read every session

**Best for**:

- Interaction style and preferences
- Workflow patterns
- Language-specific conventions
- Anti-patterns to avoid

**When to split into rules**:

- File exceeds 150 lines
- Different sections have different owners
- Rules apply to specific file paths

### .claude/rules/

**Purpose**: Modular, path-scoped rules

**Best for**:

- Large projects with many guidelines
- Path-specific rules (e.g., API files vs UI files)
- Team-shared conventions

**Structure**:

```text
.claude/rules/
  api.md           # Rules for src/api/**
  frontend.md      # Rules for src/ui/**
  testing.md       # Testing conventions
```

**Path scoping**:

```yaml
---
paths: src/api/**/*.ts
---
# API Rules
- All endpoints must validate input
```

### Skills

**Purpose**: Auto-detected capabilities Claude uses when relevant

**Best for**:

- Reusable capabilities across projects
- Domain expertise (SwiftUI, Svelte, PDF handling)
- Multi-step workflows

**Description formula**:

```text
<What it does>. Use when <trigger1>, <trigger2>, or <trigger3>.
```

**Examples**:

Good:

```yaml
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files, forms, or document extraction.
```

Bad:

```yaml
description: Helps with documents
```

### Commands

**Purpose**: User-invoked workflows via /command

**Best for**:

- Explicit user actions
- Workflows that shouldn't run automatically
- Operations requiring user confirmation

**When to use command vs skill**:

- Command: User should explicitly choose when to run
- Skill: Claude should auto-detect and use

### Hooks

**Purpose**: Automated scripts at specific events

**Best for**:

- Validation before tool use
- Enforcement of security policies
- Automated notifications

**Events**:

- PreToolUse: Before any tool runs
- PostToolUse: After tool completes
- Stop: When Claude finishes

**Exit codes**:

- 0: Success, continue
- 2: Block action, show error
- Other: Non-blocking warning

### Agents

**Purpose**: Specialized task personas with isolated context

**Best for**:

- Complex multi-step workflows
- Tasks needing specific tool sets
- Different model requirements (haiku for speed, opus for complexity)

## Troubleshooting

### Skill Not Being Discovered

1. Check YAML syntax - must have `---` on line 1
2. Verify description includes trigger words
3. Test with exact phrases from description
4. Check for competing skills with similar descriptions

### CLAUDE.md Growing Stale

Avoid including:

- Specific version numbers
- Completion percentages
- Date-specific information
- Dependency lists that change often

Include:

- Patterns and principles
- Tool preferences
- Workflow guidelines
- Anti-patterns

### Hook Not Running

1. Verify file is executable (`chmod +x`)
2. Check timeout setting (default 60s)
3. Test script manually first
4. Check exit codes (0 for success)

## Validation Checklists

### CLAUDE.md Checklist

- [ ] Uses ASCII characters only (no em-dashes)
- [ ] No content that will quickly grow stale
- [ ] Organized with clear headings
- [ ] Specific and actionable guidelines
- [ ] Anti-patterns clearly stated

### Skill Checklist

- [ ] Valid YAML frontmatter
- [ ] Description under 1024 chars
- [ ] Includes 3-5 trigger phrases
- [ ] Not duplicating another skill
- [ ] References only one level deep

### Command Checklist

- [ ] Clear purpose in filename
- [ ] Uses $ARGUMENTS if parameterized
- [ ] Not duplicating a skill
- [ ] User should explicitly invoke

## Migration Patterns

### CLAUDE.md to Rules

When CLAUDE.md exceeds 150 lines:

1. Identify logical groupings (git, python, testing)
2. Create `.claude/rules/` directory
3. Move each section to its own file
4. Keep interaction/workflow in CLAUDE.md
5. Add path frontmatter where applicable

### Command to Skill

When a command should auto-trigger:

1. Create skill directory in `.claude/skills/`
2. Write SKILL.md with YAML frontmatter
3. Add trigger phrases to description
4. Remove or redirect old command

### Consolidating Similar Skills

When you have multiple overlapping skills:

1. Identify the primary capability
2. Add modes to single skill (like swiftui-engineer)
3. Use "Mode of Operation" pattern
4. Remove redundant skills
