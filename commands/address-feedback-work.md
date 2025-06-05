# Address GitHub Pull Request Feedback

GitHub Pull Request: $ARGUMENTS

## Task

I'll examine the pull request and comments to understand the feedback and any changes needed.

I will:

1. Read the linked GitHub pull request to understand the changes
2. Find and read any related comments on the pull request
3. Review the code changes in the pull request
4. Look for any linked Linear issues or acceptance criteria
5. Identify any problems or areas for improvement
6. Make the necessary changes to the code
7. Add comments to the pull request to explain the changes made
8. Ensure that the code adheres to the project's coding standards and guidelines
9. Test the changes to ensure they work as expected
10. Submit the pull request for review

This ensures the pull request meets the requirements and adheres to our coding standards.

## Command Reference

```bash
# Get basic PR info including title, description, author and top-level comments
gh pr view <number> --json title,body,author,comments

# Get formal reviews with review comments
gh pr view <number> --json reviews

# Get all inline code comments (comments on specific lines of code)
gh api repos/<owner>/<repo>/pulls/<number>/comments

# Get conversation tab comments (if PR has additional discussion)
gh api repos/<owner>/<repo>/issues/<number>/comments

# Combined comprehensive command to get most PR information at once
gh pr view <number> --json title,body,author,commits,files,comments,reviews

# View the issue linked to the PR
linear-cli issue <issue-id>
```
