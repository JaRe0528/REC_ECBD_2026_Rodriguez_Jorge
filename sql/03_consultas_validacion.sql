/* =====================================================================
   Script 03 - Consultas de validación del Data Warehouse
   Ejecutar después del ETL para comprobar que la carga quedó bien.
   ===================================================================== */
USE DM_Abalone;
GO

-- 1) Conteo de cada tabla (después de cada carga full debe ser IGUAL)
SELECT 'Dim_Tiempo' AS Tabla, COUNT(*) AS Registros FROM dbo.Dim_Tiempo
UNION ALL SELECT 'Dim_Sexo',           COUNT(*) FROM dbo.Dim_Sexo
UNION ALL SELECT 'Dim_Grupo_Edad',     COUNT(*) FROM dbo.Dim_Grupo_Edad
UNION ALL SELECT 'Fact_Abulon',        COUNT(*) FROM dbo.Fact_Abulon
UNION ALL SELECT 'Res_Cluster',        COUNT(*) FROM dbo.Res_Cluster
UNION ALL SELECT 'Res_Prediccion',     COUNT(*) FROM dbo.Res_Prediccion
UNION ALL SELECT 'Res_Metrica_Modelo', COUNT(*) FROM dbo.Res_Metrica_Modelo;

-- 2) Bitácora del ETL: cada ejecución queda registrada
SELECT * FROM dbo.Log_ETL ORDER BY ID_Ejecucion DESC;

-- 3) Abulones muestreados por mes (uso de la dimensión de tiempo)
SELECT t.Anio_Mes, t.Nombre_Mes, COUNT(*) AS Abulones,
       CAST(AVG(f.Edad_Anios) AS DECIMAL(5,2)) AS Edad_Promedio
FROM dbo.Fact_Abulon f
JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo = f.ID_Tiempo
GROUP BY t.Anio_Mes, t.Nombre_Mes
ORDER BY t.Anio_Mes;

-- 4) Registros por sexo y grupo de edad
SELECT s.Descripcion AS Sexo, g.Grupo, COUNT(*) AS Total
FROM dbo.Fact_Abulon f
JOIN dbo.Dim_Sexo s       ON s.ID_Sexo = f.ID_Sexo
JOIN dbo.Dim_Grupo_Edad g ON g.ID_Grupo_Edad = f.ID_Grupo_Edad
GROUP BY s.Descripcion, g.Grupo, g.ID_Grupo_Edad
ORDER BY s.Descripcion, g.ID_Grupo_Edad;

-- 5) Desempeño de todos los modelos (guardado por el ETL)
SELECT * FROM dbo.vw_DM_Comparacion_Modelos ORDER BY Tipo_Analisis, Modelo, Metrica;
