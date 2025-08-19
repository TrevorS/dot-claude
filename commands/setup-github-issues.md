# Sets up complete GitHub project infrastructure from any `issues.md` file

<!-- ABOUTME: Creates complete GitHub project infrastructure from issues.md files -->

<!-- ABOUTME: Sets up labels, milestones, project boards, and issues with proper relationships -->

Set up GitHub project from issues file: $ARGUMENTS

I'll analyze the provided `issues.md` file and create complete GitHub project infrastructure including labels, milestones, project board, and all issues with proper relationships.

I will:

1. **Auto-configure permissions** by running `/auto-permissions` to ensure appropriate GitHub and project management access
2. **Parse and analyze the issues file** using Claude's analysis capabilities
3. **Extract project structure** including labels, milestones, and issue relationships
4. **Create GitHub labels** with appropriate colors and descriptions
5. **Set up milestones** with calculated due dates based on project phases
6. **Create GitHub project board** with custom fields for tracking
7. **Generate all issues** with proper labels, milestones, and descriptions
8. **Link issue dependencies** through comments and references
9. **Provide complete summary** of created resources

## Prerequisites

- The `gh` CLI is installed and authenticated
- You're in the root directory of a GitHub repository
- The repository already exists on GitHub
- The `issues.md` file exists and is properly formatted

## Process Overview

### Phase 1: Analysis & Extraction

- Read and parse the `issues.md` file
- Extract unique labels, milestones, and project metadata
- Identify issue relationships and dependencies
- Validate GitHub CLI authentication and repository access

### Phase 2: Infrastructure Setup

- Create all required labels with smart color coding
- Set up project milestones with appropriate due dates
- Create GitHub project board with custom fields
- Configure project board columns and workflows

### Phase 3: Issue Creation

- Create all issues with proper titles and descriptions
- Apply appropriate labels and milestone assignments
- Link related issues through comments
- Set up dependency relationships

### Phase 4: Finalization

- Add all issues to the project board
- Configure project board fields and statuses
- Write complete setup summary
- Validate all created resources

## Label Color Scheme

The command uses intelligent color coding for labels:

- **Component labels** (Blue shades): `#0052CC` to `#5E9FD8`
- **Type labels** (Green shades): `#0E8A16` to `#28A745`
- **Size labels** (Purple shades): `#5319E7` to `#B392F0`
- **Priority labels** (Orange/Red shades): `#FBCA04` to `#D73A49`

## Sub-Agent Coordination

This command leverages sub-agents for parallel processing while maintaining context:

1. **Analysis Agent**: Extracts and organizes all project metadata
2. **Setup Agent**: Creates labels, milestones, and project board
3. **Issue Creation Agent**: Processes issue creation in batches
4. **Dependency Agent**: Links issues and sets up relationships

All agents maintain shared context about the project structure to ensure consistency.

## Error Handling

- Validates GitHub CLI authentication before starting
- Checks for existing labels/milestones to avoid duplicates
- Handles rate limiting with appropriate delays
- Provides detailed error messages for troubleshooting
- Saves progress state for recovery from failures

## Output

The command provides:

- Real-time progress updates during setup
- Detailed summary of all created resources
- Links to the project board and key issues
- Statistics on labels, milestones, and issues created
- Any warnings or recommendations for next steps

This command integrates seamlessly with the existing workflow:
`spec-to-requirements.md` → `requirements-to-tasks.md` → `tasks-to-issues.md` → **`setup-github-issues.md`**
