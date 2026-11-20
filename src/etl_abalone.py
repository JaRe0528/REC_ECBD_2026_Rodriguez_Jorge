"""
ETL automático del Proyecto Integrador: Abalone -> Data Warehouse (SQL Server)
Alumno: Jorge Alberto Rodríguez Enríquez

Uso (desde la carpeta del proyecto, con el entorno .venv activado):

    python src/etl_abalone.py

Qué hace en UNA sola ejecución:
  E - EXTRAER   : lee el archivo ORIGINAL data/raw/abalone.data (sin modificarlo).
  T - TRANSFORMAR: limpia registros imposibles, convierte a unidades reales,
                   crea Edad, Grupo de edad, ID y Fecha de muestreo, y aplica los
                   modelos entrenados (regresión, clasificación, K-Means y PCA).
  L - CARGAR    : CARGA FULL en SQL Server. Primero BORRA el destino (en orden,
                   por la integridad referencial) y después inserta todo dentro
                   de una transacción. Si algo falla, se deshace todo.

Si se ejecuta dos o más veces, el Data Warehouse queda IGUAL (no se duplican
datos). Cada ejecución queda registrada en la tabla dbo.Log_ETL.

Requisito previo: haber creado las tablas con sql/01_crear_datamart.sql

Para vaciar todas las tablas (demostración):  python src/etl_abalone.py --vaciar
"""

import argparse
import sys
import time
from datetime import datetime
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.metrics import (accuracy_score, f1_score, mean_absolute_error,
                             mean_squared_error, r2_score, silhouette_score)
from sklearn.model_selection import train_test_split

# ---------------------------------------------------------------------------
# Configuración
# ---------------------------------------------------------------------------
RAIZ = Path(__file__).resolve().parents[1]
RUTA_RAW = RAIZ / "data" / "raw" / "abalone.data"
RUTA_PROC = RAIZ / "data" / "processed"
RUTA_MOD = RAIZ / "modelos"
RUTA_DOCS = RAIZ / "docs"

COLUMNAS = ["Sex", "Length", "Diameter", "Height", "Whole_weight",
            "Shucked_weight", "Viscera_weight", "Shell_weight", "Rings"]
MEDIDAS = COLUMNAS[1:8]
PREDICTORAS = MEDIDAS + ["Sex"]
SEMILLA = 42

# Periodo de muestreo simulado (el dataset original no trae fechas)
INICIO_MUESTREO, FIN_MUESTREO = "2026-01-05", "2026-12-18"
# Rango de la dimensión de tiempo (dimensión "artificial", hacia el futuro)
INICIO_DIM_TIEMPO, FIN_DIM_TIEMPO = "2026-01-01", "2035-12-31"


def paso(texto):
    print(f"\n[{datetime.now():%H:%M:%S}] {texto}")


# ---------------------------------------------------------------------------
# E - EXTRAER
# ---------------------------------------------------------------------------
def extraer():
    paso("EXTRAER: leyendo el archivo original de data/raw")
    df = pd.read_csv(RUTA_RAW, header=None, names=COLUMNAS)
    print(f"   Registros leídos: {len(df):,}  |  Columnas: {df.shape[1]}")
    return df


