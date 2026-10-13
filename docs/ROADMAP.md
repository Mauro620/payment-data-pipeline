# Ruta de construcción paso a paso

Este documento convierte los módulos de `LEARNING_PLAN.md` en pasos pequeños. Cada paso dice **qué construyes**, **dónde**, **cómo sabes que terminaste** y **qué concepto practicas**. Haz los pasos en orden: cada uno se apoya en el anterior.

## Las tres ideas que ordenan todo

1. **Primero una tajada delgada de punta a punta, después profundidad.** Antes de tener datos perfectos o Airflow, haz que 1.000 transacciones de un solo día viajen raw → bronze → silver → Postgres con comandos manuales. Cuando eso funciona, todo lo demás es mejorar algo que ya existe. Ese momento es el hito de la Etapa 2.
2. **Cada pieza es un script que corre solo por línea de comando y recibe la fecha como parámetro.** Airflow no hace magia: en la Etapa 3 solo va a llamar, en orden, a los comandos que ya probaste a mano.
3. **Si no se puede verificar, no está terminado.** Cada paso tiene una condición de "terminado" que se comprueba con un comando, un conteo o una captura.

## Cómo es una sesión de trabajo (bloque de mañana, ~3 h)

| Tiempo | Qué haces |
|---|---|
| 10 min | Lee el paso que sigue. Escribe en papel: qué entra, qué sale, qué puede fallar, cómo sé que terminé. |
| 2 h 20 min | Construye. Antes de cada ejecución, predice el resultado. |
| 20 min | Verifica la condición de "terminado", haz commit y escribe la entrada del día en `docs/decisions.md`. |

**Si te atascas:** 30–45 min con la documentación oficial → describe por escrito qué intentaste y qué esperabas → pregunta a Claude por una pista, no por la solución → si sigue sin salir, pide un fragmento mínimo.

---

## Etapa 0 · Arranque (medio día)

**0.1 Levantar el stack**
- Haz: `make env`, llena `.env`, `make up`, `make ps`, luego `make psql` y ejecuta `SELECT 1;`.
- Terminado cuando: `postgres` aparece como *healthy* y `psql` responde.
- Concepto: red interna de Compose. ¿Por qué el contenedor `spark` se conecta a `postgres:5432` y no a `localhost:5432`?

**0.2 Verificar el contenedor de trabajo**
- Haz: `make shell` y dentro ejecuta `python -c "import pyspark; print(pyspark.__version__)"` y `java -version`.
- Terminado cuando: ambos responden sin error.
- Concepto: ¿por qué PySpark necesita Java?

**0.3 Primera entrada de bitácora**
- Haz: en `docs/decisions.md`, el experimento del volumen (qué predijiste vs. qué pasó) y tus respuestas de M0 corregidas.
- Commit: `docs: M0 learning log`

---

## Etapa 1 · Contrato y generador (día 1 a día 2)

**1.1 Contrato de datos** · `docs/data_contract.md`
- Haz: granularidad en la primera línea ("una fila representa…"), ~15 campos con tipo, obligatoriedad y regla de validez, valores permitidos, reglas condicionales, y cómo se genera `transaction_id` de forma determinística.
- Decide también ahora: el generador debe **plantar patrones de fraude** (por ejemplo, muchas transacciones de la misma tarjeta en una hora, o montos altos internacionales de madrugada) y marcar cada fila con una etiqueta oculta `is_fraud`. Sin esa "verdad", en la Etapa 6 no podrás medir si tu scoring funciona.
- Terminado cuando: Claude revisa el contrato y no quedan reglas ambiguas.
- Commit: `docs: payment data contract v1`

**1.2 Catálogos de referencia** · `ingestion/catalogs.py`
- Haz: genera una sola vez ~50 comercios y ~2.000 clientes, con semilla fija, y escríbelos en `data/reference/merchants.parquet` y `data/reference/customers.parquet`.
- Terminado cuando: corres el script dos veces y los archivos son idénticos.
- Concepto: datos de referencia (futuras dimensiones) vs. datos transaccionales (futuros hechos).

**1.3 Generador de transacciones limpias** · `ingestion/generate_payments.py`
- Haz: una función que reciba fecha, cantidad y semilla, y devuelva un DataFrame de pandas con transacciones **válidas** que referencian comercios y clientes del catálogo. Todavía sin datos sucios.
- Terminado cuando: 1.000 filas cumplen todas las reglas del contrato. Compruébalo con asserts sencillos.
- Concepto: determinismo. ¿La misma fecha produce siempre las mismas filas?

**1.4 Interfaz de línea de comando**
- Haz: que el script se pueda correr como `python -m ingestion.generate_payments --date 2026-10-01 --n 1000`.
- Terminado cuando: funciona dentro del contenedor (`make shell`).
- Concepto: esta es la interfaz que Airflow va a usar en la Etapa 3.

**1.5 Escritura idempotente en raw**
- Haz: escribe en `data/raw/payments/date=YYYY-MM-DD/`. Escribe primero en una carpeta temporal y luego renómbrala sobre la definitiva.
- Terminado cuando: corres dos veces la misma fecha y obtienes el mismo conteo **y** el mismo contenido. Las demás fechas quedan intactas.
- Commit: `feat: deterministic payment generator writing raw partitions`

