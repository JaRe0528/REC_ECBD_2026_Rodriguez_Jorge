# REC_ECBD_2026_Rodriguez_Jorge

**Asignatura:** Extracción de Conocimiento en Bases de Datos (Recursamiento 2026)

**Estudiante:** Jorge Alberto Rodríguez Enríquez — 9 IDGS G2, UTTT

**Proyecto:** Estimación de edad y análisis morfológico de abulones

## Descripción del proyecto
Actualmente la edad de un abulón se determina cortando su concha, tiñéndola y contando sus anillos con un microscopio, un proceso lento y que requiere laboratorio. Este proyecto busca estimar la edad del abulón a partir de medidas físicas fáciles de obtener (sexo, dimensiones y pesos), clasificarlo por grupo de edad e identificar perfiles morfológicos.

**Pregunta principal:** ¿En qué medida las características físicas del abulón (sexo, dimensiones y pesos) permiten estimar su edad y reconocer perfiles o etapas de crecimiento?

## Dataset
- **Nombre:** Abalone
- **Fuente:** UCI Machine Learning Repository — https://archive.ics.uci.edu/dataset/1/abalone
- **Cita:** Nash, W., Sellers, T., Talbot, S., Cawthorn, A., & Ford, W. (1994). Abalone [Dataset]. https://doi.org/10.24432/C55C7W
- **Tamaño:** 4,177 registros, 8 variables + 1 variable objetivo (Rings)
- **Licencia:** CC BY 4.0

## Forma de trabajo
- **Metodología:** CRISP-DM (6 fases), aplicada a lo largo de las 5 unidades.
- **Herramientas:** Python 3, Jupyter/VS Code, Pandas, NumPy, scikit-learn, Matplotlib, SQL Server, Power BI, Git/GitHub.
- **Regla de datos:** `data/raw` conserva el original sin modificar; los datos limpios van en `data/processed`.
- **Regresión:** predecir `Rings` (edad ≈ Rings + 1.5 años).
- **Clasificación:** Grupo_Edad → Joven (Rings ≤ 8), Adulto (9–10), Maduro (≥ 11).
- **No supervisado:** K-Means + PCA sobre las medidas físicas.
- **Entregas:** los documentos de cada unidad se guardan en `docs/`.

## Unidad II — Preparación de datos
| Archivo | Contenido |
|---|---|
| `notebooks/01_carga_y_diccionario.ipynb` | Carga del dataset y diccionario de datos (`docs/diccionario_datos.csv`) |
| `notebooks/02_analisis_exploratorio.ipynb` | EDA: estadísticas, gráficas (`docs/figuras/`), atípicos y correlaciones |
| `notebooks/03_limpieza_etl.ipynb` | ETL: elimina 8 registros físicamente imposibles, crea unidades reales, `Edad_anios`, `Grupo_Edad` e ID → `data/processed/abalone_limpio.csv` (4,169 registros) |
| `sql/01_crear_datamart.sql` | Crea el Data Mart `DM_Abalone` (esquema estrella: `Dim_Sexo`, `Dim_Grupo_Edad`, `Fact_Abulon`) |
| `sql/02_cargar_datamart.sql` | Carga el CSV procesado al Data Mart |
| `sql/03_consultas_validacion.sql` | Consultas de validación |
| `docs/figuras/11_*`, `12_*`, `13_*` | Evidencias de ejecución en SQL Server 2025 Express (4,169 registros cargados en `Fact_Abulon`) |

## Unidad III — Análisis supervisado
| Archivo | Contenido |
|---|---|
| `notebooks/04_regresion.ipynb` | Predice `Rings` con regresión lineal, árbol de decisión y Random Forest; optimización con GridSearchCV |
| `notebooks/05_clasificacion.ipynb` | Clasifica `Grupo_Edad` con regresión logística, KNN y Random Forest; matriz de confusión |
| `docs/metricas_regresion.csv`, `docs/metricas_clasificacion.csv` | Métricas de comparación |
| `modelos/*.joblib` | Modelos optimizados guardados |

**Resultados principales:** regresión → Random Forest optimizado con MAE ≈ 1.49 anillos y R² ≈ 0.61 (baseline MAE ≈ 2.52). Clasificación → exactitud ≈ 64% (azar = 33%); la clase Adulto es la más difícil.

## Cómo ejecutar el proyecto
```
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```
Después abrir los notebooks en VS Code (kernel `.venv`) y ejecutarlos en orden 01 → 02 → 03. Para el Data Mart, ejecutar los scripts de `sql/` en SQL Server Management Studio en orden 01 → 02 → 03.

## Estructura del repositorio
- `data/raw/` — datos originales sin modificar
- `data/processed/` — datos limpios y transformados
- `notebooks/` — análisis en Jupyter
- `src/` — scripts de Python
- `sql/` — scripts del Data Warehouse / Data Mart
- `modelos/` — modelos entrenados
- `dashboard/` — dashboard en Power BI
- `docs/` — documentos y entregas

## Avance
- [x] Actividad 0 — Inicio y registro
- [x] Unidad I — Planeación del proyecto
- [x] Unidad II — Preparación de datos (notebooks 01–03 y Data Mart probado en SQL Server)
- [ ] Unidad III — Análisis supervisado (modelos funcionando; falta informe)
- [ ] Unidad IV — Análisis no supervisado
- [ ] Unidad V — Presentación y visualización
