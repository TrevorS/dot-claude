# Review GitHub Pull Request

GitHub Pull Request: $ARGUMENTS

## Task

I'll review this pull request against the GitHub issue requirements and implementation plan.

I will:
1. Read the linked GitHub pull request to understand the changes
2. Find and read the related GitHub issue for acceptance criteria
3. Review the `spec.md` and `plan.md` for context
4. Ensure we have the latest code from the correct branch
6. Analyze the diff against requirements
6. Check for TDD compliance - tests written first
7. Verify code follows style guidelines from `CLAUDE.md`
8. Assess if changes are minimal and focused
9. Confirm implementation maintains small, manageable chunks
10. Submit final recommendation (Approve/Request Changes/Block) to the pull request

## Review Structure

- Requirements coverage check
- Code quality assessment
- Test coverage verification
- Context management review
- Implementation approach evaluation

This ensures the review aligns with our specification-to-implementation workflow.

## Command Reference

```bash
# View a specific pull request with detailed information
gh pr view <number> --json title,body,author,commits,files,comments

# List all pull requests in the repository
gh pr list --state all --json title,author,createdAt,updatedAt
```
