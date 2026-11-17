/* =====================================================================
   Proyecto: Estimación de edad y análisis morfológico de abulones
   Script 01 - Crear el Data Warehouse (esquema estrella)
   Alumno: Jorge Alberto Rodríguez Enríquez

   Se ejecuta UNA sola vez (o cuando se quiera reconstruir todo).
   Después, los datos los carga AUTOMÁTICAMENTE el ETL:
        python src/etl_abalone.py

   Esquema estrella:
     Dimensiones : Dim_Tiempo, Dim_Sexo, Dim_Grupo_Edad
     Hechos      : Fact_Abulon   (una fila por abulón muestreado)
     Resultados  : Res_Cluster, Res_Prediccion, Res_Metrica_Modelo
     Control     : Log_ETL       (bitácora de cada ejecución del ETL)
   ===================================================================== */

IF DB_ID('DM_Abalone') IS NULL
    CREATE DATABASE DM_Abalone;
GO

USE DM_Abalone;
GO

/* Se borran en orden inverso por las llaves foráneas (vistas primero) */
IF OBJECT_ID('dbo.vw_DM_Desempeno_Modelos', 'V')   IS NOT NULL DROP VIEW dbo.vw_DM_Desempeno_Modelos;
IF OBJECT_ID('dbo.vw_DM_Comparacion_Modelos', 'V') IS NOT NULL DROP VIEW dbo.vw_DM_Comparacion_Modelos;
IF OBJECT_ID('dbo.vw_DM_Resumen_Perfil', 'V')      IS NOT NULL DROP VIEW dbo.vw_DM_Resumen_Perfil;
IF OBJECT_ID('dbo.vw_DM_Abalone', 'V')             IS NOT NULL DROP VIEW dbo.vw_DM_Abalone;
IF OBJECT_ID('dbo.Res_Cluster', 'U')        IS NOT NULL DROP TABLE dbo.Res_Cluster;
IF OBJECT_ID('dbo.Res_Prediccion', 'U')     IS NOT NULL DROP TABLE dbo.Res_Prediccion;
IF OBJECT_ID('dbo.Res_Metrica_Modelo', 'U') IS NOT NULL DROP TABLE dbo.Res_Metrica_Modelo;
IF OBJECT_ID('dbo.Fact_Abulon', 'U')        IS NOT NULL DROP TABLE dbo.Fact_Abulon;
IF OBJECT_ID('dbo.Dim_Sexo', 'U')           IS NOT NULL DROP TABLE dbo.Dim_Sexo;
IF OBJECT_ID('dbo.Dim_Grupo_Edad', 'U')     IS NOT NULL DROP TABLE dbo.Dim_Grupo_Edad;
IF OBJECT_ID('dbo.Dim_Tiempo', 'U')         IS NOT NULL DROP TABLE dbo.Dim_Tiempo;
IF OBJECT_ID('dbo.Stg_Abalone', 'U')        IS NOT NULL DROP TABLE dbo.Stg_Abalone;   -- versión anterior
IF OBJECT_ID('dbo.Log_ETL', 'U')            IS NOT NULL DROP TABLE dbo.Log_ETL;
GO

/* ---------------------------- DIMENSIONES ---------------------------- */
CREATE TABLE dbo.Dim_Tiempo (
    ID_Tiempo      INT          NOT NULL PRIMARY KEY,   -- formato AAAAMMDD, ej. 20260315
    Fecha          DATE         NOT NULL UNIQUE,
    Anio           SMALLINT     NOT NULL,
    Trimestre      TINYINT      NOT NULL,
    Mes            TINYINT      NOT NULL,
    Nombre_Mes     VARCHAR(12)  NOT NULL,
    Anio_Mes       CHAR(7)      NOT NULL,               -- ej. 2026-03 (útil para ordenar en Power BI)
    Semana_Anio    TINYINT      NOT NULL,
    Dia            TINYINT      NOT NULL,
    Dia_Semana     TINYINT      NOT NULL,               -- 1 = lunes ... 7 = domingo
    Nombre_Dia     VARCHAR(10)  NOT NULL,
    Es_Fin_Semana  BIT          NOT NULL
);

CREATE TABLE dbo.Dim_Sexo (
    ID_Sexo      INT          NOT NULL PRIMARY KEY,
    Codigo       CHAR(1)      NOT NULL UNIQUE,          -- M, F, I
    Descripcion  VARCHAR(20)  NOT NULL                  -- Macho, Hembra, Infante
);

CREATE TABLE dbo.Dim_Grupo_Edad (
    ID_Grupo_Edad  INT           NOT NULL PRIMARY KEY,
    Grupo          VARCHAR(10)   NOT NULL UNIQUE,
    Rings_Min      INT           NOT NULL,
    Rings_Max      INT           NULL,                  -- NULL = sin límite superior
    Edad_Min_Anios DECIMAL(4,1)  NOT NULL,
    Descripcion    VARCHAR(60)   NOT NULL
);

/* ------------------------------ HECHOS ------------------------------- */
/* Medidas: longitudes, pesos, anillos y edad.
   Llaves foráneas: ID_Tiempo, ID_Sexo, ID_Grupo_Edad                    */
