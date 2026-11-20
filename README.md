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

## Unidad II — Actividad de Evaluación 1: Exploración y diagnóstico
| Archivo | Contenido |
|---|---|
| `notebooks/Rodriguez_Enriquez_Jorge_Alberto_U2_AE1_Exploracion.ipynb` | Carga, `head/shape/columns/info/dtypes/describe`, diccionario de datos, tipo y fuente, faltantes, duplicados, inconsistencias, estadística, boxplots, visualizaciones y propuestas de análisis (sin modificar los datos) |
| `docs/Rodriguez_Enriquez_Jorge_Alberto_U2_AE1_Diagnostico.pdf` | Informe de diagnóstico |
| `docs/figuras/ae1_*.png` | Gráficas generadas por el notebook |

**Diagnóstico:** 4,177 registros, 9 variables, sin faltantes ni duplicados; menos del 0.3% de registros con valores físicamente imposibles (alturas en 0 o extremas, partes que pesan más que el total).

## Unidad II — Preparación de datos
| Archivo | Contenido |
|---|---|
| `notebooks/01_carga_y_diccionario.ipynb` | Carga del dataset y diccionario de datos (`docs/diccionario_datos.csv`) |
| `notebooks/02_analisis_exploratorio.ipynb` | EDA: estadísticas, gráficas (`docs/figuras/`), atípicos y correlaciones |
| `notebooks/03_limpieza_etl.ipynb` | ETL: elimina 8 registros físicamente imposibles, crea unidades reales, `Edad_anios`, `Grupo_Edad` e ID → `data/processed/abalone_limpio.csv` (4,169 registros) |
| Data Warehouse y ETL | Ver la sección **Data Warehouse, ETL automático y Data Mart** |
| `docs/figuras/11_*`, `12_*`, `13_*` | Evidencias de ejecución en SQL Server 2025 Express (4,169 registros cargados en `Fact_Abulon`) |

## Unidad III — Análisis supervisado
| Archivo | Contenido |
|---|---|
| `notebooks/04_regresion.ipynb` | Predice `Rings` con regresión lineal, árbol de decisión y Random Forest; optimización con GridSearchCV |
| `notebooks/05_clasificacion.ipynb` | Clasifica `Grupo_Edad` con regresión logística, KNN y Random Forest; matriz de confusión |
| `docs/metricas_regresion.csv`, `docs/metricas_clasificacion.csv` | Métricas de comparación |
| `modelos/*.joblib` | Modelos optimizados guardados |

**Resultados principales:** regresión → Random Forest optimizado con MAE ≈ 1.49 anillos y R² ≈ 0.61 (baseline MAE ≈ 2.52). Clasificación → exactitud ≈ 64% (azar = 33%); la clase Adulto es la más difícil.

## Unidad IV — Análisis no supervisado
| Archivo | Contenido |
|---|---|
| `notebooks/06_no_supervisado.ipynb` | K-Means (método del codo y silueta, k = 3) y PCA; perfiles Pequeño / Mediano / Grande |
| `notebooks/07_predicciones_dashboard.ipynb` | Predicciones de los modelos por abulón (marcando Entrenamiento / Prueba) para el dashboard |
| `data/processed/abalone_clusters.csv`, `data/processed/abalone_predicciones.csv` | Resultados que se cargan al Data Warehouse |
| `docs/metricas_clustering.csv`, `docs/perfiles_clusters.csv` | Métricas y perfiles |
| `notebooks/08_funciones_de_los_modelos.ipynb` | **Qué modelo se usó y la función que generó cada uno**: ecuación de la regresión lineal (y = mx + b y múltiple), reglas del árbol, coeficientes de la regresión logística, centros de K-Means y ecuación de PC1 |
| `modelos/kmeans_pca.joblib` | Modelo K-Means + PCA guardado |

**Resultados:** 3 perfiles morfológicos (silueta 0.44). Sin conocer la edad, el perfil Pequeño es 71% infantes y el Grande 58% maduros. PC1 (tamaño general) concentra el 92.5% de la información de las 7 medidas.

