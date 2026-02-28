---
paths:
  - "**/*.py"
  - "**/*.pyi"
---

# Python

## Package Management

- Use `uv` for everything (`uv add`, `uv remove`, `uv run`, `uv sync`)
- NEVER use `pip install` — use `uv add` for project deps, `uv run --with` or `uvx --with` for one-off tools
- New projects: `uv init` (or `uv init --lib` for libraries)
- HuggingFace downloads: `uv run --with huggingface_hub hf download <repo> --local-dir <path>`
- One-off scripts with deps: `uvx --with pkg1 --with pkg2 python3 -c "..."`
- PEP 723 inline scripts: `#!/usr/bin/env -S uv run --script` header with `# /// script` deps block

## Code Quality

- Type annotations required for all function params and returns
- Use `ruff` for formatting and linting (replaces black, isort, flake8)
- Prefer `pathlib.Path` over string paths
- Use f-strings for string formatting
- Use `is` for comparing with `None`, `True`, `False`

## Common Mistakes to Avoid

- NEVER use mutable objects (lists, dicts) as default argument values
- NEVER use bare `except:` — catch specific exceptions
- NEVER silently swallow exceptions without logging
- No `from module import *` in non-test code

## Testing

- Framework: `pytest` + `pytest-mock`, run with `uv run pytest`
- Use context managers (`with`) for resource cleanup and file handling

## Error Handling

- Use `logging` module, not `print()`, for error reporting
- Provide meaningful error messages with context
- Use context managers for resource management
