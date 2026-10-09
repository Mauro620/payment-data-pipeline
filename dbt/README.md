# dbt/ — Módulo 4

Transformación dentro del warehouse.

Qué vas a construir:
- Modelos `staging` (limpieza ligera sobre lo cargado desde silver).
- Modelos `marts` con el esquema estrella: `fact_transactions` y dimensiones (`dim_merchant`, `dim_date`, `dim_payment_method`, `dim_customer`).
- Tests: `unique`, `not_null`, `relationships`, `accepted_values`.

Inicializa el proyecto con `dbt init` cuando llegues a este módulo.
