.PHONY: run migrate makemigrations test lint format seed check

PYTHON := .venv/bin/python
MANAGE := $(PYTHON) manage.py

run:
	$(MANAGE) runserver 0.0.0.0:8000

migrate:
	$(MANAGE) migrate

makemigrations:
	$(MANAGE) makemigrations

test:
	$(PYTHON) -m pytest

lint:
	.venv/bin/ruff check .
	.venv/bin/black --check .

format:
	.venv/bin/ruff check --fix .
	.venv/bin/black .

seed:
	$(MANAGE) seed_users
	$(MANAGE) seed_catalog

check: lint test
