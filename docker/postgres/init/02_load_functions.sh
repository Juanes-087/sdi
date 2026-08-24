#!/bin/bash
set -e

# ==============================================================================
# SCRIPT DE CONSOLIDACIÓN Y EJECUCIÓN AUTOMÁTICA DE FUNCIONES SQL
# Este script se ejecuta automáticamente dentro de /docker-entrypoint-initdb.d/
# al iniciar el contenedor de PostgreSQL por primera vez.
# ==============================================================================

echo ">> Inicializando funciones, triggers y procedimientos almacenados de Specialized..."

export PGPASSWORD="$POSTGRES_PASSWORD"

SQL_BASE_DIR="/docker-entrypoint-initdb.d/functions_source"

if [ -d "$SQL_BASE_DIR" ]; then
    # 1. Triggers de Audit Trail
    if [ -d "$SQL_BASE_DIR/fun_audit_trail" ]; then
        for f in "$SQL_BASE_DIR/fun_audit_trail"/*.sql; do
            [ -f "$f" ] && echo "Ejecutando $f..." && psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$f"
        done
    fi

    # 2. Funciones de Inserción
    if [ -d "$SQL_BASE_DIR/Fun_insert" ]; then
        for f in "$SQL_BASE_DIR/Fun_insert"/*.sql; do
            [ -f "$f" ] && echo "Ejecutando $f..." && psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$f"
        done
    fi

    # 3. Funciones de Actualización
    if [ -d "$SQL_BASE_DIR/fun_update" ]; then
        for f in "$SQL_BASE_DIR/fun_update"/*.sql; do
            [ -f "$f" ] && echo "Ejecutando $f..." && psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$f"
        done
    fi

    # 4. Funciones de Eliminación (Soft delete)
    if [ -d "$SQL_BASE_DIR/fun_delete" ]; then
        for f in "$SQL_BASE_DIR/fun_delete"/*.sql; do
            [ -f "$f" ] && echo "Ejecutando $f..." && psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$f"
        done
    fi

    # 5. Funciones Transaccionales y Kardex
    if [ -d "$SQL_BASE_DIR/fun_transaccionales" ]; then
        for f in "$SQL_BASE_DIR/fun_transaccionales"/*.sql; do
            [ -f "$f" ] && echo "Ejecutando $f..." && psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$f"
        done
    fi

    # 6. Funciones de Consultas y Estadísticas
    if [ -d "$SQL_BASE_DIR/Consultas" ]; then
        for f in "$SQL_BASE_DIR/Consultas"/*.sql; do
            [ -f "$f" ] && echo "Ejecutando $f..." && psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$f"
        done
    fi
fi

echo ">> Todas las funciones y triggers fueron instalados correctamente."
