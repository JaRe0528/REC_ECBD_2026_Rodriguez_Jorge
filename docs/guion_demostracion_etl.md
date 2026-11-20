# Guion de la demostración: vaciar → cargar con el ETL → volver a cargar → Power BI

Terminal: VS Code, en `C:\Users\Jorge\REC_ECBD_2026_Rodriguez_Jorge`, con `(.venv)` activo.

| # | Acción | Comando / clic | Resultado esperado |
|---|---|---|---|
| 1 | Mostrar el Data Warehouse lleno | SSMS: `sql/03_consultas_validacion.sql` → F5 | Fact_Abulon = 4,169 |
| 2 | Vaciar todas las tablas | `python src/etl_abalone.py --vaciar` | Todas las tablas en 0 |
| 3 | Comprobar en Power BI | Inicio → Actualizar | Tarjetas "(En blanco)" y gráficas vacías |
| 4 | Ejecutar el ETL (carga full) | `python src/etl_abalone.py` | Fact_Abulon = 4,169 · Dim_Tiempo = 3,653 |
| 5 | Ejecutarlo otra vez | `python src/etl_abalone.py` | Borra 4,169 y carga 4,169: mismos números |
| 6 | Revisar la bitácora | SSMS: `SELECT * FROM dbo.Log_ETL ORDER BY ID_Ejecucion DESC;` | VACIADO, FULL, FULL en estado OK |
| 7 | Actualizar el dashboard | Power BI → Inicio → Actualizar | Vuelven 4,169 · 11.44 · 1.49 · 64.10 |
| 8 | Usar las segmentaciones | Mes, sexo o perfil | Todas las gráficas se filtran |

Alternativa al paso 2 desde SSMS: `sql/04_vaciar_datawarehouse.sql` → F5.
