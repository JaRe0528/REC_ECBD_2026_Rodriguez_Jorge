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
- [ ] Unidad II — Preparación de datos
- [ ] Unidad III — Análisis supervisado
- [ ] Unidad IV — Análisis no supervisado
- [ ] Unidad V — Presentación y visualización
