# Test plugin makefile

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

PACKAGE_NAME=cpex_test_plugin
PROJECT_NAME=cpex_test_plugin
SRC_DIR=cpex_test_plugin
TEST_DIR = tests
TARGET ?= $(SRC_DIR)

# Virtual-environment variables
VENV_DIR  ?= $(HOME)/.venv/$(PROJECT_NAME)
VENV_BIN  = $(VENV_DIR)/bin

# Python
PYTHON = python3
PYTEST_ARGS ?=

# =============================================================================
# Help
# =============================================================================

.PHONY: help
help:
	@echo "Environment Setup:"
	@echo "  venv              Create a new virtual environment"
	@echo "  install           Install package from sources"
	@echo "  install-dev       Install package in editable mode with dev deps"
	@echo ""
	@echo "Development:"
	@echo "  lint              Run all linters (black, ruff)"
	@echo "  lint-fix          Auto-fix linting issues"
	@echo "  lint-check        Check for linting issues without fixing"
	@echo "  format            Format code with black and ruff"

# =============================================================================
# Virtual Environment
# =============================================================================

.PHONY: venv
venv:
	@echo "🔧 Creating virtual environment..."
	@rm -rf "$(VENV_DIR)"
	@test -d "$(VENV_DIR)" || mkdir -p "$(VENV_DIR)"
	@$(PYTHON) -m venv "$(VENV_DIR)"
	@$(VENV_BIN)/python -m pip install --upgrade pip setuptools wheel
	@echo "✅  Virtual env created at: $(VENV_DIR)"
	@echo "💡  Activate it with:"
	@echo "    source $(VENV_DIR)/bin/activate"

.PHONY: install
install: venv
	@echo "📦 Installing package..."
	@$(VENV_BIN)/pip install .
	@echo "✅  Package installed"

.PHONY: install-dev
install-dev: venv
	@echo "📦 Installing package with dev dependencies..."
	@$(VENV_BIN)/pip install -e ".[dev]"
	@echo "✅  Package installed in editable mode with dev dependencies"

# =============================================================================
# Linting & Formatting
# =============================================================================

.PHONY: ruff
ruff:
	@echo "⚡ Running ruff on $(TARGET)..."
	@$(VENV_BIN)/ruff check $(TARGET) --fix
	@$(VENV_BIN)/ruff format $(TARGET)

.PHONY: ruff-check
ruff-check:
	@echo "⚡ Checking ruff on $(TARGET)..."
	@$(VENV_BIN)/ruff check $(TARGET)

.PHONY: ruff-fix
ruff-fix:
	@echo "⚡ Fixing ruff issues in $(TARGET)..."
	@$(VENV_BIN)/ruff check --fix $(TARGET)

.PHONY: ruff-format
ruff-format:
	@echo "⚡ Formatting with ruff on $(TARGET)..."
	@$(VENV_BIN)/ruff format $(TARGET)

.PHONY: ruff-format-check
ruff-format-check:
	@echo "⚡ Checking formatting with ruff on $(TARGET)..."
	@$(VENV_BIN)/ruff format --check $(TARGET)

.PHONY: format
format: ruff-format
	@echo "✅  Code formatted"

.PHONY: lint
lint: lint-fix

.PHONY: lint-fix
lint-fix:
	@# Handle file arguments
	@target_file="$(word 2,$(MAKECMDGOALS))"; \
	if [ -n "$$target_file" ] && [ "$$target_file" != "" ]; then \
		actual_target="$$target_file"; \
	else \
		actual_target="$(TARGET)"; \
	fi; \
	for target in $$(echo $$actual_target); do \
		if [ ! -e "$$target" ]; then \
			echo "❌ File/directory not found: $$target"; \
			exit 1; \
		fi; \
	done; \
	echo "🔧 Fixing lint issues in $$actual_target..."; \
	$(MAKE) --no-print-directory ruff-fix TARGET="$$actual_target"; \
	$(MAKE) --no-print-directory ruff-format TARGET="$$actual_target"; \
	echo "✅  Lint issues fixed"

