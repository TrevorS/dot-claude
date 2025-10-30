# Address Pull Request Feedback

<!-- ABOUTME: Addresses pull request feedback systematically with implementation and testing -->
<!-- ABOUTME: Analyzes review comments and implements requested changes with validation -->

Pull Request: $ARGUMENTS

## Task

I'll understand the feedback context and figure out the best approach for addressing pull request feedback.

I will:

1. **Auto-detect issue tracking system** - Check if this is a GitHub PR (gh CLI) or Linear PR (linear-cli)
2. **Read the pull request** to understand the changes and context
3. **Find related issue/ticket** for acceptance criteria and requirements
4. **Review project documentation** (`spec.md`, `requirements.md`, `CLAUDE.md`) for context
5. **Ensure correct branch state** - pull latest changes and verify working directory
6. **Analyze feedback systematically** - categorize comments by type (blocking, suggestions, nitpicks)
7. **Create focused implementation plan** - address feedback efficiently without scope creep
8. **Make targeted changes** - resolve feedback while maintaining code quality
9. **Test changes thoroughly** - ensure fixes don't break existing functionality
10. **Update PR with explanations** - document changes made and reasoning

This ensures complete feedback resolution that meets requirements and maintains code quality.

## Auto-Detection Logic

The command automatically detects the issue tracking system:

- **GitHub PRs**: Uses `gh pr view` and `gh issue view` commands
- **Linear PRs**: Uses `linear-cli issue` and looks for Linear issue references

## CLI References

**GitHub PR Operations**: See `@github-cli` skill for:

- Viewing PR with full details (`gh pr view`)
- Getting review comments (`gh pr view --json reviews`)
- Getting inline code comments (`gh api repos/.../comments`)
- Viewing related issues (`gh issue view`)

**Linear Issue Operations**: See `@linear-cli` skill for:

- Viewing Linear issues (`linear-cli issue`)
- Listing issues (`linear-cli issues`)
- Searching for issues by identifier

## Safety Protocol

- **Branch Protection**: Check current branch and avoid direct commits to main/master
- **Change Scope**: Address only feedback-related issues, document unrelated findings
- **Test Coverage**: Ensure changes don't break existing functionality
- **Documentation**: Update relevant docs if changes affect public APIs
