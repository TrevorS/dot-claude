---
paths:
  - "**/*.go"
---

# Go

## Tooling

- New projects: `go mod init`
- Run `go fmt` and `go vet` before committing
- Use `staticcheck` or `golangci-lint` if available in the project

## Error Handling

- Always check errors — NEVER use `_` to discard errors
- Wrap errors with context: `fmt.Errorf("doing thing: %w", err)`
- Return errors, don't panic — `panic` is only for truly unrecoverable situations
- Use `errors.Is()` and `errors.As()` for error inspection

## Code Patterns

- Keep interfaces small — one or two methods is ideal
- Accept interfaces, return structs
- Use table-driven tests with `t.Run()` subtests
- Prefer `context.Context` as the first parameter for functions that do I/O
- Use `defer` for cleanup (closing files, releasing locks)

## Common Mistakes to Avoid

- NEVER use `init()` functions for complex logic — keep them trivial or avoid entirely
- Don't over-abstract — Go favors explicit, readable code over DRY
- Avoid package-level variables (global state)
- Don't return concrete types from constructors if an interface would do

## Testing

- Use the standard `testing` package
- Run with `go test ./...`
- Use `testify/assert` or `testify/require` if the project already uses them