**1.6 Datos sucios intencionales**
- Haz: una función por cada tipo de defecto (duplicados ~2%, nulos ~1%, violaciones de reglas condicionales), cada una con su propia tasa como parámetro.
- Terminado cuando: el script imprime un resumen con cuántas filas de cada defecto inyectó. **Guarda esos números:** son la verdad contra la que vas a validar silver en el paso 2.4.
- Commit: `feat: inject controlled data quality issues`

**1.7 Experimento CSV vs. Parquet**
- Haz: genera 1 millón de filas en ambos formatos y compara tamaño en disco y tiempo de lectura de una sola columna.
- Terminado cuando: hay una tabla de resultados en `docs/decisions.md` con tu explicación.

**1.8 Una semana de datos**
- Haz: genera 7 fechas consecutivas.
- Terminado cuando: ves 7 carpetas `date=...` en raw.

---

## Etapa 2 · PySpark y la primera tajada completa (días 3 a 5)

**2.1 Leer raw con esquema explícito** · `spark/schemas.py`
- Haz: define el esquema de raw según el contrato, lee una fecha, cuenta filas y ejecuta `.explain()`.
- Terminado cuando: el conteo coincide con lo que generaste y puedes describir el plan con tus palabras.
- Concepto: transformación vs. acción, evaluación perezosa.

**2.2 raw → bronze** · `spark/jobs/raw_to_bronze.py --date`
- Haz: tipado correcto, columnas `ingestion_ts` y `source_file`, escritura en `data/bronze/payments/date=.../`.
- Terminado cuando: reprocesas una fecha y **las otras 6 siguen existiendo**. Si desaparecen, caíste en la trampa del modo overwrite: busca `partitionOverwriteMode`.
- Commit: `feat: raw to bronze job`

**2.3 Reglas de calidad como funciones puras** · `spark/quality.py` + `tests/test_quality.py`
- Haz: cada regla del contrato es una función que se puede probar sola. Escribe tests con pytest sobre DataFrames pequeños con casos válidos e inválidos.
- Terminado cuando: `make test` pasa.
- Concepto: lógica de negocio probable y separada del job.

**2.4 bronze → silver con cuarentena** · `spark/jobs/bronze_to_silver.py --date`
- Haz: deduplica por `transaction_id`. Decide y justifica cuál fila conservas cuando hay duplicados (pista: función de ventana con `row_number`). Las filas válidas van a silver; las inválidas, a `data/quarantine/payments/` con una columna `rejection_reason`.
- Terminado cuando: raw = silver + cuarentena + duplicados eliminados, y esos números cuadran con el resumen del paso 1.6.
- Commit: `feat: bronze to silver with dedup and quarantine`

**2.5 Agregado y Spark UI**
- Haz: total y conteo diario por comercio con `groupBy`. Mientras corre, abre `localhost:4040` y encuentra el *shuffle*.
- Terminado cuando: tienes una captura en `docs/evidence/` y puedes explicar por qué ese paso es costoso.

**2.6 Carga al warehouse** · `spark/jobs/load_warehouse.py --date`
- Haz: escribe silver en Postgres (schema `staging`) por JDBC. Para que sea idempotente: borra las filas de esa fecha e inserta las nuevas.
- Terminado cuando: `SELECT date, count(*) ... GROUP BY date` coincide con silver, y recargar la misma fecha no duplica.
- Commit: `feat: load silver into warehouse staging`

**2.7 Atajos en el Makefile**
- Haz: un target por paso del pipeline (generar, bronze, silver, cargar), todos con `DATE=`.

> **🏁 Hito:** con 4 comandos y una fecha, una transacción viaja de punta a punta. Ya tienes un pipeline. Todo lo que sigue lo mejora.

---

## Etapa 3 · Airflow (días 6 a 8)

**3.1 Levantar Airflow**
- Haz: resuelve primero el bug de la base de metadatos de Airflow (pista: el script de `infra/docker/postgres/init/` solo corre al crear el volumen por primera vez). Luego `make up-airflow` y entra a `localhost:8080`.
- Terminado cuando: ves la interfaz y el scheduler está corriendo.

**3.2 DAG de práctica** · `airflow/dags/hello.py`
- Haz: dos tasks con `BashOperator`, una dependiente de la otra.
- Terminado cuando: corre en verde y tienes la captura del Graph view.
- Concepto: DAG, task, operator, DAG run.

**3.3 DAG del pipeline** · `airflow/dags/payments_daily.py`
- Haz: una task por cada comando de la Etapa 2, en orden, pasando la fecha lógica `{{ ds }}`. Programación diaria, `start_date` fija, `catchup=False` al principio.
- Terminado cuando: un run manual completa todo y los datos aparecen en Postgres.
- Commit: `feat: payments_daily DAG`

**3.4 Reintentos**
- Haz: `retries=2` y provoca una falla a propósito en una task.
- Terminado cuando: ves el reintento en los logs y puedes explicar por qué solo es seguro porque cada task es idempotente.

