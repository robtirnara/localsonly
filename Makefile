SHELL := /bin/bash

BACKEND_DIR := backend
MIGRATIONS_DIR := $(BACKEND_DIR)/migrations
SCRIPTS_DIR := $(BACKEND_DIR)/scripts
SEED_BOOTSTRAP := $(SCRIPTS_DIR)/seed_bootstrap_san_diego.sql
SEED_DEV_RESET := $(SCRIPTS_DIR)/seed_dev_reset.sql
IOS_PROJECT := ios/LocalsOnlyApp.xcodeproj
POSTGRES_CONTAINER := localsonly-postgres

DATABASE_HOST ?= 127.0.0.1
DATABASE_PORT ?= 5432
DATABASE_USER ?= $(shell whoami)
DATABASE_PASSWORD ?=
DATABASE_NAME ?= localsonly
ADMIN_BEARER_TOKEN ?= local-admin-token
LOCALSONLY_API_BASE_URL ?= http://127.0.0.1:8080

export DATABASE_HOST
export DATABASE_PORT
export DATABASE_USER
export DATABASE_PASSWORD
export DATABASE_NAME
export ADMIN_BEARER_TOKEN
export LOCALSONLY_API_BASE_URL

PSQL_BIN := $(shell command -v psql 2>/dev/null || echo /opt/homebrew/opt/postgresql@16/bin/psql)
PG_ISREADY_BIN := $(shell command -v pg_isready 2>/dev/null || echo /opt/homebrew/opt/postgresql@16/bin/pg_isready)
CREATEDB_BIN := $(shell command -v createdb 2>/dev/null || echo /opt/homebrew/opt/postgresql@16/bin/createdb)

.PHONY: help up down wait-db ensure-db migrate run test ios env seed-bootstrap seed-demo

help:
	@echo "LocalsOnly MVP commands:"
	@echo "  make up      - start Postgres, wait, run migrations"
	@echo "  make run     - run backend API (includes make up)"
	@echo "  make test    - run backend tests (includes make up)"
	@echo "  make ios     - open Xcode project"
	@echo "  make down    - stop Postgres container"
	@echo "  make env     - print active environment values"
	@echo "  make seed-bootstrap - idempotent San Diego demo seed (safe for prod empty DB)"
	@echo "  make seed-demo - DEV ONLY: wipe app tables + seed-bootstrap"
	@echo ""
	@echo "DB mode:"
	@echo "  - Uses Docker if available"
	@echo "  - Falls back to local Postgres tools (pg_isready/psql) if Docker is missing"

env:
	@echo "DATABASE_HOST=$(DATABASE_HOST)"
	@echo "DATABASE_PORT=$(DATABASE_PORT)"
	@echo "DATABASE_USER=$(DATABASE_USER)"
	@echo "DATABASE_NAME=$(DATABASE_NAME)"
	@echo "ADMIN_BEARER_TOKEN=$(ADMIN_BEARER_TOKEN)"
	@echo "LOCALSONLY_API_BASE_URL=$(LOCALSONLY_API_BASE_URL)"

up: wait-db ensure-db migrate
	@echo "MVP dependencies are ready."

down:
	@if docker info >/dev/null 2>&1; then \
		cd "$(BACKEND_DIR)" && docker compose down; \
	else \
		echo "Docker not found; nothing to stop in docker compose mode."; \
	fi

