# airflow/ — Módulo 3

Orquestación del pipeline.

Qué vas a construir en `dags/`:
- Un DAG `hello` de práctica con 2 tasks dependientes.
- El DAG `payments_daily`: generate → raw_to_bronze → bronze_to_silver → load_warehouse → dbt.
- Reintentos, uso de la fecha lógica `{{ ds }}`, backfill sin duplicados y un callback de alerta.
