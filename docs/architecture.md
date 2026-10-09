# Arquitectura

> Actualiza este documento cuando una decisión cambie el diseño. Cada capa debe tener una razón de existir.

```mermaid
flowchart LR
  A["Generator"] --> B["Raw"]
  B --> C["Bronze"]
  C --> D["Silver"]
  D --> Q["Quarantine"]
  D --> E["Warehouse"]
  E --> F["dbt marts"]
  F --> G["Risk scoring"]
  H["Airflow"] -.-> A & C & D & E & F
```

## Capas

| Capa | Qué contiene | Quién la escribe | Por qué existe |
|---|---|---|---|
| Raw | | | |
| Bronze | | | |
| Silver | | | |
| Cuarentena | | | |
| Warehouse (staging) | | | |
| Marts (gold) | | | |

## Local vs. nube (Módulo 5)

| Componente | Local | AWS |
|---|---|---|
| Almacenamiento | Parquet en disco | S3 |
| Procesamiento | Spark en Docker | |
| Warehouse | Postgres | Redshift Serverless |
| Orquestación | Airflow en Docker | |
