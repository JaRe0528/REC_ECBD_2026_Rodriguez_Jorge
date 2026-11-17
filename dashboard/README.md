# Dashboard en Power BI

Power BI **no carga el modelo estrella completo**: solo se conecta al **Data Mart** (las vistas `vw_DM_...`). En producción el Data Warehouse crece mucho y cargarlo entero haría lento el dashboard; el Data Mart entrega únicamente lo que el tablero necesita.

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

## Segmentaciones (slicers)
| Segmentación | Campo | Uso |
|---|---|---|
| Mes de muestreo | `Nombre_Mes` (dimensión de tiempo) | Ver solo los abulones muestreados en un mes |
| Sexo | `Sexo` | Comparar machos, hembras e infantes |
| Perfil | `Perfil_Morfologico` | Analizar un perfil de K-Means |

## Qué representa cada visual
| Visual | Variable(s) | Qué se ve | Conclusión |
|---|---|---|---|
| Abulones analizados | Recuento de `ID_Abulon` | Total de registros válidos tras el ETL | 4,169 (se descartaron 8 imposibles) |
| Edad promedio | Promedio de `Edad_Anios` | Edad media = Rings + 1.5 | ≈ 11.4 años |
| Error regresión (MAE) | Promedio de `Error_Absoluto` (prueba) | Cuántos anillos se equivoca en promedio el Random Forest | ≈ 1.5 anillos |
| Exactitud clasificación | `Valor` de la métrica Exactitud | % de abulones con grupo de edad correcto (prueba) | ≈ 64% (el azar sería 33%) |
| Perfiles morfológicos | `PC1`, `PC2`, `Perfil_Morfologico` | Los 3 grupos de K-Means proyectados con PCA | Se ordenan por tamaño (PC1 = 92.5% de la información) |
| Edad real vs. predicha | `Rings` vs. `Rings_Predicho` (prueba) | Qué tan cerca está la predicción de la edad real | Buen ajuste en jóvenes; subestima a los muy viejos |
| Abulones por grupo de edad | Recuento por `Grupo_Edad` | Tamaño de las clases de la clasificación | Clases balanceadas (~33% cada una) |
| Medidas promedio por perfil | Promedio de longitud y pesos por perfil | Cómo es físicamente cada perfil | Los grandes pesan ~5 veces más que los pequeños |
| Edad promedio por sexo | Promedio de `Edad_Anios` por `Sexo` | Diferencia de edad entre sexos | Infantes ≈ 9 años; machos y hembras ≈ 12 |
