.PHONY: clean clean-test clean-pyc clean-build docs help
.DEFAULT_GOAL := help
define BROWSER_PYSCRIPT
import os, webbrowser, sys
try:
	from urllib import pathname2url
except:
	from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT
BROWSER := python -c "$$BROWSER_PYSCRIPT"

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

clean: clean-build clean-pyc clean-test ## remove all build, test, coverage and Python artifacts

test-match:
	uv run --group test python -m unittest tests.test_blast.TestBlast.test_002_blast
	

clean-build: ## remove build artifacts
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -fr {} +

clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test: ## remove test and coverage artifacts
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/

lint: ## check style with flake8
	uv run --group lint flake8 seqann tests

test: ## run tests quickly with the default Python
	uv run --group test python -m unittest discover -v

test-all: ## run the test suite with uv
	uv run --group test python -m unittest discover -v

coverage: ## check code coverage quickly with the default Python
	uv run --group test coverage run --source seqann -m unittest discover

	uv run --group test coverage report -m
	uv run --group test coverage html
	$(BROWSER) htmlcov/index.html

docs: ## generate Sphinx HTML documentation, including API docs
	# rm -f docs/seqann.md
	# rm -f docs/modules.md
	uv run --group docs sphinx-apidoc -o docs/ seqann
	$(MAKE) -C docs clean
	uv run --group docs $(MAKE) -C docs html
	$(BROWSER) docs/_build/html/index.html

servedocs: docs ## compile the docs watching for changes
	uv run --group docs watchmedo shell-command -p '*.md' -c 'uv run --group docs $(MAKE) -C docs html' -R -D .

release: clean ## package and upload a release
	uv build
	@echo "Upload the files in dist/ with your publishing tool."

dist: clean ## builds source and wheel package
	uv build
	ls -l dist

install: clean ## install the package to the active Python's site-packages
	uv sync

venv: ## creates a uv-managed virtualenv environment in .venv
	uv sync
	@echo "====================================================================="
	@echo "To activate the uv virtualenv, execute the following from your shell"
	@echo "source $(PWD)/.venv/bin/activate"

activate: ## activate a virtual environment. Run `make venv` before activating.
	@echo "====================================================================="
	@echo "To activate the uv virtualenv, execute the following from your shell"
	@echo "source $(PWD)/.venv/bin/activate"
