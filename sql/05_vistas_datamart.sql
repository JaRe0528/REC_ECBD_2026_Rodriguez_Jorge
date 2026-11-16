/* =====================================================================
   Proyecto: Estimación de edad y análisis morfológico de abulones
   Script 05 - DATA MART: vistas para Power BI
   Alumno: Jorge Alberto Rodríguez Enríquez

   Un Data Mart es una "parte" del Data Warehouse pensada para un
   uso concreto. Aquí se crea como VISTAS: consultas guardadas que
   juntan los hechos, las dimensiones y los resultados de los modelos
   en una sola tabla fácil de usar en Power BI.

   Requisito: haber ejecutado los scripts 01, 02 y 04.
   ===================================================================== */
USE DM_Abalone;
GO

/* ---------- Vista principal: una fila por abulón ---------- */
CREATE OR ALTER VIEW dbo.vw_DM_Abalone AS
SELECT
    f.ID_Abulon,
    s.Descripcion            AS Sexo,
    g.Grupo                  AS Grupo_Edad,
    g.ID_Grupo_Edad          AS Orden_Grupo,
    f.Longitud_mm,
    f.Diametro_mm,
    f.Altura_mm,
    f.Peso_Total_g,
    f.Peso_Carne_g,
    f.Peso_Visceras_g,
    f.Peso_Concha_g,
    f.Rings,
    f.Edad_Anios,
    c.Perfil                 AS Perfil_Morfologico,
    CASE c.Perfil WHEN 'Pequeño' THEN 1 WHEN 'Mediano' THEN 2 ELSE 3 END AS Orden_Perfil,
    c.PC1,
    c.PC2,
    p.Conjunto_Regresion,
    p.Conjunto_Clasificacion,
    p.Rings_Predicho,
    p.Edad_Predicha_Anios,
    p.Error_Absoluto,
    p.Grupo_Predicho,
    p.Acierto_Grupo
FROM dbo.Fact_Abulon f
JOIN dbo.Dim_Sexo       s ON s.ID_Sexo       = f.ID_Sexo
JOIN dbo.Dim_Grupo_Edad g ON g.ID_Grupo_Edad = f.ID_Grupo_Edad
LEFT JOIN dbo.Res_Cluster    c ON c.ID_Abulon = f.ID_Abulon
LEFT JOIN dbo.Res_Prediccion p ON p.ID_Abulon = f.ID_Abulon;
GO

/* ---------- Resumen de perfiles (análisis no supervisado) ---------- */
CREATE OR ALTER VIEW dbo.vw_DM_Resumen_Perfil AS
SELECT
    Perfil_Morfologico,
    Orden_Perfil,
    COUNT(*)                                        AS Abulones,
    CAST(AVG(Longitud_mm)   AS DECIMAL(6,1))        AS Longitud_Prom_mm,
    CAST(AVG(Peso_Total_g)  AS DECIMAL(7,1))        AS Peso_Total_Prom_g,
    CAST(AVG(Peso_Concha_g) AS DECIMAL(7,1))        AS Peso_Concha_Prom_g,
    CAST(AVG(Rings * 1.0)   AS DECIMAL(5,2))        AS Rings_Prom,
    CAST(AVG(Edad_Anios)    AS DECIMAL(5,2))        AS Edad_Prom_Anios,
    CAST(100.0 * SUM(CASE WHEN Sexo = 'Infante' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS Pct_Infantes
FROM dbo.vw_DM_Abalone
GROUP BY Perfil_Morfologico, Orden_Perfil;
GO

/* ---------- Desempeño de los modelos (solo datos de PRUEBA) ---------- */
CREATE OR ALTER VIEW dbo.vw_DM_Desempeno_Modelos AS
SELECT 'Regresión (Random Forest)' AS Modelo,
       'MAE (anillos)'              AS Metrica,
       CAST(AVG(Error_Absoluto) AS DECIMAL(6,3)) AS Valor
FROM dbo.vw_DM_Abalone WHERE Conjunto_Regresion = 'Prueba'
UNION ALL
SELECT 'Clasificación (Random Forest)',
       'Exactitud (%)',
       CAST(100.0 * SUM(CASE WHEN Acierto_Grupo = 'Sí' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(6,1))
FROM dbo.vw_DM_Abalone WHERE Conjunto_Clasificacion = 'Prueba';
GO

-- Pruebas rápidas de las vistas
SELECT TOP 10 * FROM dbo.vw_DM_Abalone;
SELECT * FROM dbo.vw_DM_Resumen_Perfil ORDER BY Orden_Perfil;
SELECT * FROM dbo.vw_DM_Desempeno_Modelos;
