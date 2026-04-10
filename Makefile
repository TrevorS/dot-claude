.PHONY: help install validate clean pre-commit pre-commit-install pre-commit-update dotfiles tpm typecheck deps

# Default target
help:
	@echo "Available targets:"
	@echo "  install           - Install all dependencies and stow dotfiles"
	@echo "  deps              - Install system packages from packages/*.txt"
	@echo "  validate          - Format and lint all files (all-in-one)"
	@echo "  clean             - Clean up generated files"
	@echo "  dotfiles          - Stow all dotfile packages into ~"
	@echo "  tpm               - Install tmux plugin manager"
	@echo "  typecheck         - Type check Python scripts (ty)"
	@echo ""
	@echo "Pre-commit commands:"
	@echo "  pre-commit-install - Install pre-commit hooks"
	@echo "  pre-commit-update  - Update pre-commit hooks to latest versions"

TPM_DIR := $(HOME)/.local/share/tmux/plugins/tpm

install:
	@$(MAKE) deps
	@uv sync --quiet
	@$(MAKE) dotfiles
	@if [ -z "$$CI" ]; then $(MAKE) tpm; fi

tpm:
	@if [ ! -d "$(TPM_DIR)" ]; then \
		echo "Installing TPM..."; \
		git clone https://github.com/tmux-plugins/tpm "$(TPM_DIR)"; \
	fi
	@"$(TPM_DIR)/bin/install_plugins" | grep -v 'Already installed' || true

typecheck:
	@uv run ty check $$(find skills -name '*.py' -not -path '*/evals/*')

validate:
	@uv run pre-commit run --all-files
	@$(MAKE) typecheck

pre-commit:
	@$(MAKE) validate

clean:
	rm -rf .venv

pre-commit-install:
	@uv run pre-commit install

pre-commit-update:
	@uv run pre-commit autoupdate

deps:
	@python3 scripts/install-deps.py

MACOS_ONLY_PKGS := ghostty

dotfiles:
	@if ! command -v stow >/dev/null 2>&1; then \
		echo "stow not found — skipping dotfiles (install with: brew install stow)"; \
	else \
		for pkg in dotfiles/*/; do \
			name=$$(basename $$pkg); \
			case "$$(uname)" in \
				Darwin) ;; \
				*) echo "$(MACOS_ONLY_PKGS)" | grep -qw "$$name" && { echo "Skipping $$name (macOS only)"; continue; } ;; \
			esac; \
			stow --adopt -d dotfiles -t ~ $$name; \
		done; \
	fi
