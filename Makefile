.DEFAULT_GOAL := help
COMPOSE := docker compose
RUN     := $(COMPOSE) run --rm --no-deps spark
JOB     ?=
DATE    ?=

.PHONY: help env build up down restart ps logs shell psql \
        up-airflow down-airflow \
        spark-submit test lint fmt clean-data reset

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

env: ## Create .env from .env.example and the local dirs the containers mount
	@test -f .env || (cp .env.example .env && echo "Created .env — fill in the empty values before 'make up'")
	@mkdir -p data airflow/logs

build: env ## Build the images
	$(COMPOSE) --profile airflow build

up: env ## Start postgres + spark container
	$(COMPOSE) up -d --build --wait postgres spark

down: ## Stop containers (keeps volumes and data)
	$(COMPOSE) --profile airflow down

restart: down up ## Restart the default stack

ps: ## List containers
	$(COMPOSE) --profile airflow ps

logs: ## Follow logs (SERVICE=name for one service)
	$(COMPOSE) --profile airflow logs -f --tail=100 $(SERVICE)

shell: ## Shell inside the spark container
	$(COMPOSE) exec spark bash

psql: ## psql into the warehouse
	$(COMPOSE) exec postgres sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'

up-airflow: env ## Start the full stack including Airflow (UI on :8080)
	$(COMPOSE) --profile airflow up -d --build

down-airflow: ## Stop only the Airflow services
	$(COMPOSE) --profile airflow stop airflow-webserver airflow-scheduler

spark-submit: ## Run a Spark job: make spark-submit JOB=raw_to_bronze DATE=2025-01-01
	@test -n "$(JOB)" -a -n "$(DATE)" || (echo "Usage: make spark-submit JOB=<job> DATE=YYYY-MM-DD" && exit 1)
	$(COMPOSE) exec spark python spark/jobs/$(JOB).py --date $(DATE)

test: ## Run pytest
	$(RUN) pytest

lint: ## Ruff lint + format check
	$(RUN) sh -c "ruff check . && ruff format --check ."

fmt: ## Ruff autofix + format
	$(RUN) sh -c "ruff check --fix . && ruff format ."

clean-data: ## Delete generated data (raw/bronze/silver/quarantine)
	rm -rf data/*

reset: ## DANGER: remove containers AND the Postgres volume
	@read -p "This deletes the warehouse volume. Type 'yes' to continue: " ans && [ "$$ans" = "yes" ]
	$(COMPOSE) --profile airflow down -v
