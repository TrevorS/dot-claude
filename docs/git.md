# Git and Version Control Instructions

## Basic Git Workflow

- Use temporary files for commit messages and PR bodies to avoid shell escaping issues
- Write commit messages that focus on "why" rather than "what"
- Follow existing commit message style by checking recent git log
- Never update git config without explicit permission
- Do not push to remote repository unless explicitly asked

## Commit Messages and Pull Request Bodies

**Always use temporary files** to avoid shell escaping issues and ensure clean content:

### For commit messages

```bash
# Create temporary file with commit message
echo "Add feature: implement user authentication

- Add login/logout functionality
- Implement JWT token handling
- Add user session management" > /tmp/commit-msg.txt

# Use the file for commit, then clean up
git commit -F /tmp/commit-msg.txt
rm /tmp/commit-msg.txt
```

### For pull request bodies

```bash
# Create temporary file with PR body
echo "## Summary
- Implement user authentication system
- Add comprehensive test coverage for auth flow

## Test Plan
- [x] Unit tests for authentication logic
- [x] Integration tests with mocked responses
- [x] Manual testing of login/logout flow" > /tmp/pr-body.md

# Create PR using the file, then clean up
gh pr create --title "Add user authentication" --body-file /tmp/pr-body.md
rm /tmp/pr-body.md
```

### For GitHub issues

```bash
# Create temporary file with issue content
echo "## Description
Implement user authentication system with JWT tokens.

## Acceptance Criteria
- [ ] Users can log in with email/password
- [ ] JWT tokens are properly managed
- [ ] Session state is maintained across requests" > /tmp/issue-body.md

# Create/update issue using the file, then clean up
gh issue create --title "Feature: User authentication" --body-file /tmp/issue-body.md
rm /tmp/issue-body.md
```

### Benefits of this approach

- Avoids shell escaping issues with special characters
- Prevents `eval`/injection vulnerabilities
- Makes content easier to review and edit
- Cleaner command history
- More reliable automation

## Feature Branch Workflow

### Claude Commands with Branch Safety

- **/implement-issue**: Automatically creates feature branches and enforces proper workflow
- **/commit-and-push**: Checks for protected branches and ensures upstream tracking
- **/create-feature-branch**: Creates properly named feature branches with GitHub integration
- **/switch-to-feature**: Moves work from protected branches to feature branches safely

### Branch Protection

- **Automatic Detection**: Claude detects when you're on main/master/dev
- **Branch Naming**: Uses conventional format (feature/, fix/, chore/)
- **GitHub Integration**: Fetches issue details for proper branch naming
- **Safety Hooks**: Warns before committing to protected branches

### Workflow Pattern

1. Start work: `/create-feature-branch description` or `/implement-issue <number>`
2. Develop with proper TDD and testing
3. Commit and push: `/commit-and-push`
4. Create PR: Commands handle upstream tracking automatically

## Code Review Practices

- Review all staged changes before committing
- Check git status and git diff to understand what will be committed
- Analyze commit history to follow repository's commit message style
- Look for sensitive information that shouldn't be committed
- Ensure commits accurately reflect changes and their purpose
- Run lint and typecheck commands before finalizing code changes
- When reviewing self-authored pull requests, leave comments instead of reviews
