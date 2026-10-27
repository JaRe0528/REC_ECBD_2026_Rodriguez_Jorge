/* =====================================================================
   Proyecto: Estimación de edad y análisis morfológico de abulones
   Unidad II - Data Mart (esquema estrella) en SQL Server
   Alumno: Jorge Alberto Rodríguez Enríquez

   Esquema estrella:
     - Dim_Sexo        -> quién es el abulón (macho, hembra, infante)
     - Dim_Grupo_Edad  -> etapa de crecimiento (Joven, Adulto, Maduro)
     - Fact_Abulon     -> una fila por abulón con sus medidas (hechos)
   ===================================================================== */

IF DB_ID('DM_Abalone') IS NULL
    CREATE DATABASE DM_Abalone;
GO

USE DM_Abalone;
GO

-- Se borran en orden inverso por las llaves foráneas
IF OBJECT_ID('dbo.Fact_Abulon', 'U')    IS NOT NULL DROP TABLE dbo.Fact_Abulon;
IF OBJECT_ID('dbo.Dim_Sexo', 'U')       IS NOT NULL DROP TABLE dbo.Dim_Sexo;
IF OBJECT_ID('dbo.Dim_Grupo_Edad', 'U') IS NOT NULL DROP TABLE dbo.Dim_Grupo_Edad;
IF OBJECT_ID('dbo.Stg_Abalone', 'U')    IS NOT NULL DROP TABLE dbo.Stg_Abalone;
GO

/* ---------- Dimensión: Sexo ---------- */
CREATE TABLE dbo.Dim_Sexo (
    ID_Sexo      INT          NOT NULL PRIMARY KEY,
    Codigo       CHAR(1)      NOT NULL UNIQUE,   -- M, F, I
    Descripcion  VARCHAR(20)  NOT NULL           -- Macho, Hembra, Infante
);

INSERT INTO dbo.Dim_Sexo (ID_Sexo, Codigo, Descripcion) VALUES
    (1, 'M', 'Macho'),
    (2, 'F', 'Hembra'),
    (3, 'I', 'Infante');

/* ---------- Dimensión: Grupo de edad ----------
   Criterio documentado en la Unidad I (cuartiles de Rings) */
CREATE TABLE dbo.Dim_Grupo_Edad (
    ID_Grupo_Edad  INT          NOT NULL PRIMARY KEY,
    Grupo          VARCHAR(10)  NOT NULL UNIQUE,
    Rings_Min      INT          NOT NULL,
    Rings_Max      INT          NULL,             -- NULL = sin límite superior
    Edad_Min_Anios DECIMAL(4,1) NOT NULL,
    Descripcion    VARCHAR(60)  NOT NULL
);

INSERT INTO dbo.Dim_Grupo_Edad VALUES
    (1, 'Joven',  1,  8,    2.5,  'Rings <= 8 (hasta 9.5 años)'),
    (2, 'Adulto', 9,  10,   10.5, '9 <= Rings <= 10 (10.5 a 11.5 años)'),
    (3, 'Maduro', 11, NULL, 12.5, 'Rings >= 11 (12.5 años o más)');

/* ---------- Tabla de hechos ---------- */
CREATE TABLE dbo.Fact_Abulon (
    ID_Abulon         INT           NOT NULL PRIMARY KEY,
    ID_Sexo           INT           NOT NULL REFERENCES dbo.Dim_Sexo(ID_Sexo),
    ID_Grupo_Edad     INT           NOT NULL REFERENCES dbo.Dim_Grupo_Edad(ID_Grupo_Edad),
    Longitud_mm       DECIMAL(6,1)  NOT NULL,
    Diametro_mm       DECIMAL(6,1)  NOT NULL,
    Altura_mm         DECIMAL(6,1)  NOT NULL,
    Peso_Total_g      DECIMAL(7,1)  NOT NULL,
    Peso_Carne_g      DECIMAL(7,1)  NOT NULL,
    Peso_Visceras_g   DECIMAL(7,1)  NOT NULL,
    Peso_Concha_g     DECIMAL(7,1)  NOT NULL,
    Rings             INT           NOT NULL,
    Edad_Anios        DECIMAL(4,1)  NOT NULL
);

/* ---------- Tabla temporal (staging) ----------
   Recibe el CSV de data/processed tal cual, antes de repartirlo
   en dimensiones y hechos. Columnas en el mismo orden que el CSV. */
CREATE TABLE dbo.Stg_Abalone (
    ID_Abulon        INT,
    Sex              CHAR(1),
    Length           FLOAT,
    Diameter         FLOAT,
    Height           FLOAT,
    Whole_weight     FLOAT,
    Shucked_weight   FLOAT,
    Viscera_weight   FLOAT,
    Shell_weight     FLOAT,
    Rings            INT,
    Sexo             VARCHAR(20),
    Length_mm        FLOAT,
    Diameter_mm      FLOAT,
    Height_mm        FLOAT,
    Whole_weight_g   FLOAT,
    Shucked_weight_g FLOAT,
    Viscera_weight_g FLOAT,
    Shell_weight_g   FLOAT,
    Edad_anios       FLOAT,
    Grupo_Edad       VARCHAR(10)
);
GO

PRINT 'Data Mart DM_Abalone creado correctamente.';
