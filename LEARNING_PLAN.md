# Plan de aprendizaje

La versión completa (preguntas de concepto, ejercicios con evidencia y preguntas de entrevista por módulo) vive en Notion, en la página **payment-data-pipeline** de la base de Proyectos. Este archivo es el resumen para tenerlo a mano en el repo.

## Mentalidad

1. **Diseña antes de generar.** Cada módulo empieza en papel: qué entra, qué sale, qué puede fallar, cómo sé que funcionó.
2. **Predice antes de ejecutar.** Escribe qué esperas que pase. Si no coincide, ahí está la lección.
3. **Lucha primero, pregunta después.** 30–45 min con la documentación oficial antes de pedir ayuda. La IA explica; no escribe por ti en los ejercicios de concepto.
4. **Rompe cosas a propósito.** Ver cómo falla un sistema es lo que preguntan en entrevistas.
5. **Si no lo puedes explicar, no lo sabes.** Cierra cada módulo explicando en inglés, en 2 minutos, qué hiciste y por qué.

**Regla de evidencia:** un ejercicio solo cuenta como hecho si deja un commit, una captura en `docs/evidence/`, una salida de consola o una entrada en `docs/decisions.md`.

## Ruta

| Semana | Módulos | Hito |
|---|---|---|
| 1 | M0 Entorno · M1 Datos y raw · M2 PySpark | Datos generados y procesados hasta silver, local |
| 2 | M3 Airflow · inicio M4 | DAG diario con backfill funcionando |
| 3 | M4 Warehouse y dbt · M5 AWS | Modelo estrella con tests + despliegue en la nube |
| 4 | M6 Calidad, CI y scoring · M7 Cierre | README, video, CV actualizado, simulacro de entrevista |

## Módulos

- **M0 · Entorno** — Docker Compose con Postgres y volúmenes, `Makefile` con `make up` / `make down`.
- **M1 · Datos y capa raw** — contrato de datos, generador con datos sucios a propósito, CSV vs. Parquet, idempotencia.
- **M2 · PySpark** — esquema explícito, raw → bronze → silver, deduplicación, cuarentena, particiones y shuffle.
- **M3 · Airflow** — DAG diario con fecha lógica, reintentos, backfill sin duplicados, alertas.
- **M4 · Warehouse y dbt** — esquema estrella, tests de dbt, 5 preguntas de negocio con funciones de ventana.
- **M5 · AWS** — presupuesto primero, S3, Glue + Athena, Redshift Serverless (y apagarlo).
- **M6 · Calidad, CI y scoring** — GitHub Actions, reglas que detienen el DAG, scoring de riesgo con precision/recall.
- **M7 · Cierre** — README en inglés con métricas, video de 3 minutos, CV y LinkedIn.

## Definición de terminado

- [ ] `make up` levanta todo localmente y cualquiera puede reproducirlo.
- [ ] El DAG corre cada día simulado y permite backfill sin duplicar datos.
- [ ] El warehouse responde preguntas de negocio.
- [ ] Tests de dbt y validaciones de calidad pasan; si los datos vienen mal, el pipeline se detiene.
- [ ] Corrió en AWS al menos una vez, con evidencia.
- [ ] CI verde en cada push.
- [ ] README en inglés con diagrama, decisiones y métricas reales.
- [ ] Video de 3 minutos.
- [ ] Puedes explicar cada decisión en voz alta, en inglés, sin mirar el código.