wait-db:
	@if docker info >/dev/null 2>&1; then \
		cd "$(BACKEND_DIR)" && docker compose up -d; \
		echo "Waiting for Postgres in Docker..."; \
		until docker exec "$(POSTGRES_CONTAINER)" pg_isready -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" >/dev/null 2>&1; do \
			sleep 1; \
		done; \
		echo "Postgres (Docker) is ready."; \
	else \
		if [ ! -x "$(PG_ISREADY_BIN)" ]; then \
			echo "Neither docker nor pg_isready is available."; \
			echo "Install Docker Desktop OR PostgreSQL client tools (pg_isready, psql)."; \
			exit 127; \
		fi; \
		echo "Docker not found; using local Postgres at $(DATABASE_HOST):$(DATABASE_PORT)..."; \
		until "$(PG_ISREADY_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d postgres >/dev/null 2>&1; do \
			sleep 1; \
		done; \
		echo "Postgres (local) is ready."; \
	fi

ensure-db:
	@if docker info >/dev/null 2>&1; then \
		docker exec "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d postgres -tc "SELECT 1 FROM pg_database WHERE datname='$(DATABASE_NAME)'" | grep -q 1 || docker exec "$(POSTGRES_CONTAINER)" createdb -U "$(DATABASE_USER)" "$(DATABASE_NAME)"; \
	else \
		if [ ! -x "$(PSQL_BIN)" ] || [ ! -x "$(CREATEDB_BIN)" ]; then \
			echo "psql/createdb are required when Docker is unavailable."; \
			exit 127; \
		fi; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d postgres -tc "SELECT 1 FROM pg_database WHERE datname='$(DATABASE_NAME)'" | grep -q 1 || PGPASSWORD="$(DATABASE_PASSWORD)" "$(CREATEDB_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" "$(DATABASE_NAME)"; \
	fi

migrate:
	@echo "Applying SQL migrations..."
	@if docker info >/dev/null 2>&1; then \
		cat "$(MIGRATIONS_DIR)/0001_base_schema.sql" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" >/dev/null; \
		cat "$(MIGRATIONS_DIR)/0002_eligibility_and_moderation.sql" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" >/dev/null; \
		cat "$(MIGRATIONS_DIR)/0003_user_sessions.sql" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" >/dev/null; \
		cat "$(MIGRATIONS_DIR)/0004_moderation_action_type_suppress_rating.sql" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" >/dev/null; \
		cat "$(MIGRATIONS_DIR)/0005_seed_test_invite.sql" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" >/dev/null; \
		cat "$(MIGRATIONS_DIR)/0006_item_ratings.sql" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" >/dev/null; \
		cat "$(MIGRATIONS_DIR)/0007_rating_photos.sql" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" >/dev/null; \
		cat "$(MIGRATIONS_DIR)/0008_places_coordinates.sql" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" >/dev/null; \
		cat "$(MIGRATIONS_DIR)/0009_seed_tags.sql" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" >/dev/null; \
		cat "$(MIGRATIONS_DIR)/0010_place_cover_photo.sql" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" >/dev/null; \
		cat "$(MIGRATIONS_DIR)/0011_backfill_cover_photos.sql" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" >/dev/null; \
		cat "$(MIGRATIONS_DIR)/0012_saved_places.sql" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" >/dev/null; \
		cat "$(MIGRATIONS_DIR)/0013_lists.sql" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" >/dev/null; \
		cat "$(MIGRATIONS_DIR)/0014_cosigns.sql" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" >/dev/null; \
		cat "$(MIGRATIONS_DIR)/0015_notifications.sql" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" >/dev/null; \
	else \
		if [ ! -x "$(PSQL_BIN)" ]; then \
			echo "psql is required when Docker is unavailable."; \
			echo "Install PostgreSQL client tools or Docker Desktop."; \
			exit 127; \
		fi; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(MIGRATIONS_DIR)/0001_base_schema.sql" >/dev/null; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(MIGRATIONS_DIR)/0002_eligibility_and_moderation.sql" >/dev/null; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(MIGRATIONS_DIR)/0003_user_sessions.sql" >/dev/null; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(MIGRATIONS_DIR)/0004_moderation_action_type_suppress_rating.sql" >/dev/null; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(MIGRATIONS_DIR)/0005_seed_test_invite.sql" >/dev/null; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(MIGRATIONS_DIR)/0006_item_ratings.sql" >/dev/null; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(MIGRATIONS_DIR)/0007_rating_photos.sql" >/dev/null; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(MIGRATIONS_DIR)/0008_places_coordinates.sql" >/dev/null; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(MIGRATIONS_DIR)/0009_seed_tags.sql" >/dev/null; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(MIGRATIONS_DIR)/0010_place_cover_photo.sql" >/dev/null; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(MIGRATIONS_DIR)/0011_backfill_cover_photos.sql" >/dev/null; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(MIGRATIONS_DIR)/0012_saved_places.sql" >/dev/null; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(MIGRATIONS_DIR)/0013_lists.sql" >/dev/null; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(MIGRATIONS_DIR)/0014_cosigns.sql" >/dev/null; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(MIGRATIONS_DIR)/0015_notifications.sql" >/dev/null; \
	fi
	@echo "Migrations complete."

seed-bootstrap:
	@echo "Applying bootstrap seed ($(SEED_BOOTSTRAP))..."
	@if docker info >/dev/null 2>&1; then \
		cat "$(SEED_BOOTSTRAP)" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)"; \
	else \
		if [ ! -x "$(PSQL_BIN)" ]; then \
			echo "psql is required when Docker is unavailable."; \
			exit 127; \
		fi; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(SEED_BOOTSTRAP)"; \
	fi
	@echo "Bootstrap seed complete."

seed-demo: wait-db
	@echo "DEV ONLY: resetting app data ($(SEED_DEV_RESET)), then bootstrap seed."
	@if docker info >/dev/null 2>&1; then \
		cat "$(SEED_DEV_RESET)" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)"; \
		cat "$(SEED_BOOTSTRAP)" | docker exec -i "$(POSTGRES_CONTAINER)" psql -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)"; \
	else \
		if [ ! -x "$(PSQL_BIN)" ]; then \
			echo "psql is required when Docker is unavailable."; \
			exit 127; \
		fi; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(SEED_DEV_RESET)"; \
		PGPASSWORD="$(DATABASE_PASSWORD)" "$(PSQL_BIN)" -h "$(DATABASE_HOST)" -p "$(DATABASE_PORT)" -U "$(DATABASE_USER)" -d "$(DATABASE_NAME)" -f "$(SEED_BOOTSTRAP)"; \
	fi
	@echo "seed-demo complete."

run: up
	@echo "Starting API at http://127.0.0.1:8080 ..."
	@cd "$(BACKEND_DIR)" && swift run

test: up
	@cd "$(BACKEND_DIR)" && swift test

ios:
	@echo "Opening iOS project. Set LOCALSONLY_API_BASE_URL=$(LOCALSONLY_API_BASE_URL) in Run scheme."
	@open "$(IOS_PROJECT)"
