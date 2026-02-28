.PHONY: help install validate clean pre-commit pre-commit-install pre-commit-update dotfiles

# Default target
help:
	@echo "Available targets:"
	@echo "  install           - Install all dependencies and stow dotfiles"
	@echo "  validate          - Format and lint all files (all-in-one)"
	@echo "  clean             - Clean up generated files"
	@echo "  dotfiles           - Stow all dotfile packages into ~"
	@echo ""
	@echo "Pre-commit commands:"
	@echo "  pre-commit-install - Install pre-commit hooks"
	@echo "  pre-commit-update  - Update pre-commit hooks to latest versions"

install:
	@pnpm install
	@uv sync
	@$(MAKE) dotfiles

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

dotfiles:
	@command -v stow >/dev/null 2>&1 || { echo "stow not found — install with: brew install stow"; exit 1; }
	@for pkg in dotfiles/*/; do \
		echo "Stowing $$(basename $$pkg)..."; \
		stow -d dotfiles -t ~ $$(basename $$pkg); \
	done