# ---------------------------------------------------------------------------
# T - TRANSFORMAR
# ---------------------------------------------------------------------------
def transformar(df_raw):
    paso("TRANSFORMAR: limpieza y nuevas columnas")
    df = df_raw.copy()

    # 1) Eliminar registros físicamente imposibles (mismas reglas del notebook 03)
    imposibles = ((df["Height"] == 0) | (df["Height"] > 0.3)
                  | (df["Shucked_weight"] > df["Whole_weight"])
                  | (df["Shell_weight"] > df["Whole_weight"]))
    descartados = int(imposibles.sum())
    df = df[~imposibles].reset_index(drop=True)
    print(f"   Registros imposibles descartados: {descartados}  ->  quedan {len(df):,}")

    # 2) Identificador, unidades reales (x200), edad y grupo de edad
    df.insert(0, "ID_Abulon", range(1, len(df) + 1))
    for col in ["Length", "Diameter", "Height"]:
        df[col + "_mm"] = (df[col] * 200).round(1)
    for col in ["Whole_weight", "Shucked_weight", "Viscera_weight", "Shell_weight"]:
        df[col + "_g"] = (df[col] * 200).round(1)
    df["Edad_anios"] = df["Rings"] + 1.5
    df["Grupo_Edad"] = pd.cut(df["Rings"], bins=[0, 8, 10, np.inf],
                              labels=["Joven", "Adulto", "Maduro"]).astype(str)

    # 3) Fecha de muestreo simulada: un año de trabajo, solo días hábiles.
    #    Semilla fija -> siempre las mismas fechas en cada ejecución.
    dias_habiles = pd.bdate_range(INICIO_MUESTREO, FIN_MUESTREO)
    rng = np.random.default_rng(SEMILLA)
    df["Fecha_Muestreo"] = np.sort(rng.choice(dias_habiles, size=len(df), replace=True))
    df["ID_Tiempo"] = df["Fecha_Muestreo"].dt.strftime("%Y%m%d").astype(int)
    print(f"   Fechas de muestreo: {df['Fecha_Muestreo'].min():%d/%m/%Y} a "
          f"{df['Fecha_Muestreo'].max():%d/%m/%Y}")

    # 4) Aplicar los modelos entrenados (notebooks 04, 05 y 06)
    paso("TRANSFORMAR: aplicando los modelos entrenados")
    X = df[PREDICTORAS]
    reg = joblib.load(RUTA_MOD / "regresion_random_forest.joblib")
    cla = joblib.load(RUTA_MOD / "clasificacion_random_forest.joblib")
    nos = joblib.load(RUTA_MOD / "kmeans_pca.joblib")

    # Misma división entrenamiento/prueba que en los notebooks 04 y 05
    _, X_test_reg = train_test_split(X, test_size=0.2, random_state=SEMILLA)
    _, X_test_cla = train_test_split(X, test_size=0.2, random_state=SEMILLA,
                                     stratify=df["Grupo_Edad"])
    df["Conjunto_Regresion"] = np.where(df.index.isin(X_test_reg.index), "Prueba", "Entrenamiento")
    df["Conjunto_Clasificacion"] = np.where(df.index.isin(X_test_cla.index), "Prueba", "Entrenamiento")

    df["Rings_Predicho"] = reg.predict(X).round(2)
    df["Edad_Predicha_Anios"] = (df["Rings_Predicho"] + 1.5).round(2)
    df["Error_Absoluto"] = (df["Rings"] - df["Rings_Predicho"]).abs().round(2)
    df["Grupo_Predicho"] = cla.predict(X)
    df["Acierto_Grupo"] = np.where(df["Grupo_Edad"] == df["Grupo_Predicho"], "Sí", "No")

    X_esc = nos["escalador"].transform(df[MEDIDAS])
    df["Cluster"] = nos["kmeans"].predict(X_esc)
    df["Perfil"] = df["Cluster"].map(nos["nombres"])
    comp = nos["pca"].transform(X_esc)
    df["PC1"], df["PC2"] = comp[:, 0].round(4), comp[:, 1].round(4)

    # 5) Métricas de desempeño (solo con datos de PRUEBA)
    pr = df[df["Conjunto_Regresion"] == "Prueba"]
    pc = df[df["Conjunto_Clasificacion"] == "Prueba"]
    metricas = [
        ("Random Forest (regresión)", "Regresión", "MAE (anillos)", mean_absolute_error(pr["Rings"], pr["Rings_Predicho"]), 1),
        ("Random Forest (regresión)", "Regresión", "RMSE (anillos)", np.sqrt(mean_squared_error(pr["Rings"], pr["Rings_Predicho"])), 1),
        ("Random Forest (regresión)", "Regresión", "R2", r2_score(pr["Rings"], pr["Rings_Predicho"]), 1),
        ("Random Forest (clasificación)", "Clasificación", "Exactitud (%)", 100 * accuracy_score(pc["Grupo_Edad"], pc["Grupo_Predicho"]), 1),
        ("Random Forest (clasificación)", "Clasificación", "F1 (%)", 100 * f1_score(pc["Grupo_Edad"], pc["Grupo_Predicho"], average="macro"), 1),
        ("K-Means (k = 3)", "Agrupamiento", "Silueta", silhouette_score(X_esc, df["Cluster"]), 1),
        ("PCA", "Agrupamiento", "Varianza PC1 (%)", 100 * nos["pca"].explained_variance_ratio_[0], 1),
    ]
    # Comparación con los demás modelos probados en los notebooks 04 y 05
    for archivo, tipo, nombres in [
        ("metricas_regresion.csv", "Regresión", {"MAE": "MAE (anillos)", "RMSE": "RMSE (anillos)", "R²": "R2"}),
        ("metricas_clasificacion.csv", "Clasificación", {"Exactitud": "Exactitud (%)", "F1": "F1 (%)"}),
    ]:
        ruta = RUTA_DOCS / archivo
        if ruta.exists():
            tabla = pd.read_csv(ruta, encoding="utf-8-sig")
            for _, fila in tabla.iterrows():
                if fila["Modelo"] == "Random Forest":
                    continue  # el modelo final ya está arriba (optimizado)
                for col, metrica in nombres.items():
                    valor = fila[col] * (100 if "%" in metrica else 1)
                    metricas.append((fila["Modelo"], tipo, metrica, valor, 0))
    df_met = pd.DataFrame(metricas, columns=["Modelo", "Tipo_Analisis", "Metrica", "Valor", "Es_Modelo_Final"])
    df_met["Valor"] = df_met["Valor"].astype(float).round(3)
    print(f"   MAE regresión: {metricas[0][3]:.3f}  |  Exactitud clasificación: {metricas[3][3]:.1f}%"
          f"  |  Silueta K-Means: {metricas[5][3]:.3f}")

    # Copia del resultado transformado (trazabilidad)
    RUTA_PROC.mkdir(parents=True, exist_ok=True)
    df.to_csv(RUTA_PROC / "abalone_etl_transformado.csv", index=False,
              encoding="utf-8", lineterminator="\n", date_format="%Y-%m-%d")
    return df, df_met, descartados


