# Description Best Practices

Effective descriptions enable Claude to discover your skill automatically. The description is your skill's "first impression"—it needs to match how users naturally describe problems.

## Formula: What + When

```text
<CAPABILITY>. Use when <TRIGGER_PATTERN> or <TRIGGER_PATTERN>
```

**Example**:

```text
Generate clear, focused commit messages from git diffs.
Use when creating commits, reviewing staged changes, or explaining code changes.
```

## Anatomy of a Good Description

### Part 1: Capability Statement (What it does)

Start with what the skill does, using action verbs:

- ✅ "Extract text and tables from PDF files"
- ✅ "Generate Excel spreadsheets with charts and formulas"
- ❌ "Helps with documents" (too vague)
- ❌ "For working with files" (too broad)

**Use precise verbs**:

- Extract, parse, analyze, process (data operations)
- Generate, create, write, compose (content creation)
- Transform, convert, format, structure (data transformation)
- Validate, check, verify, test (validation)

### Part 2: Trigger Patterns (When to use it)

Include 2-3 specific scenarios that indicate the skill should be used:

**Pattern**: "Use when [user action] or when [specific terms mentioned]"

**Examples**:

```text
Use when working with Excel files, creating data dashboards,
or analyzing spreadsheet data.
```

```text
Use when the user mentions PDFs, forms, document extraction,
or merging multiple documents.
```

```text
Use when writing commit messages, reviewing staged changes,
or explaining code modifications.
```

### Part 3: Specific Trigger Words

Include file types, domain terms, and common phrasings:

❌ **Missing specificity**:

```text
description: Helps analyze data
```

✅ **With triggers**:

```text
description: Analyze Excel spreadsheets, create pivot tables,
generate charts. Use when working with .xlsx files, spreadsheets,
data analysis, pivot tables, or creating reports.
```

## Trigger Word Categories

### File Types

- "PDF files", ".pdf"
- "Excel files", ".xlsx", "spreadsheets"
- "Word documents", ".docx"
- "JSON", "CSV files"
- "Python files", ".py"

### Domain Terms

- **Git**: commits, diffs, staged changes, branches, rebasing
- **Data**: spreadsheets, databases, queries, analysis, pivot
- **Documents**: forms, extraction, merging, formatting, pages
- **Code**: testing, debugging, refactoring, optimization

### User Actions

- "When creating...", "When writing...", "When analyzing..."
- "When reviewing...", "When debugging..."
- "When extracting...", "When generating..."

### Problem Statements

- "I need to...", "Help me...", "How do I..."
- These often appear in user requests

## Length Constraints

- **name**: 64 characters max (count carefully!)
- **description**: 1024 characters max

**Measuring**:

```text
# For name (max 64)
"Generating Commit Messages" = 28 chars ✅
"Generate Very Long Names That Might Exceed Our Limits Unnecessarily" = way too long ❌

# For description (max 1024)
Usually safe if it's 3-4 sentences with specific details
```

## Examples by Domain

### Git/Version Control

```yaml
---
name: Commit Message Generator
description: Write clear commit messages from staged changes.
Use when creating commits, reviewing staged files, or explaining
what changed in your code.
---
```

### PDF Processing

```yaml
---
name: PDF Processing
description: Extract text and tables from PDF files, fill forms,
merge documents. Use when working with PDF files or when the user
mentions PDFs, forms, document extraction, or merging documents.
---
```

### Data Analysis

```yaml
---
name: Excel Data Analysis
description: Analyze spreadsheets, create pivot tables, generate
charts and reports. Use when working with Excel files, analyzing
tabular data, .xlsx files, or creating data visualizations.
---
```

### Code Review

```yaml
---
name: Code Reviewer
description: Review code for best practices, potential bugs, and
performance issues. Use when reviewing code, checking pull requests,
analyzing code quality, or suggesting improvements.
---
```

### Custom Workflow

```yaml
---
name: Setup Assistant
description: Configure development environments, install dependencies,
and verify setup. Use when setting up projects, installing tools,
testing configurations, or troubleshooting setup issues.
---
```

## Anti-Patterns (What NOT to do)

### ❌ Too vague

```text
description: Helps with stuff
```

**Why it fails**: "Stuff" could mean anything. Claude has no trigger pattern.

### ❌ Only describes capability, missing triggers

```text
description: Generates spreadsheets
```

**Why it fails**: When should Claude use it? The user doesn't know to ask.

### ❌ Overloaded with unrelated features

```text
description: Process documents, analyze data, generate reports,
manage files, create presentations, handle emails, and more.
```

**Why it fails**: This isn't a skill, it's a toolkit. Break it into separate skills.

### ❌ Marketing language

```text
description: Amazing tool for doing cool stuff with your data!
```

**Why it fails**: Claude doesn't respond to enthusiasm. Be specific.

### ❌ Too technical without user-facing triggers

```text
description: Implements RPC protocol handlers with async/await
patterns for distributed systems
```

**Why it fails**: Users won't say "RPC protocol handlers". Match user language.

## Testing Your Description

Ask yourself:

1. **Is it specific?** Could it describe a different skill? If yes, make it more specific.
2. **Does it answer "when"?** Can a user naturally match their problem to this skill?
3. **Are trigger words there?** Would a user mention those specific terms?
4. **Is it concise?** Could you remove any words without losing meaning?

**Test prompts** to validate discovery:

For "Commit Message Generator":

- ✅ "Write a commit message for these changes"
- ✅ "I need to commit this code, what's a good message?"
- ✅ "Help me create a clear commit"
- ❌ "Analyze my code" (different skill territory)

For "PDF Processing":

- ✅ "Extract text from this PDF"
- ✅ "I need to merge several PDFs"
- ✅ "Fill out this PDF form"
- ❌ "Analyze my spreadsheet" (different skill)

## Iteration

Your first description might not be perfect. If Claude doesn't use your skill when you expect:

1. Check YAML syntax first (common issue)
2. Make the trigger words more specific
3. Add domain terms users actually use
4. Test with more natural language phrasings

Track iterations:

```markdown
## Version History

- v1.1: Added "staging", "branches" to trigger words
- v1.0: Initial release
```
