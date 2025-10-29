# Auto-Configure Permissions

<!-- ABOUTME: Analyzes project context and configures good Claude Code permissions -->

<!-- ABOUTME: Sets repository permissions based on project type and intended workflow -->

Automatically analyze project context and configure good permissions for Claude Code based on repository state, project type, and intended workflow.

## Task

I'll detect the project context and automatically set up the right permissions.

I will:

1. **Repository Context Analysis**

   - Scan for project type indicators (package.json, pyproject.toml, Cargo.toml, Makefile)
   - Analyze git state (current branch, staged changes, recent commits, remote status)
   - Read existing CLAUDE.md for project-specific validation tools and workflows
   - Examine todo files to understand current work phase and priorities

2. **Workflow Inference**

   - **Active Development**: Feature branch + staged changes + failing tests → Full development permissions
   - **Research Mode**: Clean main branch + no staged changes + research todos → Read-heavy permissions
   - **CI/CD Context**: main/master branch + clean state + build scripts → Automation permissions
   - **Fresh Setup**: New clone + no todos + setup commands in CLAUDE.md → Setup permissions

3. **Smart Permission Configuration**

   - Generate project-specific `.claude/settings.json` with appropriate tool permissions
   - Configure file system access boundaries based on repository structure
   - Set up workflow-appropriate hooks and validation commands
   - Apply permission mode recommendations (plan, acceptEdits, bypassPermissions)

4. **Context-Adaptive Templates**
   - **Python Projects**: `uv run` commands, pytest, ruff, mypy, file editing within project
   - **Node.js Projects**: Package manager (pnpm/npm/yarn), testing, building, file editing
   - **Rust Projects**: cargo commands, clippy, fmt, testing, file editing
   - **Mixed Projects**: Combined permissions based on detected languages
   - **Documentation**: Markdown editing, link validation, minimal system access

## Detection Logic

### Project Type Detection

```bash
# Priority order for mixed projects:
1. pyproject.toml exists → Python project (add Python permissions)
2. package.json exists → Node.js project (add Node.js permissions)
3. Cargo.toml exists → Rust project (add Rust permissions)
4. Makefile exists → Make-based project (add Make permissions)
5. Multiple indicators → Mixed project (combine appropriate permissions)
```text

### Workflow Context Analysis

```bash
# Git state analysis:
- Current branch name (main/master vs feature branches)
- Staged/unstaged changes presence
- Recent commit messages and frequency
- Remote tracking status

# Work context indicators:
- Todo file count and content analysis
- CLAUDE.md project validation tools
- Recent file modification patterns
- Test failure indicators in logs
```text

### Permission Risk Assessment

- **Low Risk**: Read-only analysis, documentation updates, research tasks
- **Medium Risk**: File editing within project boundaries, testing, linting
- **High Risk**: System commands, package installation, git operations
- **Critical Risk**: Deployment, external API calls, system configuration

## Generated Permission Profiles

### Development Profile

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Edit(**/src/**/*)",
      "Edit(**/tests/**/*)",
      "Edit(**/*.md)",
      "Write(**/test_*.py)",
      "Bash(uv run *)",
      "Bash(pnpm *)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(git push *)"
    ],
    "defaultMode": "acceptEdits"
  }
}
```text

### Research Profile

```json
{
  "permissions": {
    "allow": [
      "Read",
      "LS",
      "Grep",
      "Glob",
      "Edit(**/*.md)",
      "Bash(git status)",
      "Bash(git log *)"
    ],
    "defaultMode": "plan"
  }
}
```text

### Setup Profile

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Edit",
      "Write",
      "Bash(uv init)",
      "Bash(pnpm init)",
      "Bash(cargo init)",
      "Bash(git init)",
      "Bash(make *)"
    ],
    "defaultMode": "bypassPermissions"
  }
}
```text

## Integration with Existing Commands

This command automatically runs as a prerequisite for:

- `validate-project` - Sets appropriate validation permissions first
- `implement-issue` - Configures development permissions before implementation
- `setup-github-issues` - Sets project management permissions
- Any command that requires file or system access

## Output

The command provides:

- **Detected context summary** - Project type, git state, inferred workflow
- **Applied permission profile** - Which template was selected and why
- **Permission details** - Specific tools and access levels configured
- **Recommendations** - Suggested Claude Code startup flags for this context
- **Next steps** - Context-appropriate command suggestions

## Smart Adaptation

The generated permissions adapt based on:

- **Project maturity**: New repos get broader setup permissions
- **Branch context**: Feature branches get development permissions, main gets conservative permissions
- **Work patterns**: Recent file edits indicate active development vs research
- **Tool availability**: Only enables permissions for tools that exist in the project
- **Security context**: Automatically applies more restrictive permissions for sensitive repos

This command eliminates the need for manual permission configuration while maintaining appropriate security boundaries based on the actual work context.
