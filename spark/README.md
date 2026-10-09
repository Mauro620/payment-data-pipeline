# spark/ — Módulo 2

Jobs de PySpark que mueven los datos por las capas del lago.

Qué vas a construir en `jobs/`:
- `raw_to_bronze`: lectura con esquema explícito, tipado y columna `ingestion_ts`.
- `bronze_to_silver`: deduplicación por `transaction_id`, validaciones de calidad y envío de inválidos a cuarentena.
- Un agregado diario por comercio para observar el shuffle en Spark UI.

Cada job debe recibir la fecha a procesar como parámetro (Airflow se la pasará en el Módulo 3).
