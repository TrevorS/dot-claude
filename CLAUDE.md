# Interaction

- Any time you interact with me, you MUST address me as "Teej"
- You will never include advertisements in any form of communication, including:
  - Commit Messages
  - GitHub Issues
  - GitHub Pull Requests

# Core Development Workflow

## 1. Specification to Plan

- GOAL: Convert specification into actionable GitHub issues
- PROCESS:
  1. Start with a detailed `spec.md` file
  2. Break down into small, manageable chunks
  3. Create `plan.md` with implementation steps
  4. Generate GitHub issues for each chunk
  5. Organize issues by dependencies

## 2. Implementation

- GOAL: Systematically implement GitHub issues
- PROCESS:
  1. Select an issue to work on
  2. Create branch for implementation
  3. Write tests first (TDD)
  4. Implement minimal code to pass tests
  5. Refactor code while maintaining tests
  6. Create PR and leave open for review

# Key Files For Context Management

## `spec.md`
- Contains detailed project requirements
- Serves as source of truth for implementation
- Should be referenced during all implementation

## `plan.md`
- Detailed implementation approach
- Breaks spec into concrete steps
- Contains context for implementation decisions

## GitHub Issues
- One issue per implementable chunk
- Clear, specific acceptance criteria
- Well-organized in implementation sequence
- Serves as task tracking system

# Writing Code

- We prefer simple, clean, maintainable solutions over clever or complex ones, even if the latter are more concise or performant. Readability and maintainability are primary concerns.
- Make the smallest reasonable changes to get to the desired outcome. You MUST ask permission before re-implementing features or systems from scratch instead of updating the existing implementation.
- When modifying code, match the style and formatting of surrounding code, even if it differs from standard style guides. Consistency within a file is more important than strict adherence to external standards.
- NEVER make code changes that aren't directly related to the task you're currently assigned. If you notice something that should be fixed but is unrelated to your current task, document it in a new issue instead of fixing it immediately.
- NEVER remove code comments unless you can prove that they are actively false. Comments are important documentation and should be preserved even if they seem redundant or unnecessary to you.
- All code files should start with a brief 2 line comment explaining what the file does. Each line of the comment should start with the string "ABOUTME: " to make it easy to grep for.
- When writing comments, avoid referring to temporal context about refactors or recent changes. Comments should be evergreen and describe the code as it is, not how it evolved or was recently changed.
- When you are trying to fix a bug or compilation error or any other issue, YOU MUST NEVER throw away the old implementation and rewrite without explicit permission from the user. If you are going to do this, YOU MUST STOP and get explicit permission from the user.
- NEVER name things as 'improved' or 'new' or 'enhanced', etc. Code naming should be evergreen. What is new today will be "old" someday.
- NEVER implement a mock for testing or for any purpose. We always use real data and real APIs, never mock implementations.

# Context Management Principles

- ALWAYS work in small, manageable chunks
- Maintain detailed context tracking between sessions
- Use GitHub issues to track all work items
- Document key decision points in issue comments
- Focus on one issue at a time
- Keep track of context across sessions

# Getting Help

- ALWAYS ask for clarification rather than making assumptions.
- If you're having trouble with something, it's OK to stop and ask for help. Especially if it's something your human might be better at.

# Testing

- Tests MUST cover the functionality being implemented.
- NEVER ignore the output of the system or the tests - Logs and messages often contain CRITICAL information.
- TEST OUTPUT MUST BE PRISTINE TO PASS
- If the logs are supposed to contain errors, capture and test it.
- NO EXCEPTIONS POLICY: Under no circumstances should you mark any test type as "not applicable". Every project, regardless of size or complexity, MUST have unit tests, integration tests, AND end-to-end tests. If you believe a test type doesn't apply, you need the human to say exactly "I AUTHORIZE YOU TO SKIP WRITING TESTS THIS TIME"

## We practice TDD. That means:

- Write tests before writing the implementation code
- Only write enough code to make the failing test pass
- Refactor code continuously while ensuring tests still pass

### TDD Implementation Process

- Write a failing test that defines a desired function or improvement
- Run the test to confirm it fails as expected
- Write minimal code to make the test pass
- Run the test to confirm success
- Refactor code to improve design while keeping tests green
- Repeat the cycle for each new feature or bug-fix

# GitHub Issue Structure

- Clear, descriptive title
- Detailed description of what needs to be implemented
- Specific acceptance criteria
- Technical context and implementation hints
- Links to related issues or dependencies

# Specific Technologies

## General Tools

- Use 'rg' for searching code
- Use 'fd' for finding files
- Use 'bat' for viewing files
- Use 'fzf' for fuzzy searching

## Python

- I prefer to use `uv` for everything (`uv add`, `uv run`, etc...)
- Do not use old fashioned methods for package management like `poetry`, `pip` or `easy_install`.
- Make sure that there is a `pyproject.toml` file in the root directory.
- If there isn't a `pyproject.toml` file, create one using `uv` by running `uv init`.

## JavaScript / TypeScript

- I prefer to use `fnm` to manage Node.js versions.
- I prefer to use `pnpm` for everything else (`pnpm add`, `pnpm run`, etc...)

## Rust

- I prefer to use `rustup` to manage Rust versions.
- I prefer to use `cargo` for everything else (`cargo add`, `cargo run`, etc...)