# ---------------------------------------------------------------------------
# L - CARGAR (carga full)
# ---------------------------------------------------------------------------
def conectar(servidor, base):
    try:
        import pyodbc
    except ImportError:
        sys.exit("Falta la biblioteca pyodbc. Instálala con:  pip install pyodbc")
    drivers = pyodbc.drivers()
    for d in ["ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server", "SQL Server"]:
        if d in drivers:
            driver = d
            break
    else:
        sys.exit(f"No se encontró un driver ODBC de SQL Server. Drivers instalados: {drivers}")
    cadena = (f"DRIVER={{{driver}}};SERVER={servidor};DATABASE={base};"
              "Trusted_Connection=yes;")
    if driver.startswith("ODBC Driver"):
        cadena += "Encrypt=yes;TrustServerCertificate=yes;"
    print(f"   Driver: {driver}  |  Servidor: {servidor}  |  Base: {base}")
    con = pyodbc.connect(cadena, autocommit=False)
    return con, driver.startswith("ODBC Driver")


def filas(df, columnas):
    """Convierte un DataFrame en lista de tuplas con tipos nativos de Python."""
    salida = []
    for fila in df[columnas].itertuples(index=False):
        salida.append(tuple(v.item() if hasattr(v, "item") else v for v in fila))
    return salida


