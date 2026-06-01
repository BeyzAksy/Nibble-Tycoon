# Lezzet İmparatorluğu — Godot 4.x project Makefile
#
# Override Godot binary:
#   make run GODOT=/path/to/Godot
#   export GODOT=/Applications/Godot.app/Contents/MacOS/Godot

SHELL         := /bin/bash
.DEFAULT_GOAL := help

PROJECT       := $(CURDIR)
GODOT_MACOS   := /Applications/Godot.app/Contents/MacOS/Godot
GODOT        ?= $(shell \
	command -v godot4 2>/dev/null || \
	command -v godot 2>/dev/null || \
	( [ -x "$(GODOT_MACOS)" ] && echo "$(GODOT_MACOS)" ))

GUT_VERSION   ?= v9.6.0
GUT_REPO      := https://github.com/bitwes/Gut.git
GUT_CMD       := $(PROJECT)/addons/gut/gut_cmdln.gd

GUT_ARGS      := -gdir=res://tests/ \
                 -gprefix=test_ \
                 -gsuffix=.gd \
                 -ginclude_subdirs \
                 -gexit

.PHONY: help info check-godot check-gut install-gut \
        run edit validate import \
        test test-unit test-integration ci \
        clean clean-editor

help: ## Show available targets
	@printf "\nLezzet İmparatorluğu — Makefile targets\n\n"
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'
	@printf "\nExamples:\n"
	@printf "  make run\n"
	@printf "  make install-gut && make test\n"
	@printf "  make GODOT=/Applications/Godot.app/Contents/MacOS/Godot validate\n\n"

info: check-godot ## Print Godot version and project paths
	@printf "Project : %s\n" "$(PROJECT)"
	@printf "Godot   : %s\n" "$(GODOT)"
	@$(GODOT) --version
	@if [ -f "$(GUT_CMD)" ]; then \
		printf "GUT     : installed (%s)\n" "$(GUT_VERSION)"; \
	else \
		printf "GUT     : not installed (run: make install-gut)\n"; \
	fi

check-godot:
	@if [ -z "$(GODOT)" ] || [ ! -x "$(GODOT)" ]; then \
		printf "Error: Godot binary not found.\n"; \
		printf "Install Godot 4.x or set GODOT=/path/to/Godot\n"; \
		exit 1; \
	fi

check-gut:
	@if [ ! -f "$(GUT_CMD)" ]; then \
		printf "Error: GUT not found at addons/gut/\n"; \
		printf "Run: make install-gut\n"; \
		exit 1; \
	fi

install-gut: check-godot ## Clone GUT (Godot Unit Test) into addons/gut
	@printf "Installing GUT $(GUT_VERSION)...\n"
	@tmpdir=$$(mktemp -d); \
	trap 'rm -rf "$$tmpdir"' EXIT; \
	git clone --depth 1 --branch "$(GUT_VERSION)" "$(GUT_REPO)" "$$tmpdir/gut-repo"; \
	rm -rf "$(PROJECT)/addons/gut"; \
	mkdir -p "$(PROJECT)/addons"; \
	cp -R "$$tmpdir/gut-repo/addons/gut" "$(PROJECT)/addons/gut"; \
	printf "GUT $(GUT_VERSION) installed at addons/gut/\n"
	@$(MAKE) import
	@printf "Enable plugin in Godot: Project → Plugins → GUT\n"

run: check-godot ## Launch the game
	"$(GODOT)" --path "$(PROJECT)"

edit: check-godot ## Open project in Godot editor
	"$(GODOT)" --path "$(PROJECT)" --editor

validate: check-godot ## Headless smoke test — project loads without crash
	"$(GODOT)" --headless --path "$(PROJECT)" --quit-after 1

import: check-godot ## Reimport all assets (fonts, textures, etc.)
	"$(GODOT)" --headless --path "$(PROJECT)" --import --quit

test: check-godot check-gut ## Run all GUT tests (unit + integration)
	"$(GODOT)" --headless --path "$(PROJECT)" \
		-s "$(GUT_CMD)" $(GUT_ARGS)

test-unit: check-godot check-gut ## Run unit tests only
	"$(GODOT)" --headless --path "$(PROJECT)" \
		-s "$(GUT_CMD)" \
		-gdir=res://tests/unit/ \
		-gprefix=test_ \
		-gsuffix=.gd \
		-gexit

test-integration: check-godot check-gut ## Run integration tests only
	"$(GODOT)" --headless --path "$(PROJECT)" \
		-s "$(GUT_CMD)" \
		-gdir=res://tests/integration/ \
		-gprefix=test_ \
		-gsuffix=.gd \
		-gexit

ci: validate test ## CI pipeline: validate project + run all tests

clean-editor: ## Remove local Godot editor cache (safe — reopens on next edit)
	rm -rf "$(PROJECT)/.godot/editor"

clean: clean-editor ## Alias for clean-editor
