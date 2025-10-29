# Language-Specific Tooling - Reference Guide

Detailed patterns and troubleshooting for Python, TypeScript/JavaScript, and Rust projects.

## Python with `uv`

### Why `uv`?

`uv` is a fast, Rust-based Python package installer and manager. It's significantly faster than pip and handles virtual environments automatically.

### Common Commands

```bash
# Add a dependency
uv add requests

# Add a dev dependency
uv add --dev pytest-mock

# Run a command in the virtual environment
uv run python script.py
uv run pytest
uv run ruff format .

# Install all dependencies from pyproject.toml
uv sync

# Remove a dependency
uv remove requests
```text

### The command_blocker Hook

Your shell hook enforces `uv` usage:

- ❌ Blocks: `python script.py` → Use `uv run python script.py`
- ❌ Blocks: `pytest` → Use `uv run pytest`
- ❌ Blocks: `pip install` → Use `uv add`
- ✓ Allowed: `uv run <anything>`

This only activates when `pyproject.toml` exists, so non-Python projects aren't affected.

### Type Annotations Pattern

```python
from typing import Optional, List

def process_items(items: List[str], limit: Optional[int] = None) -> dict:
    """Process items with optional limit."""
    result: dict[str, int] = {}
    for item in items:
        result[item] = len(item)
    return result
```text

### Error Handling Pattern

```python
import logging

logger = logging.getLogger(__name__)

try:
    result = api.fetch_data()
except ConnectionError as e:
    logger.error(f"API connection failed: {e}")
    raise  # Re-raise at appropriate abstraction level
except ValueError as e:
    logger.warning(f"Invalid response format: {e}")
    return None  # Handle gracefully if appropriate
```text

### Testing Pattern with pytest

```python
# tests/test_processor.py
import pytest
from unittest.mock import Mock
from mymodule import processor

@pytest.fixture
def mock_api():
    api = Mock()
    api.fetch.return_value = {"status": "ok"}
    return api

def test_process_with_api(mock_api):
    result = processor(mock_api)
    assert result["status"] == "ok"
    mock_api.fetch.assert_called_once()
```text

### Validation Checklist

- [ ] All functions have type annotations
- [ ] Tests exist for critical paths
- [ ] Run `uv run ruff format .` before commit
- [ ] Run `uv run ruff check` for linting
- [ ] Run `uv run pytest` and all tests pass
- [ ] Project has `pyproject.toml` with metadata

## TypeScript/JavaScript with fnm + pnpm

### Node.js Version Management with fnm

```bash
# Check required version
cat .node-version  # e.g., "23.11.0"

# fnm automatically uses this version when cd'ing to directory
# If version isn't installed: fnm install 23.11.0

# List installed versions
fnm list
```text

### Package Management with pnpm

Why pnpm over npm or yarn?

- **Disk efficiency**: Hard links instead of copies
- **Speed**: Parallel operations
- **Strictness**: Better dependency resolution
- **Lock file**: More deterministic than yarn.lock

```bash
# Install dependencies from lock file
pnpm install

# Add a dependency
pnpm add lodash

# Add a dev dependency
pnpm add --save-dev @types/node

# Update a specific package
pnpm up lodash

# Run a script
pnpm run build
pnpm run dev
```text

### Strict TypeScript Configuration Pattern

Require in `tsconfig.json`:

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  }
}
```text

### Async/Await Pattern

```typescript
// Good: async/await is more readable
async function fetchUserData(userId: string): Promise<User> {
  try {
    const response = await api.get(`/users/${userId}`);
    return response.data;
  } catch (error) {
    console.error(`Failed to fetch user ${userId}:`, error);
    throw error;
  }
}

// Bad: Promise.then chains
fetchUserData(id)
  .then((user) => console.log(user))
  .catch((error) => console.error(error));
```text

### Template Literals Pattern

```typescript
// Good: Template literals with expressions
const name = "Teej";
const message = `Hello, ${name}! You have ${count} tasks.`;
const multiline = `
  This is a
  multiline string
  with proper formatting
`;

// Avoid: String concatenation
const message_bad = "Hello, " + name + "! You have " + count + " tasks.";
```text

### React/Vue Component Pattern

```typescript
// React with TypeScript
interface UserProps {
  userId: string;
  onUpdate: (user: User) => void;
}

