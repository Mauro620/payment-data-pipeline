#!/bin/bash
# Runs only the first time the pgdata volume is created.
# Airflow's metadata DB lives apart from the warehouse DB (POSTGRES_DB).
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-SQL
    CREATE DATABASE ${AIRFLOW_DB:-airflow};
SQL
