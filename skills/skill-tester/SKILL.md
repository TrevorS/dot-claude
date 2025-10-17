---
name: Skill Tester
description: Verify and test Agent Skills for correct structure, discoverability, and functionality. Use when testing new skills, debugging why a skill isn't being triggered, or validating skill quality before deployment.
allowed-tools: Read, Grep, Glob
---

# Skill Tester

## Validation Types

1. **Structure** - YAML, required fields, character limits
2. **Discoverability** - Description triggers skill appropriately
3. **Functionality** - Test scenarios verify skill works

## Usage

Provide path to SKILL.md, then:

- Verify structure and YAML syntax
- Analyze description for discovery patterns
- Generate positive/negative test prompts
- Suggest improvements

## Validation Checklist

### Structure Validation

- [ ] YAML frontmatter starts with `---` on line 1
- [ ] YAML frontmatter ends with `---` before content
- [ ] `name` field present and under 64 characters
- [ ] `description` field present and under 1024 characters
- [ ] Markdown headers use proper syntax (`#` for main, `##` for sections)
- [ ] Code blocks have language specified
- [ ] Links to supporting files are relative paths with forward slashes
- [ ] All referenced files exist in the skill directory

### Discovery Validation

**Effective**: Clear capability + trigger phrases + 3-5 concrete terms + "what" and "when"
**Weak**: Only capability, vague language, too many features, marketing language

### Functionality Validation

- [ ] Clear step-by-step instructions
- [ ] Realistic examples with appropriate syntax
- [ ] Edge cases/limitations documented
- [ ] Required scripts/tools mentioned

## Test Prompts

**Positive (should trigger)**: Natural phrasings with domain terms from description
**Negative (shouldn't trigger)**: Related but different tasks, other domains

## Common Issues & Fixes

### Not discovered

- **YAML**: Check `---` markers, no tabs, quote special chars
- **Description**: Add trigger words, 3-5 concrete terms, covers "what" + "when"
- **Permissions**: Readable SKILL.md, executable scripts

### Wrong skill triggered

Make descriptions distinct with different triggers. Use specific domain terms, not generic language.

### Description too long

Limit: 1024 chars. Prioritize: core capability + top 3 triggers. Remove examples/secondary triggers.

### Character limits

Name: 64 max | Description: 1024 max (includes spaces/punctuation)

## Testing Workflow

1. **Structural**: Verify YAML, required fields, character limits, referenced files exist
2. **Discovery**: Extract triggers, generate positive/negative prompts, assess specificity
3. **Functionality**: Check clarity, examples, limitations, focused scope
4. **Recommendations**: Suggest fixes for structure, trigger words, or instructions

## Examples

### Well-Structured

```yaml
name: Commit Message Generator
description: Generate clear commit messages from staged changes.
Use when creating commits, reviewing staged files, or writing git commit messages.
```

✅ 27 chars name, ~130 chars description, clear triggers, test: "Write a commit message for my staged changes"

### Weak

```yaml
name: Helper
description: Helps with stuff
```

❌ Vague name, no specificity, no triggers. Fix: Specify what "stuff" means.

## Best Practices

Test early, use realistic prompts, iterate on descriptions, document limitations
