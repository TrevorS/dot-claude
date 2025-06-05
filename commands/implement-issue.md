# Implement GitHub Issue

GitHub issue: $ARGUMENTS

## Task

I'll **ultrathink** in order to develop a solution for this GitHub issue with careful context management.

I will:

1. Read and understand the issue requirements
2. Create a branch for implementation
3. Follow TDD approach - write tests first
4. Implement minimal code to pass tests
5. Refactor while maintaining test coverage
6. Document key decisions in code
7. Push to GitHub and create a pull request
8. Keep the PR open for review

## Pull Request Structure

- Title: [Issue #<number>] Short description of the change
- Description: Detailed explanation of the changes made
- Linked Issues: Reference to the GitHub issue
- Tests: Include tests that cover the new functionality
- Documentation: Update any relevant documentation

**NEVER** include an advertisement or unrelated content in the pull request.

## Command Reference

```bash
# View a specific issue with detailed information
gh issue view <number> --json title,body,labels

# Search for issues by keyword
gh issue list --search "in:title <keyword>"
```
