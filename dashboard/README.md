# Dashboard en Power BI

Conecta Power BI a la base de datos **DM_Abalone** de SQL Server y usa las vistas del Data Mart (`sql/02_vistas_datamart.sql`). Los datos los carga el ETL automático (`src/etl_abalone.py`); después de cada ejecución del ETL, en Power BI da clic en **Inicio → Actualizar**..

| Archivo | Uso |
|---|---|
| `fondo_dashboard_abulones.png` | Plantilla de fondo (1920×1080) con los espacios para cada gráfica |
| `tema_abulones.json` | Tema de colores del proyecto (Vista → Temas → Buscar temas) |
| `Dashboard_Abulones.pbix` | Archivo del dashboard (se agrega al terminarlo en Power BI Desktop) |

## Gráficas y de dónde salen sus datos (vista `vw_DM_Abalone`)
| Espacio | Visual | Campos |
|---|---|---|
| Abulones analizados | Tarjeta | Recuento de `ID_Abulon` |
| Edad promedio (años) | Tarjeta | Promedio de `Edad_Anios` |
| Error regresión (MAE) | Tarjeta | Promedio de `Error_Absoluto` · filtro `Conjunto_Regresion = Prueba` |
| Exactitud clasificación | Tarjeta | `vw_DM_Desempeno_Modelos` |
| Perfiles morfológicos | Dispersión | X `PC1`, Y `PC2`, leyenda `Perfil_Morfologico` |
| Edad real vs. predicha | Dispersión | X `Rings`, Y `Rings_Predicho` · filtro `Conjunto_Regresion = Prueba` |
| Abulones por grupo de edad | Columnas | Eje `Grupo_Edad`, valor recuento de `ID_Abulon` |
| Medidas promedio por perfil | Columnas agrupadas | Eje `Perfil_Morfologico`, promedios de `Longitud_mm`, `Peso_Total_g`, `Peso_Concha_g` |
| Edad promedio por sexo | Barras | Eje `Sexo`, promedio de `Edad_Anios` |
| Filtro por mes (segmentación) | Segmentación | `Nombre_Mes` u `Anio_Mes` (dimensión de tiempo) |