def cargar(df, df_met, servidor, base):
    paso("CARGAR: conectando a SQL Server")
    con, rapido = conectar(servidor, base)
    cur = con.cursor()
    cur.fast_executemany = rapido

    try:
        paso("CARGAR: borrando el destino (carga full, en orden por las llaves foráneas)")
        for tabla in ["Res_Cluster", "Res_Prediccion", "Res_Metrica_Modelo",
                      "Fact_Abulon", "Dim_Sexo", "Dim_Grupo_Edad"]:
            cur.execute(f"DELETE FROM dbo.{tabla};")
            print(f"   DELETE dbo.{tabla:<20} ({cur.rowcount} filas borradas)")

        paso("CARGAR: dimensiones")
        cur.execute("EXEC dbo.sp_Generar_Dim_Tiempo ?, ?;", INICIO_DIM_TIEMPO, FIN_DIM_TIEMPO)
        cur.execute("SELECT COUNT(*) FROM dbo.Dim_Tiempo;")
        print(f"   Dim_Tiempo      : {cur.fetchone()[0]:,} días (procedimiento sp_Generar_Dim_Tiempo)")

        cur.fast_executemany = False   # tablas pequeñas (y con un valor NULL)
        cur.executemany("INSERT INTO dbo.Dim_Sexo VALUES (?, ?, ?);",
                        [(1, "M", "Macho"), (2, "F", "Hembra"), (3, "I", "Infante")])
        cur.executemany("INSERT INTO dbo.Dim_Grupo_Edad VALUES (?, ?, ?, ?, ?, ?);", [
            (1, "Joven", 1, 8, 2.5, "Rings <= 8 (hasta 9.5 años)"),
            (2, "Adulto", 9, 10, 10.5, "9 <= Rings <= 10 (10.5 a 11.5 años)"),
            (3, "Maduro", 11, None, 12.5, "Rings >= 11 (12.5 años o más)"),
        ])
        print("   Dim_Sexo        : 3 filas  |  Dim_Grupo_Edad: 3 filas")
        cur.fast_executemany = rapido

        paso("CARGAR: tabla de hechos")
        df = df.copy()
        df["ID_Sexo"] = df["Sex"].map({"M": 1, "F": 2, "I": 3})
        df["ID_Grupo_Edad"] = df["Grupo_Edad"].map({"Joven": 1, "Adulto": 2, "Maduro": 3})
        cols_fact = ["ID_Abulon", "ID_Tiempo", "ID_Sexo", "ID_Grupo_Edad",
                     "Length_mm", "Diameter_mm", "Height_mm", "Whole_weight_g",
                     "Shucked_weight_g", "Viscera_weight_g", "Shell_weight_g",
                     "Rings", "Edad_anios"]
        cur.executemany(f"INSERT INTO dbo.Fact_Abulon VALUES ({', '.join('?' * len(cols_fact))});",
                        filas(df, cols_fact))
        print(f"   Fact_Abulon     : {len(df):,} filas")

        paso("CARGAR: resultados de los modelos")
        cur.executemany("INSERT INTO dbo.Res_Cluster VALUES (?, ?, ?, ?, ?);",
                        filas(df, ["ID_Abulon", "Cluster", "Perfil", "PC1", "PC2"]))
        cols_pred = ["ID_Abulon", "Conjunto_Regresion", "Conjunto_Clasificacion", "Rings_Predicho",
                     "Edad_Predicha_Anios", "Error_Absoluto", "Grupo_Predicho", "Acierto_Grupo"]
        cur.executemany(f"INSERT INTO dbo.Res_Prediccion VALUES ({', '.join('?' * len(cols_pred))});",
                        filas(df, cols_pred))
        cur.executemany("INSERT INTO dbo.Res_Metrica_Modelo VALUES (?, ?, ?, ?, ?);",
                        filas(df_met, list(df_met.columns)))
        print(f"   Res_Cluster     : {len(df):,} filas")
        print(f"   Res_Prediccion  : {len(df):,} filas")
        print(f"   Res_Metrica_Modelo: {len(df_met)} métricas")

        con.commit()
        print("\n   COMMIT: carga confirmada")
        return con
    except Exception:
        con.rollback()
        print("\n   ROLLBACK: hubo un error y se deshicieron todos los cambios")
        try:
            registrar_log(con, None, "ERROR", None, None, None, str(sys.exc_info()[1])[:480])
        except Exception:
            pass
        raise


