# src — Scripts de Python

| Script | Qué hace |
|---|---|
| `etl_abalone.py` | **ETL automático** con **carga FULL** al Data Warehouse `DM_Abalone` de SQL Server |
| `ejecutar_etl.bat` | Ejecuta el ETL; se programa en el Programador de tareas de Windows (diario, 3:00 a.m.) |

## Cómo ejecutar el ETL
```
python src/etl_abalone.py
```
1. **Extraer:** lee el archivo original `data/raw/abalone.data` (no lo modifica).
2. **Transformar:** elimina 8 registros físicamente imposibles, convierte a mm y g, crea `Edad_anios`, `Grupo_Edad`, `ID_Abulon` y una **fecha de muestreo simulada** (días hábiles de 2026), y aplica los modelos guardados en `modelos/` (regresión, clasificación, K-Means y PCA).
3. **Cargar (full):** dentro de una transacción **borra** el destino en orden por las llaves foráneas (`DELETE`, porque las tablas con integridad referencial no admiten `TRUNCATE`), genera `Dim_Tiempo` con el procedimiento `sp_Generar_Dim_Tiempo` e inserta dimensiones, hechos, resultados y métricas. Si algo falla hace `ROLLBACK`.
4. Registra cada ejecución en `dbo.Log_ETL`.

Ejecutarlo varias veces deja el Data Warehouse **igual** (no se duplican datos).

Opciones: `--servidor`, `--base`, y `--sin-cargar` (solo extrae y transforma).

## Ejecución automática programada
`ejecutar_etl.bat` corre el ETL con el Python del entorno `.venv` y guarda la salida en `logs/etl.log`.
Está programado en el **Programador de tareas de Windows** para ejecutarse **todos los días a las 3:00 a.m.** (tarea `ETL_Abalone`).

> SQL Server Express no incluye el Agente SQL Server, por eso no se usa un *job* de SQL Server. En Linux o Mac el equivalente sería una línea en `cron`, por ejemplo: `0 3 * * * cd /ruta/proyecto && .venv/bin/python src/etl_abalone.py`.
