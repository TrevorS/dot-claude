.PHONY: help install upgrade validate clean pre-commit pre-commit-install pre-commit-update dotfiles tpm typecheck hook-tests deps emacs-plugins

# Default target
help:
	@echo "Available targets:"
	@echo "  install           - Install all dependencies and stow dotfiles"
	@echo "  deps              - Install system packages from packages/*.txt"
	@echo "  upgrade           - Bump managed brew/cargo/luarocks packages + Emacs plugins to latest"
	@echo "  emacs-plugins     - Update Emacs packages (elpaca) headlessly"
	@echo "  validate          - Format and lint all files (all-in-one)"
	@echo "  clean             - Clean up generated files"
	@echo "  dotfiles          - Stow all dotfile packages into ~"
	@echo "  tpm               - Install tmux plugin manager"
	@echo "  typecheck         - Type check Python scripts (ty)"
	@echo "  hook-tests        - Run hooks/*.test.sh regression suites"
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
# --ignore unresolved-import: skill scripts declare deps via PEP 723 inline
# metadata, so they aren't in the project venv. pyproject.toml declares the same
# suppression under [tool.ty.rules], but ty 0.0.71 parses that key without
# applying it to unresolved-import (module resolution fails before rule mapping).
# Kept in both places: the flag works today, the config works again once fixed.
	@uv run ty check --ignore unresolved-import $$(find skills teej-skills/skills -name '*.py' -not -path '*/evals/*')

hook-tests:
	@for t in hooks/*.test.sh; do echo "-- $$t"; "$$t" || exit 1; done

validate:
	@uv run pre-commit run --all-files
	@$(MAKE) typecheck
	@$(MAKE) hook-tests

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

upgrade:
	@python3 scripts/install-deps.py --upgrade
	@$(MAKE) emacs-plugins

EMACS_INIT := $(HOME)/.config/emacs/init.el

emacs-plugins:
	@if ! command -v emacs >/dev/null 2>&1; then \
		echo "emacs not found — skipping plugin updates"; \
	elif [ ! -e "$(EMACS_INIT)" ]; then \
		echo "$(EMACS_INIT) not found — skipping plugin updates"; \
	else \
		if [ "$$(uname)" = "Darwin" ]; then \
			bundle=$$(cd "$$(dirname "$$(readlink -f "$$(command -v emacs)")")/../.." 2>/dev/null && pwd); \
			case "$$bundle" in \
				*.app) xattr -dr com.apple.quarantine "$$bundle" 2>/dev/null || true ;; \
			esac; \
		fi; \
		emacs --batch -l "$(EMACS_INIT)" -l scripts/update-emacs-plugins.el; \
	fi

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
