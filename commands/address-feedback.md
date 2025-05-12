# Address GitHub Pull Request Feedback

GitHub Pull Request: $ARGUMENTS

## Task

I'll examine the pull request and comments to understand the feedback and any changes needed.

I will:
1. Read the linked GitHub pull request to understand the changes
2. Find and read the related GitHub issue for acceptance criteria
3. Review the `spec.md` and `plan.md` for context
4. Ensure we have the latest code from the correct branch
5. Create a plan for addressing the feedback
6. Make appropriate and necessary changes to resolve the feedback

This ensures the pull request meets the requirements and adheres to our coding standards.

## Command Reference

```bash
# View a specific pull request with detailed information
gh pr view <number> --json title,body,author,commits,files,comments

# View a specific issue with detailed information
gh issue view <number> --json title,body,labels
```
