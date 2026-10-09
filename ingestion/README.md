# ingestion/ — Módulo 1

Generador de transacciones de pago sintéticas que escribe la capa **raw**.

Qué vas a construir:
- Un script que reciba una fecha y una cantidad N, y genere transacciones según `docs/data_contract.md`.
- Datos sucios a propósito (duplicados, nulos, montos inválidos).
- Salida particionada: `data/raw/date=YYYY-MM-DD/`.
- Comportamiento idempotente: correrlo dos veces para la misma fecha no debe duplicar.

Antes de escribir código: termina el contrato de datos en papel.
