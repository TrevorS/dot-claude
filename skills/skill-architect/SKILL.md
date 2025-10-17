---
name: Skill Architect
description: Create new Agent Skills with proper structure, effective descriptions, and discoverable triggers. Use when building custom Skills, packaging expertise as reusable capabilities, or designing new skill-based workflows.
---

# Skill Architect

## Workflow

1. **Understand requirements** - Ask: what, when triggered, needed files/scripts
2. **Design structure** - Location (personal/project) + supporting files
3. **Write description** - Include what + when with specific triggers
4. **Generate SKILL.md** - YAML frontmatter + clear instructions
5. **Create supporting files** - Templates, scripts, reference docs
6. **Generate test prompts** - Verify discovery works

## Key Principles

**Discovery-first**: Description must include what the skill does AND specific triggers
**Progressive disclosure**: Split content across files—load only what's needed
**Focused scope**: One skill = one capability

## Skill Structure

```text
my-skill/
├── SKILL.md                 (required - main instructions)
├── SUPPORTING_FILE.md       (optional - additional docs)
└── scripts/
    └── helper.py            (optional - executable scripts)
```

### SKILL.md Requirements

**YAML Frontmatter**:

- `name`: 1-64 characters, descriptive and concise
- `description`: 1-1024 characters, include what AND when to use

**Content**:

- Clear instructions for Claude to follow
- Examples showing typical usage
- References to supporting files using markdown links

## Writing Effective Descriptions

See [BEST_PRACTICES.md](BEST_PRACTICES.md) for detailed guidance.

**Formula**: `<What it does>. Use when <trigger conditions> or when <specific terms mentioned>`

**Example**:

```text
Extract text and tables from PDF files, fill forms, merge documents.
Use when working with PDF files or when the user mentions PDFs,
forms, document extraction, or merging multiple documents.
```

## Execution Details

### Questions to Ask

- Purpose, trigger points, scope (personal/project)
- Inputs/outputs, supporting files needed

### Design Decisions

- Location: `~/.claude/skills/` or `.claude/skills/`
- Files: SKILL.md + supporting files
- Tool restrictions: `allowed-tools` if needed

### Description Requirements

- Core capability + 3-5 trigger phrases
- Under 1024 characters
- Covers "what" and "when"

### SKILL.md Template

- Valid YAML frontmatter
- Instructions section
- Examples section
- Links to supporting files

### Supporting Files

- Reference docs: specifications, API reference
- Scripts: deterministic operations (use forward slashes)
- Templates: boilerplate structures

### Test Prompts

Generate 3-5 natural prompts matching the description

## Common Patterns

### Simple single-file skill

```markdown
---
name: Generate Commit Messages
description: Write clear commit messages from git diffs. Use when creating commits, reviewing staged changes, or documenting code changes.
---

# Generating Commit Messages

## Instructions

1. Review the changes with `git diff --staged`
2. Write a message following these rules:
   - Summary under 50 characters
   - Present tense ("add feature" not "added feature")
   - Explain what changed and why
```

### Multi-file skill with scripts

Create skill for "PDF Processing":

- SKILL.md (main instructions)
- FORMS.md (form-filling guide)
- scripts/fill_form.py (executable)

Reference from SKILL.md:

````text
For form filling, see [FORMS.md](FORMS.md).

Run the helper script:

```bash
python scripts/fill_form.py input.pdf output.pdf
```
````

## Best Practices

1. Concrete trigger words in descriptions
2. One skill = one capability
3. Test discovery with realistic prompts
4. Add `allowed-tools` for restricted skills

## Troubleshooting

**Not discovered?** Add specific trigger words, check YAML syntax
**Slow?** Move large content to separate files, use scripts for deterministic ops
**Conflicts?** Use distinct trigger terms, specify what skill is NOT for