def registrar_log(con, inicio, estado, leidos, descartados, cargados, mensaje):
    cur = con.cursor()
    cur.execute("INSERT INTO dbo.Log_ETL (Fecha_Inicio, Fecha_Fin, Tipo_Carga, Registros_Leidos, "
                "Registros_Descartados, Registros_Cargados, Estado, Mensaje) VALUES (?, ?, ?, ?, ?, ?, ?, ?);",
                inicio or datetime.now(), datetime.now(), "FULL", leidos, descartados, cargados, estado, mensaje)
    con.commit()


def vaciar(servidor, base):
    """Deja vacías todas las tablas del Data Warehouse (para la demostración)."""
    paso("VACIAR: borrando todas las tablas del Data Warehouse")
    con, _ = conectar(servidor, base)
    cur = con.cursor()
    try:
        for tabla in ["Res_Cluster", "Res_Prediccion", "Res_Metrica_Modelo",
                      "Fact_Abulon", "Dim_Sexo", "Dim_Grupo_Edad", "Dim_Tiempo"]:
            cur.execute(f"DELETE FROM dbo.{tabla};")
            print(f"   DELETE dbo.{tabla:<20} ({cur.rowcount} filas borradas)")
        con.commit()
    except Exception:
        con.rollback()
        raise
    registrar_log(con, datetime.now(), "OK", None, None, 0, "Vaciado del Data Warehouse (demostración)")
    validar(con)
    con.close()
    print("\nData Warehouse VACÍO. Para volver a llenarlo:  python src/etl_abalone.py")


def validar(con):
    paso("VALIDAR: conteo de registros en el Data Warehouse")
    cur = con.cursor()
    for tabla in ["Dim_Tiempo", "Dim_Sexo", "Dim_Grupo_Edad", "Fact_Abulon",
                  "Res_Cluster", "Res_Prediccion", "Res_Metrica_Modelo"]:
        cur.execute(f"SELECT COUNT(*) FROM dbo.{tabla};")
        print(f"   {tabla:<20} {cur.fetchone()[0]:>6,}")


# ---------------------------------------------------------------------------
def main():
    p = argparse.ArgumentParser(description="ETL Abalone -> SQL Server (carga full)")
    p.add_argument("--servidor", default=r"localhost\SQLEXPRESS")
    p.add_argument("--base", default="DM_Abalone")
    p.add_argument("--vaciar", action="store_true",
                   help="Solo vacía todas las tablas del Data Warehouse (no carga nada)")
    p.add_argument("--sin-cargar", action="store_true",
                   help="Solo extrae y transforma (no se conecta a SQL Server)")
    args = p.parse_args()

    if args.vaciar:
        vaciar(args.servidor, args.base)
        return

    inicio = datetime.now()
    t0 = time.time()
    print("=" * 66)
    print(" ETL ABALONE -> DATA WAREHOUSE DM_Abalone   (carga FULL)")
    print("=" * 66)

    df_raw = extraer()
    df, df_met, descartados = transformar(df_raw)
    if args.sin_cargar:
        print("\nModo --sin-cargar: no se conectó a SQL Server.")
        return

    con = cargar(df, df_met, args.servidor, args.base)
    registrar_log(con, inicio, "OK", len(df_raw), descartados, len(df),
                  "Carga full completada correctamente")
    validar(con)
    con.close()
    print(f"\nETL terminado correctamente en {time.time() - t0:.1f} segundos.")
    print("Puedes ejecutarlo de nuevo: el Data Warehouse quedará igual (no se duplican datos).")


if __name__ == "__main__":
    main()