## Data Warehouse, ETL automático y Data Mart
| Archivo | Contenido |
|---|---|
| `sql/01_crear_datamart.sql` | Crea el **esquema estrella**: `Dim_Tiempo`, `Dim_Sexo`, `Dim_Grupo_Edad`, `Fact_Abulon`, tablas de resultados (`Res_Cluster`, `Res_Prediccion`, `Res_Metrica_Modelo`), bitácora `Log_ETL` y el procedimiento **`sp_Generar_Dim_Tiempo`** |
| `src/etl_abalone.py` | **ETL automático con carga FULL**: extrae de `data/raw`, transforma, aplica los modelos y carga todo en SQL Server |
| `src/ejecutar_etl.bat` | Ejecuta el ETL; programado en el **Programador de tareas de Windows** todos los días a las 3:00 a.m. (bitácora en `logs/etl.log` y en la tabla `Log_ETL`) |
| `sql/02_vistas_datamart.sql` | **Data Mart** como vistas: `vw_DM_Abalone`, `vw_DM_Resumen_Perfil`, `vw_DM_Desempeno_Modelos`, `vw_DM_Comparacion_Modelos` |
| `sql/03_consultas_validacion.sql` | Conteos, bitácora del ETL y consultas por mes |
| `sql/04_vaciar_datawarehouse.sql` | Deja vacías todas las tablas (demostración: vaciar → ejecutar ETL → volver a ejecutar ETL) |
| `docs/figuras/28_esquema_estrella_final.png` | Diagrama del esquema estrella final (con Dim_Tiempo y tablas de resultados) |
| `dashboard/` | Dashboard de Power BI conectado a las vistas del Data Mart |

**Orden de ejecución:** notebooks 01 → 07 (exploración y entrenamiento de modelos) → `sql/01` (una vez) → `python src/etl_abalone.py` → `sql/02` → Power BI (Inicio → Actualizar).

> El dataset original no tiene fechas, por lo que el ETL asigna a cada abulón una **fecha de muestreo simulada** (días hábiles de enero a diciembre de 2026, con semilla fija). `Dim_Tiempo` se genera con un procedimiento almacenado de 2026 a 2035.

![Dashboard](dashboard/captura_dashboard.png)

## Cómo ejecutar el proyecto
```
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```
Después ejecutar los notebooks en orden (kernel `.venv`), crear el Data Warehouse con `sql/01_crear_datamart.sql` en SSMS, correr el ETL con `python src/etl_abalone.py` y crear las vistas con `sql/02_vistas_datamart.sql`.

## Resultados principales
| Análisis | Modelo final | Resultado (datos de prueba) |
|---|---|---|
| Regresión (anillos) | Random Forest Regressor (200 árboles, optimizado con GridSearchCV) | MAE = 1.49 anillos · R² = 0.61 |
| Clasificación (Joven/Adulto/Maduro) | Random Forest Classifier (optimizado) | Exactitud = 64.1 % · F1 = 0.64 |
| Agrupamiento | K-Means (k = 3) + PCA | Silueta = 0.44 · PC1 = 92.5 % de la varianza |

## Conclusiones
1. Las medidas físicas **sí permiten estimar la edad** del abulón con un error promedio de **1.5 años** y clasificar su etapa de crecimiento con **64 %** de exactitud, sin sacrificarlo.
2. El **peso de la concha** es la variable más relacionada con la edad (correlación 0.63; 42 % de importancia).
3. La precisión baja en abulones viejos: después de la madurez el crecimiento se detiene y el tamaño deja de reflejar la edad.
4. K-Means encontró **tres perfiles morfológicos** (Pequeño, Mediano, Grande) que coinciden con la madurez sin conocer la edad; PCA mostró que el tamaño general resume el 92.5 % de la información.
5. La arquitectura **ETL automático → Data Warehouse → Data Mart → Power BI** permite actualizar todo el análisis con un solo comando y de forma programada.

## Recomendaciones
- **Granjas de acuicultura:** usar el modelo como prueba rápida y no destructiva para decidir la cosecha; confirmar al microscopio solo los casos dudosos.
- **Muestreo:** registrar siempre el peso de la concha, la altura y el sexo.
- **Manejo pesquero:** devolver al mar los ejemplares del perfil Pequeño, que son mayoritariamente juveniles.
- **Mejora del modelo:** agregar variables ambientales y fechas reales de muestreo, y probar Gradient Boosting.
- **Operación:** cambiar a carga incremental cuando el volumen de datos crezca.

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
- [x] Unidad III — Análisis supervisado (regresión y clasificación con entrenamiento/prueba)
- [x] Unidad IV — Análisis no supervisado (K-Means + PCA)
- [x] Unidad V — Dashboard en Power BI conectado al Data Mart de SQL Server
- [x] Informe final, conclusiones y recomendaciones (`docs/Rodriguez_Enriquez_Jorge_Alberto_Informe_Final_Proyecto_Integrador.pdf`)
