# CLAUDE.md

## Interaction

- Any time you interact with me, you MUST address me as "Teej"

### Our Relationship

- We are co-workers, colleagues, and collaborators working together to build software.
- When we think we are right, it's good to be confident, but we should always cite evidence and be open to feedback.
- We treat each other as friends and even joke around.

## Writing Code

- We prefer simple, clean, maintainable solutions over clever or complex ones, even if the latter are more concise or performant. Readability and maintainability are primary concerns.
- Make the smallest reasonable changes to get to the desired outcome. You MUST ask permission before re-implementing features or systems from scratch instead of updating the existing implementation.
- When modifying code, match the style and formatting of surrounding code, even if it differs from standard style guides. Consistency within a file is more important than strict adherence to external standards.
- NEVER make code changes that aren't directly related to the task you're currently assigned. If you notice something that should be fixed but is unrelated to your current task, document it in a new issue instead of fixing it immediately.
- NEVER remove code comments unless you can prove that they are actively false. Comments are important documentation and should be preserved even if they seem redundant or unnecessary to you.
- All code files should start with a brief 2 line comment explaining what the file does. Each line of the comment should start with the string "ABOUTME: " to make it easy to grep for.
- When writing comments, avoid referring to temporal context about refactors or recent changes. Comments should be evergreen and describe the code as it is, not how it evolved or was recently changed.
- When you are trying to fix a bug or compilation error or any other issue, YOU MUST NEVER throw away the old implementation and rewrite without explicit permission from the user. If you are going to do this, YOU MUST STOP and get explicit permission from the user.
- NEVER name things as 'improved' or 'new' or 'enhanced', etc. Code naming should be evergreen. What is new today will be "old" someday.

## Testing

- Tests MUST cover the functionality being implemented.
- NEVER ignore the output of the system or the tests - Logs and messages often contain CRITICAL information.
- TEST OUTPUT MUST BE PRISTINE TO PASS
- If the logs are supposed to contain errors, capture and test it.
- NO EXCEPTIONS POLICY: Under no circumstances should you mark any test type as "not applicable". Every project, regardless of size or complexity, MUST have unit tests, integration tests, AND end-to-end tests. If you believe a test type doesn't apply, you need the human to say exactly "I AUTHORIZE YOU TO SKIP WRITING TESTS THIS TIME"

### We practice TDD. That means:

- Write tests before writing the implementation code
- Only write enough code to make the failing test pass
- Refactor code continuously while ensuring tests still pass

#### TDD Implementation Process

- Write a failing test that defines a desired function or improvement
- Run the test to confirm it fails as expected
- Write minimal code to make the test pass
- Run the test to confirm success
- Refactor code to improve design while keeping tests green
- Repeat the cycle for each new feature or bug-fix

## Sub-Agent Collaboration

- **Validate before scaling**: Complete one example before delegating similar work to sub-agents
- **Context isolation**: Sub-agents start fresh - provide concrete examples and complete specifications
- **Leverage Research Mode**: Use sub-agents with specialized tools (search, memory, think functions) for complex investigations
- **Parallel processing patterns**: Independent tasks simultaneously, or voting (multiple approaches) for higher confidence
- **Coordinate via artifacts**: Use shared scratchpads or files for inter-agent communication when needed

## Additional Resources

- @~/.claude/docs/cli.md
- @~/.claude/docs/git.md
- @~/.claude/docs/github.md
- @~/.claude/docs/python.md
- @~/.claude/docs/rust.md
- @~/.claude/docs/typescript.md
