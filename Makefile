# ABOUTME: Makefile for formatting and linting the repository
# ABOUTME: Provides targets for running prettier to format markdown and other files

.PHONY: format format-check help

# Default target
help:
	@echo "Available targets:"
	@echo "  format       - Format all files with prettier"
	@echo "  format-check - Check if files are formatted correctly"
	@echo "  help         - Show this help message"

# Format all files
format:
	pnpm prettier --write "**/*.{md,json,yaml,yml,js,ts,tsx,jsx,html,css,scss}"

# Check formatting without modifying files
format-check:
	pnpm prettier --check "**/*.{md,json,yaml,yml,js,ts,tsx,jsx,html,css,scss}"