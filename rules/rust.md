---
paths:
  - "**/*.rs"
---

# Rust

## Tooling

- Use `cargo` for everything (`cargo add`, `cargo run`, `cargo clippy`, `cargo fmt`)
- New projects: `cargo new` (binary) or `cargo new --lib` (library)
- Run `cargo clippy` before committing — treat warnings as errors
- NEVER read `Cargo.lock` unless specifically investigating dependency resolution

## Error Handling

- Use `thiserror` for library error types, `anyhow` for application-level errors
- Propagate errors with `?` — NEVER use `.unwrap()` in library code
- `.expect()` only for invariant violations with a descriptive message
- Use `.context()` from `anyhow` for meaningful error messages

## Code Patterns

- Prefer borrowing (`&T`, `&mut T`) over taking ownership when possible
- Prefer `&str` over `String` in function parameters
- Use `Vec::with_capacity()` when the size is known
- Derive common traits: `Debug`, `Clone`, `PartialEq` where appropriate
- Use iterators and combinators over explicit loops where clearer
- Pattern match exhaustively — avoid catch-all `_` when possible

## Common Mistakes to Avoid

- NEVER use `unsafe` without documenting safety invariants
- NEVER commit `dbg!()` macros or debug `println!()`
- No wildcard imports (`use module::*`) except for preludes and `use super::*` in tests
- Don't chase maximum occupancy — `#[inline]` and aggressive generics can hurt compile times for marginal gains

## Testing

- Use `#[cfg(test)]` modules with `use super::*`
- Run `cargo test` before committing
- Use `cargo fmt --check` to verify formatting

## Concurrency

- `tokio` for async runtime, `rayon` for CPU-bound parallelism
- Prefer channels (`mpsc`, `crossbeam`) for message passing
- Prefer `RwLock` over `Mutex` when reads dominate
