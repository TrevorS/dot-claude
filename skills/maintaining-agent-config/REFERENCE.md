# Maintaining Claude Code - Reference

Detailed examples and troubleshooting for Claude Code configuration.

## Creating Skills

### Design Process

Before building, clarify:

- **What**: What specific problem does this skill solve?
- **When**: What triggers would tell Claude to use it? (3-5 concrete phrases)
- **Scope**: Single capability or multiple related features?
- **Location**: Personal (`~/.claude/skills/`) or project (`.claude/skills/`)?

### Description Formula

`<What it does>. Use when <trigger1>, <trigger2>, or <trigger3>.`

- Name max 64 chars, Description max 1024 chars
- Action verbs: extract, analyze, generate, review, validate, debug, migrate
- Include file types, domain terms, and concrete trigger phrases

### Directory Structure

Minimal (single task):

```text
my-skill/
  SKILL.md
```

With reference docs:

```text
my-skill/
  SKILL.md              (main instructions - keep <200 lines)
  REFERENCE.md          (detailed patterns, examples)
```

### SKILL.md Template

```markdown
---
name: your-skill-name
description: What it does. Use when trigger1, trigger2, or trigger3.
---

# Skill Name

## Quick Start

[One-paragraph overview]

## Instructions

1. [Core steps]

## Examples

[2-3 concrete examples]

## Best Practices

- [Key guidelines]
```

### Frontmatter Options

- `name:` — display name (max 64 chars)
- `description:` — discovery text with triggers (max 1024 chars)
- `context: fork` — runs in isolated subprocess (use for heavy/destructive workflows)
- `argument-hint:` — hint for skill arguments
- `model:` — model override (e.g., `claude-sonnet-4-5`)
- `allowed-tools:` — restrict available tools

### Validation Checklist

- [ ] YAML frontmatter valid (`---` on line 1 and before content)
- [ ] Description includes 3-5 trigger phrases covering "what" + "when"
- [ ] Description could NOT describe a different skill
- [ ] Instructions are step-by-step and clear
- [ ] Examples are concrete, not abstract
- [ ] No nested references (only one level deep: SKILL.md -> REFERENCE.md)

### Common Patterns

**Single-capability skill**: One specific task (commit messages, PDF extraction)

**Multi-mode skill**: Related capabilities under one umbrella (e.g., SwiftUI: architecture, review, debugging). Keep main file 150-200 lines, use REFERENCE.md for detailed patterns.

### Anti-Patterns

- Overloaded: "Does commits, reviews code, analyzes data, generates docs..." -> Split
- Vague triggers: "Helps with stuff" -> Add 3-5 specific domain terms
- Nested references: SKILL.md -> REF.md -> DETAILS.md -> Keep flat
- Marketing language: "Amazing tool for awesome results!" -> Be specific

---

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
