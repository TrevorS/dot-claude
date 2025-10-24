# ABOUTME: Makefile for formatting, linting, and managing the repository
# ABOUTME: Provides targets for running prettier, pre-commit, and dependency management

.PHONY: help install validate clean pre-commit pre-commit-install pre-commit-update

# Default target
help:
	@echo "Available targets:"
	@echo "  install           - Install all dependencies (pnpm + uv)"
	@echo "  validate          - Format and lint all files (all-in-one)"
	@echo "  clean             - Clean up generated files"
	@echo ""
	@echo "Pre-commit commands:"
	@echo "  pre-commit-install - Install pre-commit hooks"
	@echo "  pre-commit-update  - Update pre-commit hooks to latest versions"

install:
	@pnpm install
	@uv sync

validate:
	@uv run pre-commit run --all-files

pre-commit:
	@$(MAKE) validate

clean:
	rm -rf node_modules .pnpm-store .venv

pre-commit-install:
	@uv run pre-commit install

pre-commit-update:
	@uv run pre-commit autoupdate
