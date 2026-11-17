/* =====================================================================
   Proyecto: Estimación de edad y análisis morfológico de abulones
   Script 04 - VACIAR el Data Warehouse (para la demostración del ETL)
   Alumno: Jorge Alberto Rodríguez Enríquez

   Deja TODAS las tablas vacías (la estructura y las vistas se conservan).
   Después se ejecuta el ETL para volver a llenarlas:
        python src/etl_abalone.py

   Se usa DELETE (no TRUNCATE) porque las tablas tienen integridad
   referencial, y se borra en orden: primero las que tienen llaves
   foráneas (resultados y hechos) y al final las dimensiones.
   La bitácora Log_ETL NO se borra, para conservar el historial.
   ===================================================================== */
USE DM_Abalone;
GO

DELETE FROM dbo.Res_Cluster;
DELETE FROM dbo.Res_Prediccion;
DELETE FROM dbo.Res_Metrica_Modelo;
DELETE FROM dbo.Fact_Abulon;
DELETE FROM dbo.Dim_Sexo;
DELETE FROM dbo.Dim_Grupo_Edad;
DELETE FROM dbo.Dim_Tiempo;
GO

-- Comprobación: todas deben quedar en 0
SELECT 'Dim_Tiempo' AS Tabla, COUNT(*) AS Registros FROM dbo.Dim_Tiempo
UNION ALL SELECT 'Dim_Sexo',           COUNT(*) FROM dbo.Dim_Sexo
UNION ALL SELECT 'Dim_Grupo_Edad',     COUNT(*) FROM dbo.Dim_Grupo_Edad
UNION ALL SELECT 'Fact_Abulon',        COUNT(*) FROM dbo.Fact_Abulon
UNION ALL SELECT 'Res_Cluster',        COUNT(*) FROM dbo.Res_Cluster
UNION ALL SELECT 'Res_Prediccion',     COUNT(*) FROM dbo.Res_Prediccion
UNION ALL SELECT 'Res_Metrica_Modelo', COUNT(*) FROM dbo.Res_Metrica_Modelo;
