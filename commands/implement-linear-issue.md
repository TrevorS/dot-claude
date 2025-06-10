# Implement Linear Issue

Linear issue: $ARGUMENTS

## Task

I'll **ultrathink** in order to develop a solution for this Linear issue with careful context management.

I will:

1. Read and understand the issue requirements using the Linear CLI (`linear-cli`)
2. Ensure we are on the correct branch
3. Review the repository, if useful, search online for further information
4. Write a detailed implementation plan and save it as `impl-plan.md`. Ensure that it:
   1. Follows TDD approach - write tests first
   2. Implements minimal code to pass tests
   3. Refactors while maintaining test coverage
   4. Documents key decisions in code
5. Write a pull request description including a manual test plan, save it as `pr-description.md`

## Pull Request Structure

- Title: [TEAM_NAME-TICKET_ID] Short description of the change
- Description: Detailed explanation of the changes made
- Linked Issues: Reference to the Linear issue
- Tests: Include tests that cover the new functionality
- Documentation: Update any relevant documentation

## Command Reference

```bash
# View all issues
linear-cli issues

# View a specific issue with detailed information
linear-cli issue <issue-id>
```
