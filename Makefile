# ABOUTME: Makefile for formatting, linting, and managing the repository
# ABOUTME: Provides targets for running prettier, pre-commit, and dependency management

.PHONY: help install format format-check lint test clean pre-commit pre-commit-install pre-commit-update

# Default target
help:
	@echo "Available targets:"
	@echo "  install           - Install all dependencies (pnpm + uv)"
	@echo "  format            - Format code with Prettier"
	@echo "  format-check      - Check code formatting"
	@echo "  lint              - Run all linters (markdownlint + pre-commit checks)"
	@echo "  test              - Run tests"
	@echo "  clean             - Clean up generated files"
	@echo ""
	@echo "Pre-commit commands:"
	@echo "  pre-commit        - Run pre-commit on all files"
	@echo "  pre-commit-install- Install pre-commit hooks"
	@echo "  pre-commit-update - Update pre-commit hooks to latest versions"

install:
	pnpm install
	uv sync

format:
	uv run pre-commit run prettier --all-files || pnpm prettier --write "**/*.{md,json,yaml,yml,js,ts,tsx,jsx,html,css,scss}"

format-check:
	pnpm prettier --check "**/*.{md,json,yaml,yml,js,ts,tsx,jsx,html,css,scss}"

lint:
	uv run pre-commit run --all-files

test:
	@echo "No tests configured yet"

clean:
	rm -rf node_modules .pnpm-store .venv

pre-commit:
	uv run pre-commit run --all-files

pre-commit-install:
	uv run pre-commit install

pre-commit-update:
	uv run pre-commit autoupdate
