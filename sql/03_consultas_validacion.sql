/* =====================================================================
   Unidad II - Consultas de validación y exploración del Data Mart
   ===================================================================== */
USE DM_Abalone;
GO

-- Registros por sexo
SELECT d.Descripcion AS Sexo, COUNT(*) AS Total,
       CAST(AVG(f.Rings * 1.0) AS DECIMAL(5,2)) AS Promedio_Rings
FROM dbo.Fact_Abulon f
JOIN dbo.Dim_Sexo d ON d.ID_Sexo = f.ID_Sexo
GROUP BY d.Descripcion;

-- Registros por grupo de edad (deben estar balanceados, ~33% cada uno)
SELECT g.Grupo, COUNT(*) AS Total,
       CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dbo.Fact_Abulon) AS DECIMAL(5,1)) AS Porcentaje
FROM dbo.Fact_Abulon f
JOIN dbo.Dim_Grupo_Edad g ON g.ID_Grupo_Edad = f.ID_Grupo_Edad
GROUP BY g.Grupo, g.ID_Grupo_Edad
ORDER BY g.ID_Grupo_Edad;

-- Medidas promedio por sexo y grupo de edad
SELECT d.Descripcion AS Sexo, g.Grupo,
       CAST(AVG(f.Longitud_mm)   AS DECIMAL(6,1)) AS Longitud_Prom_mm,
       CAST(AVG(f.Peso_Total_g)  AS DECIMAL(7,1)) AS Peso_Prom_g,
       CAST(AVG(f.Peso_Concha_g) AS DECIMAL(7,1)) AS Concha_Prom_g
FROM dbo.Fact_Abulon f
JOIN dbo.Dim_Sexo d       ON d.ID_Sexo = f.ID_Sexo
JOIN dbo.Dim_Grupo_Edad g ON g.ID_Grupo_Edad = f.ID_Grupo_Edad
GROUP BY d.Descripcion, g.Grupo, g.ID_Grupo_Edad
ORDER BY d.Descripcion, g.ID_Grupo_Edad;