export const UserCard: React.FC<UserProps> = ({ userId, onUpdate }) => {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    fetchUser(userId).then(setUser);
  }, [userId]);

  return <div>{user?.name}</div>;
};
```text

### Validation Checklist

- [ ] TypeScript compiles with `pnpm run type-check` (zero errors)
- [ ] No `any` types used
- [ ] ESLint passes: `pnpm run lint`
- [ ] Prettier formatted: `pnpm run format`
- [ ] Tests pass: `pnpm run test`
- [ ] `.node-version` file exists and matches Dockerfile/deployment

## Rust with cargo

### Why cargo?

Cargo is Rust's official package manager and build system. It handles:

- Dependency management
- Building binaries and libraries
- Running tests
- Documentation generation
- Publishing to crates.io

### Common Commands

```bash
# Create a new project
cargo new myproject
cargo new --lib mylib

# Add a dependency
cargo add serde

# Add a dev dependency
cargo add --dev criterion

# Build the project
cargo build              # Debug build (faster compile)
cargo build --release   # Release build (optimized)

# Run the project
cargo run
cargo run --release

# Run tests
cargo test
cargo test -- --show-output

# Check code without building
cargo check

# Format code
cargo fmt

# Lint with Clippy
cargo clippy

# Generate documentation
cargo doc --open
```text

### Clippy Recommendations

Clippy is Rust's linter and catches common mistakes:

```rust
// Bad: Clippy warns about this
let x = vec![1, 2, 3];
for i in 0..x.len() {
    println!("{}", x[i]);
}

// Good: Use iterator instead
let x = vec![1, 2, 3];
for item in &x {
    println!("{}", item);
}

// Run: cargo clippy
```text

### Type Safety Pattern

```rust
// Rust's type system is powerful - use it
fn calculate(a: i32, b: i32) -> i32 {
    a + b
}

// Use enums for variant types
enum Result<T, E> {
    Ok(T),
    Err(E),
}

// Pattern matching
match result {
    Ok(value) => println!("Success: {}", value),
    Err(error) => println!("Error: {}", error),
}
```text

### Error Handling Pattern

```rust
use std::io;

fn read_config(path: &str) -> Result<Config, Box<dyn std::error::Error>> {
    let contents = std::fs::read_to_string(path)?;
    let config = serde_json::from_str(&contents)?;
    Ok(config)
}

// The ? operator propagates errors up
// Much cleaner than if let Err(e) = ... checks
```text

### Testing Pattern

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_addition() {
        assert_eq!(calculate(2, 2), 4);
    }

    #[test]
    #[should_panic]
    fn test_panic() {
        panic!("This test expects a panic");
    }
}

// Run: cargo test
```text

### Cargo.toml Structure

```toml
[package]
name = "myproject"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = { version = "1.0", features = ["derive"] }
tokio = { version = "1.0", features = ["full"] }

[dev-dependencies]
criterion = "0.5"

[profile.release]
opt-level = 3
lto = true
codegen-units = 1
```text

### Validation Checklist

- [ ] Code compiles: `cargo build`
- [ ] No Clippy warnings: `cargo clippy`
- [ ] Formatted: `cargo fmt --check`
- [ ] Tests pass: `cargo test`
- [ ] Documentation builds: `cargo doc`
- [ ] Release build optimized: `cargo build --release`

## Common Pitfalls & Fixes

### Python

| Problem                                   | Solution                                     |
| ----------------------------------------- | -------------------------------------------- |
| "ModuleNotFoundError" when using `python` | Use `uv run python` instead                  |
| Type hints are ignored                    | Enable type checking in your IDE/CI          |
| Tests fail locally but pass in CI         | Check Python version with `python --version` |

### TypeScript/JavaScript

| Problem                     | Solution                                    |
| --------------------------- | ------------------------------------------- |
| "Cannot find module" errors | Run `pnpm install` to sync lock file        |
| ESLint/Prettier conflicts   | Use prettier as formatter, ESLint for logic |
| Node version mismatch       | Check `.node-version` and run `fnm install` |

### Rust

| Problem                    | Solution                                              |
| -------------------------- | ----------------------------------------------------- |
| "error: unresolved import" | Run `cargo add` for dependencies, not manual edits    |
| Lifetime errors            | Use references `&T` instead of moves when appropriate |
| Compilation takes forever  | Use `cargo check` during development                  |

## Quick Reference: Running Validation

```bash
# Python
uv run pytest && uv run ruff format . && uv run ruff check

# TypeScript/JavaScript
pnpm run test && pnpm run lint && pnpm run format

# Rust
cargo test && cargo clippy && cargo fmt
```text

Or use the project's make targets (if available):

```bash
make test    # Run all tests
make lint    # Run linter
make format  # Format code
```text