.PHONY: lint-check
lint-check:
	@# Handle file arguments
	@target_file="$(word 2,$(MAKECMDGOALS))"; \
	if [ -n "$$target_file" ] && [ "$$target_file" != "" ]; then \
		actual_target="$$target_file"; \
	else \
		actual_target="$(TARGET)"; \
	fi; \
	echo "🔍 Checking for lint issues..."; \
	$(MAKE) --no-print-directory ruff-check TARGET="$$actual_target"; \
	$(MAKE) --no-print-directory ruff-format-check TARGET="$$actual_target"; \
	echo "✅  Lint check complete"

# =============================================================================
# Testing
# =============================================================================

.PHONY: test
test:
	@echo "🧪 Running tests..."
	@PYTHONPATH="$(SRC_DIR)" $(VENV_BIN)/pytest  $(TEST_DIR) $(PYTEST_ARGS)

.PHONY: test-cov
test-cov:
	@echo "🧪 Running tests with coverage..."
	@PYTHONPATH="$(SRC_DIR)" $(VENV_BIN)/pytest  $(TEST_DIR) \
		--cov=$(SRC_DIR) \
		--cov-report=html \
		--cov-report=term-missing \
		$(PYTEST_ARGS)
	@echo "📊 Coverage report generated in htmlcov/"

.PHONY: test-verbose
test-verbose:
	@$(MAKE) test PYTEST_ARGS="-vv"

.PHONY: test-file
test-file:
	@if [ -z "$(FILE)" ]; then \
		echo "❌ Please specify FILE=path/to/test.py"; \
		exit 1; \
	fi
	@echo "🧪 Running test file: $(FILE)..."
	@PYTHONPATH="$(SRC_DIR)" $(VENV_BIN)/pytest $(FILE) $(PYTEST_ARGS)

# =============================================================================
# Building & Distribution
# =============================================================================

.PHONY: check-manifest
check-manifest:
	@echo "📦  Verifying MANIFEST.in completeness..."
	@$(VENV_BIN)/check-manifest

.PHONY: dist
dist: clean
	@echo "📦 Building distribution packages..."
	@test -d "$(VENV_DIR)" || $(MAKE) --no-print-directory venv
	@$(VENV_BIN)/python -m pip install --quiet --upgrade pip build
	@$(VENV_BIN)/python -m build
	@echo "✅  Wheel & sdist written to ./dist"

.PHONY: wheel
wheel:
	@echo "📦 Building wheel..."
	@test -d "$(VENV_DIR)" || $(MAKE) --no-print-directory venv
	@$(VENV_BIN)/python -m pip install --quiet --upgrade pip build
	@$(VENV_BIN)/python -m build -w
	@echo "✅  Wheel written to ./dist"

.PHONY: sdist
sdist:
	@echo "📦 Building source distribution..."
	@test -d "$(VENV_DIR)" || $(MAKE) --no-print-directory venv
	@$(VENV_BIN)/python -m pip install --quiet --upgrade pip build
	@$(VENV_BIN)/python -m build -s
	@echo "✅  Source distribution written to ./dist"

.PHONY: verify
verify: dist check-manifest
	@echo "🔍 Verifying package..."
	@$(VENV_BIN)/twine check dist/*
	@echo "✅  Package verified - ready to publish"

.PHONY: publish-test
publish-test: verify
	@echo "📤 Publishing to TestPyPI..."
	@$(VENV_BIN)/twine upload --repository testpypi dist/*

# =============================================================================
# Utilities
# =============================================================================


.PHONY: clean
clean:
	@echo "🧹 Cleaning build artifacts..."
	@find . -type f -name '*.py[co]' -delete
	@find . -type d -name __pycache__ -delete
	@rm -rf *.egg-info .pytest_cache tests/.pytest_cache build dist .ruff_cache .coverage htmlcov .mypy_cache
	@echo "✅  Build artifacts cleaned"

