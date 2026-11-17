@echo off
REM ====================================================================
REM  Ejecuta el ETL automatico del proyecto Abalone (carga FULL)
REM  Programado en el Programador de tareas de Windows: todos los dias 3:00 a.m.
REM  Alumno: Jorge Alberto Rodriguez Enriquez
REM ====================================================================

REM Ir a la carpeta del proyecto (la carpeta padre de src)
cd /d "%~dp0.."

if not exist logs mkdir logs
set PYTHONIOENCODING=utf-8

echo ================================================== >> logs\etl.log
echo  Ejecucion programada: %date% %time% >> logs\etl.log
echo ================================================== >> logs\etl.log

REM Usar el Python del entorno virtual del proyecto
".venv\Scripts\python.exe" src\etl_abalone.py >> logs\etl.log 2>&1

if %errorlevel% neq 0 (
    echo  RESULTADO: ERROR codigo %errorlevel% >> logs\etl.log
) else (
    echo  RESULTADO: OK >> logs\etl.log
)
exit /b %errorlevel%
