# Python Development Instructions

## Package Management

- Use `uv` for everything (`uv add`, `uv remove`, `uv run`, etc...)
- Always use `uv add` and `uv remove` commands to manage dependencies
- Never edit `pyproject.toml` directly for dependency management - let `uv` handle it
- Do not use old fashioned methods for package management like `poetry`, `pip` or `easy_install`
- Ensure there is a `pyproject.toml` file in the root directory
- If there isn't a `pyproject.toml` file, create one using `uv` by running `uv init`

## Error Handling

- Use Python exceptions for error handling
- Handle errors at the appropriate abstraction level
- Always log error context, never swallow errors silently
- Prefer explicit exception handling over generic try/except blocks
- Use specific exception types rather than catching all exceptions
- Include error scenarios in test coverage

## Code Style and Formatting

- Use type annotations for all function parameters and return values
- Follow PEP 8 style guidelines unless project conventions differ
- Use descriptive variable names following snake_case convention
- Keep line length reasonable (typically 88-120 characters)
- Use f-strings for string formatting
- Prefer list comprehensions over map/filter when readable

## Testing

- Use pytest as the testing framework unless project uses different framework
- Write tests in `test_*.py` files or `*_test.py` files
- Use descriptive test function names that explain what is being tested
- Group related tests in test classes when appropriate
- Use fixtures for test setup and teardown
- Mock external dependencies in unit tests

## Security Practices

- Never hardcode sensitive information (API keys, passwords, secrets)
- Use environment variables for configuration
- Validate all external inputs at system boundaries
- Use parameterized queries for database operations to prevent SQL injection
- Regularly update dependencies for security patches
- Use virtual environments to isolate project dependencies
