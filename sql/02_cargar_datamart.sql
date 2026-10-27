/* =====================================================================
   Unidad II - Carga del Data Mart (la "L" del ETL)
   Requisito: haber ejecutado antes 01_crear_datamart.sql

   ⚠️ Antes de ejecutar, copia data/processed/abalone_limpio.csv a C:\datos\
      (SQL Server no tiene permiso de leer archivos dentro de C:\Users).
   ===================================================================== */
USE DM_Abalone;
GO

TRUNCATE TABLE dbo.Stg_Abalone;
DELETE FROM dbo.Fact_Abulon;

-- 1) Cargar el CSV limpio a la tabla staging
BULK INSERT dbo.Stg_Abalone
FROM 'C:\datos\abalone_limpio.csv'   -- copia del archivo de data/processed
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,            -- la fila 1 son los encabezados
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001'       -- UTF-8
);

-- 2) Pasar de staging a la tabla de hechos, buscando las llaves de las dimensiones
INSERT INTO dbo.Fact_Abulon (
    ID_Abulon, ID_Sexo, ID_Grupo_Edad,
    Longitud_mm, Diametro_mm, Altura_mm,
    Peso_Total_g, Peso_Carne_g, Peso_Visceras_g, Peso_Concha_g,
    Rings, Edad_Anios
)
SELECT
    s.ID_Abulon, ds.ID_Sexo, dg.ID_Grupo_Edad,
    s.Length_mm, s.Diameter_mm, s.Height_mm,
    s.Whole_weight_g, s.Shucked_weight_g, s.Viscera_weight_g, s.Shell_weight_g,
    s.Rings, s.Edad_anios
FROM dbo.Stg_Abalone s
JOIN dbo.Dim_Sexo       ds ON ds.Codigo = s.Sex
JOIN dbo.Dim_Grupo_Edad dg ON dg.Grupo  = REPLACE(s.Grupo_Edad, CHAR(13), '');  -- quita un posible salto de linea de Windows
GO

-- 3) Validación: deben ser 4,169 registros
SELECT COUNT(*) AS Registros_Cargados FROM dbo.Fact_Abulon;
