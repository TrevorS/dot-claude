---
paths:
  - "**/*.py"
  - "**/*.pyi"
---

# Python

- Use `uv` for everything (`uv add`, `uv remove`, `uv run`, `uv sync`) -- NEVER `pip install`
- New projects: `uv init` (or `uv init --lib` for libraries)
- HuggingFace downloads: `uv run --with huggingface_hub hf download <repo> --local-dir <path>`
- One-off scripts with deps: `uvx --with pkg1 --with pkg2 python3 -c "..."`
- PEP 723 inline scripts: `#!/usr/bin/env -S uv run --script` header with `# /// script` deps block
- Use `ruff` for formatting and linting (replaces black, isort, flake8)
- Framework: `pytest` + `pytest-mock`, run with `uv run pytest`
