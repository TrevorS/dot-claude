# Review GitHub Pull Request

GitHub Pull Request: $ARGUMENTS

## Task

I'll **ultrathink** in order to review this pull request against the GitHub issue requirements and execution approach.

I will:

1. Read the linked GitHub pull request to understand the changes
2. Request the user provide the related Linear issue for description and acceptance criteria
3. Ensure we have the latest code from the correct branch
4. Locate any related Linear issues or acceptance criteria
5. Analyze the diff against requirements
6. Check for TDD compliance - tests written first
7. Verify code follows style guidelines from `CLAUDE.md`
8. Assess if changes are minimal and focused
9. Confirm implementation maintains small, manageable chunks
10. Write full review but don't yet submit it

## Review Structure

- Requirements coverage check
- Code quality assessment
- Test coverage verification
- Implementation approach evaluation

This ensures the review aligns with our requirements-first implementation workflow.

## Command Reference

```bash
# View a specific pull request with detailed information
gh pr view <number> --json title,body,author,commits,files,comments

# List all pull requests in the repository
gh pr list --state all --json title,author,createdAt,updatedAt

# View all issues
linear-cli issues

# View a specific issue with detailed information
linear-cli issue <issue-id>
```
