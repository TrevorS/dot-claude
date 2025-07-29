# Validate Project

Auto-detect and run formatter, linter, type checker, and tests for the current project.

## Task

Use the @project-validator agent to systematically validate the current project. The agent will handle all context discovery and validation execution autonomously.

The agent will:

- **Auto-detect** project type and available tooling
- **Execute** validation steps in proper order (format → lint → typecheck → test)
- **Update** local CLAUDE.md with discovered tool information
- **Report** results and handle any failures appropriately
