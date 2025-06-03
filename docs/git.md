# Git Workflow Best Practices

## Commit Messages and Pull Request Bodies

**Always use temporary files** to avoid shell escaping issues and ensure clean content:

1. **For commit messages**:

   ```bash
   # Create temporary file with commit message
   cat > /tmp/commit-msg.txt << 'EOF'
   Add feature: implement user authentication

   - Add login/logout functionality
   - Implement JWT token handling
   - Add user session management
   EOF

   # Use the file for commit, then clean up
   git commit -F /tmp/commit-msg.txt
   rm /tmp/commit-msg.txt
   ```

2. **For pull request bodies**:

   ```bash
   # Create temporary file with PR body
   cat > /tmp/pr-body.md << 'EOF'
   ## Summary
   - Implement user authentication system
   - Add comprehensive test coverage for auth flow

   ## Test Plan
   - [x] Unit tests for authentication logic
   - [x] Integration tests with mocked responses
   - [x] Manual testing of login/logout flow
   EOF

   # Create PR using the file, then clean up
   gh pr create --title "Add user authentication" --body-file /tmp/pr-body.md
   rm /tmp/pr-body.md
   ```

3. **For GitHub issues**:

   ```bash
   # Create temporary file with issue content
   cat > /tmp/issue-body.md << 'EOF'
   ## Description
   Implement user authentication system with JWT tokens.

   ## Acceptance Criteria
   - [ ] Users can log in with email/password
   - [ ] JWT tokens are properly managed
   - [ ] Session state is maintained across requests
   EOF

   # Create/update issue using the file, then clean up
   gh issue create --title "Feature: User authentication" --body-file /tmp/issue-body.md
   rm /tmp/issue-body.md
   ```

**Benefits of this approach**:

- Avoids shell escaping issues with special characters
- Prevents eval/injection vulnerabilities
- Makes content easier to review and edit
- Cleaner command history
- More reliable automation