CREATE TABLE dbo.Fact_Abulon (
    ID_Abulon         INT           NOT NULL PRIMARY KEY,
    ID_Tiempo         INT           NOT NULL REFERENCES dbo.Dim_Tiempo(ID_Tiempo),
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

/* ------------------- RESULTADOS DE LOS MODELOS ----------------------- */
CREATE TABLE dbo.Res_Cluster (                          -- análisis NO supervisado
    ID_Abulon  INT          NOT NULL PRIMARY KEY REFERENCES dbo.Fact_Abulon(ID_Abulon),
    Cluster    INT          NOT NULL,
    Perfil     VARCHAR(10)  NOT NULL,                   -- Pequeño, Mediano, Grande
    PC1        FLOAT        NOT NULL,                   -- PCA: tamaño general
    PC2        FLOAT        NOT NULL                    -- PCA: forma
);

CREATE TABLE dbo.Res_Prediccion (                       -- análisis supervisado
    ID_Abulon              INT           NOT NULL PRIMARY KEY REFERENCES dbo.Fact_Abulon(ID_Abulon),
    Conjunto_Regresion     VARCHAR(15)   NOT NULL,      -- Entrenamiento o Prueba
    Conjunto_Clasificacion VARCHAR(15)   NOT NULL,
    Rings_Predicho         DECIMAL(5,2)  NOT NULL,
    Edad_Predicha_Anios    DECIMAL(5,2)  NOT NULL,
    Error_Absoluto         DECIMAL(5,2)  NOT NULL,
    Grupo_Predicho         VARCHAR(10)   NOT NULL,
    Acierto_Grupo          VARCHAR(5)    NOT NULL       -- Sí o No
);

CREATE TABLE dbo.Res_Metrica_Modelo (                   -- desempeño de los modelos
    Modelo           VARCHAR(40)    NOT NULL,
    Tipo_Analisis    VARCHAR(20)    NOT NULL,           -- Regresión, Clasificación, Agrupamiento
    Metrica          VARCHAR(20)    NOT NULL,
    Valor            DECIMAL(10,3)  NOT NULL,
    Es_Modelo_Final  BIT            NOT NULL,           -- 1 = modelo elegido para el dashboard
    PRIMARY KEY (Modelo, Metrica)
);

/* ------------------------------ CONTROL ------------------------------ */
CREATE TABLE dbo.Log_ETL (
    ID_Ejecucion           INT IDENTITY(1,1) PRIMARY KEY,
    Fecha_Inicio           DATETIME2(0)   NOT NULL,
    Fecha_Fin              DATETIME2(0)   NULL,
    Tipo_Carga             VARCHAR(15)    NOT NULL,
    Registros_Leidos       INT            NULL,
    Registros_Descartados  INT            NULL,
    Registros_Cargados     INT            NULL,
    Estado                 VARCHAR(10)    NOT NULL,     -- OK o ERROR
    Mensaje                VARCHAR(500)   NULL
);
GO

/* =====================================================================
   PROCEDIMIENTO ALMACENADO: genera la dimensión de tiempo
   Es una dimensión "artificial": se llena con TODOS los días entre dos
   fechas, aunque todavía no haya hechos en ellos.
   Ejemplo:  EXEC dbo.sp_Generar_Dim_Tiempo '2026-01-01', '2035-12-31';
   ===================================================================== */
CREATE OR ALTER PROCEDURE dbo.sp_Generar_Dim_Tiempo
    @FechaInicio DATE,
    @FechaFin    DATE
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.Dim_Tiempo;                         -- carga full: se borra y se regenera

    DECLARE @f DATE = @FechaInicio;
    DECLARE @dia_semana TINYINT;
    WHILE @f <= @FechaFin
    BEGIN
        SET @dia_semana = (DATEDIFF(DAY, '19000101', @f) % 7) + 1;   -- 1900-01-01 fue lunes
        INSERT INTO dbo.Dim_Tiempo VALUES (
            YEAR(@f) * 10000 + MONTH(@f) * 100 + DAY(@f),
            @f,
            YEAR(@f),
            DATEPART(QUARTER, @f),
            MONTH(@f),
            CASE MONTH(@f) WHEN 1 THEN 'Enero' WHEN 2 THEN 'Febrero' WHEN 3 THEN 'Marzo'
                           WHEN 4 THEN 'Abril' WHEN 5 THEN 'Mayo' WHEN 6 THEN 'Junio'
                           WHEN 7 THEN 'Julio' WHEN 8 THEN 'Agosto' WHEN 9 THEN 'Septiembre'
                           WHEN 10 THEN 'Octubre' WHEN 11 THEN 'Noviembre' ELSE 'Diciembre' END,
            CONVERT(CHAR(7), @f, 120),
            DATEPART(ISO_WEEK, @f),
            DAY(@f),
            @dia_semana,
            CASE @dia_semana WHEN 1 THEN 'Lunes' WHEN 2 THEN 'Martes' WHEN 3 THEN 'Miércoles'
                             WHEN 4 THEN 'Jueves' WHEN 5 THEN 'Viernes' WHEN 6 THEN 'Sábado'
                             ELSE 'Domingo' END,
            CASE WHEN @dia_semana >= 6 THEN 1 ELSE 0 END
        );
        SET @f = DATEADD(DAY, 1, @f);
    END
END;
GO

PRINT 'Data Warehouse DM_Abalone creado. Ahora ejecuta el ETL: python src/etl_abalone.py';
