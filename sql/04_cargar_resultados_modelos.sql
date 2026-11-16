/* =====================================================================
   Proyecto: Estimación de edad y análisis morfológico de abulones
   Script 04 - Cargar al Data Warehouse los resultados de los modelos
   Alumno: Jorge Alberto Rodríguez Enríquez

   Requisitos:
     1. Haber ejecutado 01_crear_datamart.sql y 02_cargar_datamart.sql
     2. Haber ejecutado los notebooks 06 y 07
     3. Copiar a C:\datos\ estos dos archivos de data/processed:
          abalone_clusters.csv      (perfiles de K-Means y componentes PCA)
          abalone_predicciones.csv  (predicciones de regresión y clasificación)
   ===================================================================== */
USE DM_Abalone;
GO

IF OBJECT_ID('dbo.Res_Cluster', 'U')    IS NOT NULL DROP TABLE dbo.Res_Cluster;
IF OBJECT_ID('dbo.Res_Prediccion', 'U') IS NOT NULL DROP TABLE dbo.Res_Prediccion;
GO

/* ---------- Resultados del análisis NO supervisado (notebook 06) ---------- */
CREATE TABLE dbo.Res_Cluster (
    ID_Abulon  INT          NOT NULL PRIMARY KEY REFERENCES dbo.Fact_Abulon(ID_Abulon),
    Cluster    INT          NOT NULL,        -- número que asignó K-Means (0, 1 o 2)
    Perfil     VARCHAR(10)  NOT NULL,        -- Pequeño, Mediano o Grande
    PC1        FLOAT        NOT NULL,        -- componente 1 de PCA (tamaño general)
    PC2        FLOAT        NOT NULL         -- componente 2 de PCA (forma)
);

/* ---------- Resultados del análisis supervisado (notebook 07) ---------- */
CREATE TABLE dbo.Res_Prediccion (
    ID_Abulon              INT           NOT NULL PRIMARY KEY REFERENCES dbo.Fact_Abulon(ID_Abulon),
    Conjunto_Regresion     VARCHAR(15)   NOT NULL,   -- Entrenamiento o Prueba
    Conjunto_Clasificacion VARCHAR(15)   NOT NULL,
    Rings_Predicho         DECIMAL(5,2)  NOT NULL,
    Edad_Predicha_Anios    DECIMAL(5,2)  NOT NULL,
    Error_Absoluto         DECIMAL(5,2)  NOT NULL,   -- |Rings real - Rings predicho|
    Grupo_Predicho         VARCHAR(10)   NOT NULL,   -- Joven, Adulto o Maduro
    Acierto_Grupo          VARCHAR(5)    NOT NULL    -- Sí o No
);
GO

BULK INSERT dbo.Res_Cluster
FROM 'C:\datos\abalone_clusters.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', CODEPAGE = '65001');

BULK INSERT dbo.Res_Prediccion
FROM 'C:\datos\abalone_predicciones.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', CODEPAGE = '65001');
GO

-- Quitar un posible salto de línea de Windows al final de la última columna
UPDATE dbo.Res_Prediccion SET Acierto_Grupo = REPLACE(Acierto_Grupo, CHAR(13), '');
GO

-- Validación: ambas deben tener 4,169 registros
SELECT 'Res_Cluster' AS Tabla, COUNT(*) AS Registros FROM dbo.Res_Cluster
UNION ALL
SELECT 'Res_Prediccion', COUNT(*) FROM dbo.Res_Prediccion;
