# SKILL.md Templates

Use these templates as starting points for new skills. Customize based on your specific needs.

## Simple Single-File Skill

Use this for focused skills that don't need supporting files or scripts.

```yaml
---
name: Your Skill Name
description: What it does. Use when specific triggers or when user mentions specific terms.
---

# Your Skill Name

## Overview

Brief explanation of what this skill does and the problem it solves.

## Instructions

1. Step-by-step guidance for how Claude should approach tasks
2. Include specific techniques or approaches to use
3. Explain error handling or edge cases

## Examples

Show concrete examples of:
- Typical input
- Expected output
- Common use patterns

## Best Practices

- Specific do's and don'ts
- Common pitfalls to avoid
- When NOT to use this skill
```

## Multi-File Skill with Documentation

Use this when the skill needs supporting reference docs.

```yaml
---
name: Your Skill Name
description: What it does and key features. Use when specific triggers.
---

# Your Skill Name

## Quick Start

For common usage, see [QUICK_START.md](QUICK_START.md).

For detailed reference, see [REFERENCE.md](REFERENCE.md).

## Overview

What problem this solves and when to use it.

## Instructions

Core workflow:

1. First step
2. Second step
3. Final step

## Examples

Basic examples here; advanced examples in [REFERENCE.md](REFERENCE.md).

## When NOT to Use

- Cases where this skill doesn't apply
- Situations to avoid
- Related skills for other problems
```

## Skill with Scripts

Use this when the skill needs executable code for deterministic operations.

````markdown
---
name: Your Skill Name
description: What it does, using scripts for specific operations. Use when working with [domain] or when the user mentions [specific terms].
---

# Your Skill Name

## Overview

What this skill does and why the scripts approach works well here.

## Requirements

List any required packages or dependencies:

- Package 1: description
- Package 2: description

## Quick Start

Basic usage:

```bash
python scripts/helper.py input.txt
```
````

## Instructions

1. Understand the problem
2. Run the appropriate script:
   - `scripts/process.py` for data processing
   - `scripts/validate.py` for validation
3. Handle the output

## Available Scripts

### process.py

```bash
python scripts/process.py <input> [--option value]
```

Processes input data. See [SCRIPTS.md](SCRIPTS.md) for full documentation.

### validate.py

```bash
python scripts/validate.py <input>
```

Validates input structure and returns detailed errors if found.

## Examples

Example 1: Processing a file

```bash
python scripts/process.py data.json
```

For more examples, see [SCRIPTS.md](SCRIPTS.md).

``````markdown
## Read-Only Skill (with tool restrictions)

Use this for skills that should only read files, not modify them.

`````markdown
---
name: Your Skill Name
description: Analyzes X without making changes. Use when reviewing [something] or analyzing [something].
allowed-tools: Read, Grep, Glob
---

# Your Skill Name

## Overview

This is a read-only skill. It analyzes and reports but doesn't modify files.

## Instructions

1. Read relevant files using Read tool
2. Search within files using Grep tool
3. Find files matching patterns using Glob tool
4. Analyze findings and report results

## What You Can Do

- Analyze existing code or documents
- Search for patterns or specific content
- Find files matching criteria
- Report findings and suggestions

## What You Can't Do

- Modify or edit files (intentionally restricted)
- Create new files
- Run commands that change the system

````markdown
## Workflow Skill

Use this for skills that guide multi-step processes.

```yaml
---
name: Your Skill Name
description: Guides through X workflow, including [key steps]. Use when [trigger scenario].
---

# Your Skill Name

## Workflow Overview

This skill guides you through the following steps:
1. Planning
2. Execution
3. Verification

## Prerequisites

Before starting, ensure:
- Requirement 1
- Requirement 2
- Requirement 3

## Step 1: Planning

What to think about and decide before starting:
- Decision 1
- Decision 2
- Questions to ask

## Step 2: Execution

The actual work:
- Specific approach
- Techniques to use
- Common patterns

## Step 3: Verification

How to check if it worked:
- Success criteria
- What to look for
- Troubleshooting common issues

## Examples

Walk through a complete example from start to finish.

## Troubleshooting

- Problem 1: Solution
- Problem 2: Solution
- Common mistakes to avoid
```

## Domain-Specific Template (Example: Data Analysis)

```yaml
---
name: Data Analysis
description: Analyze datasets, create visualizations, generate insights. Use when working with data analysis, spreadsheets, or when the user mentions datasets, charts, or analysis.
---

# Data Analysis Skill

## Types of Analysis

### Exploratory Analysis
- Get summary statistics
- Check for missing values
- Identify outliers
- Visualize distributions

### Comparative Analysis
- Compare groups or time periods
- Find significant differences
- Identify trends

### Predictive Analysis
- Fit models to data
- Make forecasts
- Estimate patterns

## Data Formats Supported

- CSV files
- Excel spreadsheets (.xlsx)
- JSON data
- SQL query results

## Instructions

1. Understand the data shape and content
2. Choose appropriate analysis type
3. Apply techniques specific to the data type
4. Create visualizations if applicable
5. Communicate findings clearly

## Common Patterns

### Time Series Analysis

1. Load time-series data
2. Check for trends and seasonality
3. Decompose into components
4. Visualize over time

### Categorical Comparison

1. Group by categories
2. Calculate statistics per group
3. Create comparison visualizations
4. Test for significant differences

## Examples

[Include real-world examples with data types and analyses shown]
```

## Tips for Customization

1. **Replace placeholders** in angle brackets like `<description>`
2. **Remove sections** that don't apply to your skill
3. **Add domain-specific content** relevant to what your skill does
4. **Keep examples concrete** - use real scenarios, not abstract concepts
5. **Test discovery** - verify Claude uses the skill with test prompts matching the description

## Validation Checklist

Before finalizing your SKILL.md:

- [ ] YAML frontmatter has valid syntax (--- at start and middle)
- [ ] `name` is under 64 characters
- [ ] `description` is under 1024 characters and includes triggers
- [ ] `description` includes both "what" and "when"
- [ ] Headers use markdown (# for main, ## for sections)
- [ ] Code blocks use proper syntax highlighting
- [ ] Links to supporting files use relative paths with forward slashes
- [ ] Examples are concrete and realistic
- [ ] Instructions are clear and step-by-step
````
`````
``````
