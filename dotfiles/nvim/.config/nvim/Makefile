.PHONY: format lint check all

all: lint format

format:
	@echo "Formatting..."
	@stylua init.lua
	@echo "Formatted"

lint:
	@echo "Linting..."
	@luacheck init.lua
	@echo "Linted"

check:
	@echo "Checking format..."
	@stylua --check init.lua && echo "Format check passed" || (echo "Format check failed - run 'make format'" && exit 1)
	@echo "Checking lint..."
	@luacheck init.lua && echo "Lint check passed" || (echo "Lint check failed" && exit 1)
