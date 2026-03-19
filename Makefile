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
	@uv sync
	@$(MAKE) dotfiles
	@if [ -z "$$CI" ]; then $(MAKE) tpm; fi

tpm:
	@if [ -d "$(TPM_DIR)" ]; then \
		echo "TPM already installed"; \
	else \
		echo "Installing TPM..."; \
		git clone https://github.com/tmux-plugins/tpm "$(TPM_DIR)"; \
	fi
	@echo "Installing tmux plugins..."
	@"$(TPM_DIR)/bin/install_plugins"

typecheck:
	@uv run ty check skills/reading-books/book.py skills/monitoring-ci/ci-monitor.py skills/testing-whisper/transcribe.py

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

# -- Package lists --
# Strip comments and blank lines from a package list file
pkg_list = $(shell sed 's/\#.*//' $(1) | tr '\n' ' ')

deps:
	@case "$$(uname)" in \
		Darwin) \
			if command -v brew >/dev/null 2>&1; then \
				echo "Installing Homebrew packages..."; \
				brew install $(call pkg_list,packages/brew.txt); \
			else \
				echo "brew not found — skipping brew packages"; \
			fi ;; \
		Linux) \
			if command -v apt >/dev/null 2>&1; then \
				echo "Installing apt packages..."; \
				sudo apt install -y $(call pkg_list,packages/apt.txt); \
			else \
				echo "apt not found — skipping apt packages"; \
			fi ;; \
	esac
	@if command -v luarocks >/dev/null 2>&1; then \
		echo "Installing LuaRocks packages..."; \
		for pkg in $(call pkg_list,packages/luarocks.txt); do \
			if luarocks show $$pkg >/dev/null 2>&1; then \
				echo "  $$pkg already installed"; \
			else \
				sudo luarocks install $$pkg; \
			fi; \
		done; \
	else \
		echo "luarocks not found — skipping luarocks packages"; \
	fi
	@if command -v cargo >/dev/null 2>&1; then \
		echo "Installing cargo packages..."; \
		for pkg in $(call pkg_list,packages/cargo.txt); do \
			if cargo install --list | grep -q "^$$pkg "; then \
				echo "  $$pkg already installed"; \
			elif command -v cargo-binstall >/dev/null 2>&1 && [ "$$pkg" != "cargo-binstall" ]; then \
				cargo binstall -y $$pkg; \
			else \
				cargo install $$pkg; \
			fi; \
		done; \
	else \
		echo "cargo not found — skipping cargo packages"; \
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
			echo "Stowing $$name..."; \
			stow --adopt -d dotfiles -t ~ $$name; \
		done; \
	fi
