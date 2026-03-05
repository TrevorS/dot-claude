.PHONY: help install validate clean pre-commit pre-commit-install pre-commit-update dotfiles tpm

# Default target
help:
	@echo "Available targets:"
	@echo "  install           - Install all dependencies and stow dotfiles"
	@echo "  validate          - Format and lint all files (all-in-one)"
	@echo "  clean             - Clean up generated files"
	@echo "  dotfiles          - Stow all dotfile packages into ~"
	@echo "  tpm               - Install tmux plugin manager"
	@echo ""
	@echo "Pre-commit commands:"
	@echo "  pre-commit-install - Install pre-commit hooks"
	@echo "  pre-commit-update  - Update pre-commit hooks to latest versions"

TPM_DIR := $(HOME)/.local/share/tmux/plugins/tpm

install:
	@uv sync
	@$(MAKE) dotfiles
	@$(MAKE) tpm

tpm:
	@if [ -d "$(TPM_DIR)" ]; then \
		echo "TPM already installed"; \
	else \
		echo "Installing TPM..."; \
		git clone https://github.com/tmux-plugins/tpm "$(TPM_DIR)"; \
	fi
	@echo "Installing tmux plugins..."
	@"$(TPM_DIR)/bin/install_plugins"

validate:
	@uv run pre-commit run --all-files

pre-commit:
	@$(MAKE) validate

clean:
	rm -rf .venv

pre-commit-install:
	@uv run pre-commit install

pre-commit-update:
	@uv run pre-commit autoupdate

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
			echo "Stowing $$name..."; \
			stow -d dotfiles -t ~ $$name; \
		done; \
	fi
