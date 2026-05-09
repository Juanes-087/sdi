@echo off
setlocal enabledelayedexpansion

:: ====================================================================
:: SCRIPT DE EJECUCION MASIVA DE FUNCIONES SQL
:: ====================================================================
:: Proposito: Recorre las carpetas del BACK y ejecuta todos los archivos 
:: .sql, excluyendo la carpeta de validaciones.
:: ====================================================================

:: Configuracion de Base de Datos
set DB_HOST=localhost
set DB_PORT=5433
set DB_NAME=specialized
set DB_USER=postgres
set PGPASSWORD=PgSena2024

echo [*] Iniciando ejecucion de funciones SQL...
echo [*] Host: %DB_HOST%:%DB_PORT%
echo [*] Base de Datos: %DB_NAME%
echo.

:: Carpeta base (donde esta el .bat)
set BASE_DIR=%~dp0

:: Recorrer subcarpetas
for /d %%D in ("%BASE_DIR%*") do (
    set "folderName=%%~nxD"
    
    :: Excluir carpeta de validaciones
    if /i "!folderName!"=="fun_validaciones" (
        echo [SKIP] Omitiendo carpeta de validaciones: !folderName!
    ) else (
        echo [INFO] Procesando carpeta: !folderName!
        
        :: Buscar archivos .sql en la subcarpeta
        for %%F in ("%%D\*.sql") do (
            echo   [-] Ejecutando: %%~nxF
            psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f "%%F" > nul 2>&1
            if !errorlevel! equ 0 (
                echo     [OK] Exito.
            ) else (
                echo     [ERROR] Fallo al ejecutar %%~nxF. Revise el archivo.
            )
        )
    )
)

echo.
echo [*] Proceso finalizado.
pause