**3.5 Backfill**
- Haz: corre el DAG para 7 fechas pasadas. Luego córrelo **otra vez** para las mismas fechas.
- Terminado cuando: los conteos por fecha en Postgres son idénticos antes y después del segundo backfill.

**3.6 Alerta de falla**
- Haz: un callback que registre o notifique cuando una task falla.
- Commit: `feat: retries, backfill-safe tasks and failure alerts`

> **🏁 Hito:** Airflow en el CV ya tiene respaldo real.

---

## Etapa 4 · Modelado dimensional y dbt (días 9 a 11)

**4.1 Diseño del esquema estrella** · `docs/architecture.md`
- Haz: en papel, la granularidad de `fact_transactions` y sus dimensiones (comercio, cliente, método de pago, fecha). Pasa el diagrama al documento.

**4.2 Proyecto dbt**
- Haz: `dbt init` dentro de `dbt/`, perfil que lea las credenciales de variables de entorno.
- Terminado cuando: `dbt debug` pasa en verde.

**4.3 Fuentes** · `models/sources.yml`
- Haz: declara las tablas de `staging` como fuentes, con tests básicos.

**4.4 Modelos staging**
- Haz: `stg_payments`, `stg_merchants`, `stg_customers` (renombres y tipos, sin lógica de negocio).

**4.5 Marts**
- Haz: `dim_merchant`, `dim_customer`, `dim_payment_method`, `dim_date` y `fact_transactions`, con tests `unique`, `not_null`, `relationships` y `accepted_values`.
- Terminado cuando: `dbt build` pasa completo.
- Commit: `feat: dbt star schema with tests`

**4.6 Documentación y linaje**
- Haz: `dbt docs generate` y captura el grafo de linaje.

**4.7 dbt en el DAG**
- Haz: agrega una task que corra `dbt build` después de la carga.

**4.8 Preguntas de negocio** · `analysis/`
- Haz: las 5 consultas (top comercios, tasa de rechazo diaria, ticket promedio móvil de 7 días, clientes con muchas transacciones en una hora, participación por método de pago) usando funciones de ventana.

**4.9 Optimización**
- Haz: `EXPLAIN ANALYZE` de la consulta más lenta, agrega un índice y compara.
- Terminado cuando: tienes antes y después en la bitácora.

---

## Etapa 5 · AWS (días 12 y 13)

**5.1 Presupuesto primero**
- Haz: alerta en AWS Budgets **antes** de crear cualquier recurso.

**5.2 Identidad**
- Haz: un usuario o rol con permisos mínimos y la CLI configurada.

**5.3 S3 como lago**
- Haz: un bucket con prefijos raw, bronze y silver; sube las particiones con boto3.

**5.4 Glue y Athena**
- Haz: registra silver en el Glue Catalog y consúltalo con Athena. Compara los datos escaneados filtrando por fecha y sin filtrar.
- Concepto: *partition pruning* en la nube y por qué cuesta dinero no tenerlo.

**5.5 Redshift Serverless**
- Haz: `COPY` desde S3 a la tabla de hechos, una consulta, capturas y tiempos. **Elimínalo el mismo día.**

**5.6 Documentar la diferencia**
- Haz: completa la tabla local vs. nube de `docs/architecture.md`.

---

## Etapa 6 · Calidad, CI y scoring de riesgo (días 14 y 15)

**6.1 CI** · `.github/workflows/ci.yml`
- Haz: ruff y pytest en cada push.
- Terminado cuando: badge verde en el README.

**6.2 Compuerta de calidad**
- Haz: una task que falle el DAG si la tasa de cuarentena supera un umbral.

**6.3 Completitud y frescura**
- Haz: valida que llegó un volumen razonable de filas para la fecha.

**6.4 Scoring de riesgo**
- Haz: primero reglas simples como línea base, luego un Random Forest sobre features del warehouse. Mide precision y recall contra la etiqueta `is_fraud` del paso 1.1.
- Concepto: por qué el accuracy engaña cuando el fraude es el 1% de los datos.

**6.5 Scores en el warehouse**
- Haz: una tabla `risk_scores` que el DAG escribe en cada run.

---

## Etapa 7 · Cierre (días 16 y 17)

- README en inglés con métricas reales: filas procesadas, tiempo de ejecución, tasa de cuarentena, precision y recall.
- Video de 3 minutos.
- CV: quitar "in progress" y agregar una métrica del proyecto.
- Simulacro: todas las preguntas de entrevista de Notion, en voz alta y en inglés.
- Post en LinkedIn con el diagrama y el enlace al repo.

---

## Control de avance

| Etapa | Días aprox. | Hito |
|---|---|---|
| 0 | 0,5 | Stack corriendo |
| 1 | 2 | Datos determinísticos y sucios en raw |
| 2 | 3 | **Pipeline manual de punta a punta** |
| 3 | 3 | DAG con backfill seguro |
| 4 | 3 | Modelo estrella con tests |
| 5 | 2 | Evidencia en AWS |
| 6 | 2 | CI, calidad y scoring |
| 7 | 2 | Listo para mostrar |

Unos 17 días de trabajo en bloques de mañana, más o menos 4 semanas.
