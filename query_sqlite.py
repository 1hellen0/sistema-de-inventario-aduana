#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=====================================================================
SISTEMA DE INVENTARIO ADUANERO — CONECTOR SQLITE DE SOLO LECTURA
Script: query_sqlite.py
Propósito: Conectar n8n y herramientas externas a aduana.db de forma segura
           utilizando el módulo estándar sqlite3 en modo de solo lectura.
=====================================================================
"""

import sys
import os
import json
import time
import sqlite3
import argparse

# 1. Resolución robusta de rutas absolutas
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "aduana.db")
QUERIES_DIR = os.path.join(BASE_DIR, "sql", "consultas_sqlite")

# 2. Catálogo estricto de consultas autorizadas (Whitelist de seguridad)
# Prohíbe terminantemente la ejecución de SQL arbitrario generado por IA.
AUTHORIZED_QUERIES = {
    "Q1": {
        "file": "Q1_mercancia_retenida_china.sql",
        "title": "Mercancía retenida originaria de China en Bodega 2 (BOD-02)",
        "description": "Filtra existencias retenidas con origen China en Bodega de Decomisos 2."
    },
    "Q2": {
        "file": "Q2_importaciones_octubre_2026.sql",
        "title": "Declaraciones de importación registradas en octubre de 2026",
        "description": "Lista DUAs de importación en el rango temporal exacto de octubre 2026."
    },
    "Q3": {
        "file": "Q3_pais_con_mas_contenedores.sql",
        "title": "País con más unidades intermodales recibidas en puerto",
        "description": "Ranking de países por contenedores en puerto con resolución de empates mediante DENSE_RANK."
    },
    "Q4": {
        "file": "Q4_importador_mayor_valor_cif.sql",
        "title": "Importador con mayor valor CIF acumulado en importaciones",
        "description": "Sumatoria de valor CIF por operador comercial excluyendo exportaciones sin duplicación 1:N."
    },
    "Q5": {
        "file": "Q5_inspecciones_con_observaciones.sql",
        "title": "Inspecciones aduaneras con observaciones registradas",
        "description": "Actas de inspección con incidencias, funcionarios responsables y medidas cautelares."
    },
    "Q6": {
        "file": "Q6_stock_disponible_laptops.sql",
        "title": "Stock total disponible de laptops Lenovo ThinkPad T14",
        "description": "Saldo disponible de SKU-LAP-001 consultando exclusivamente la tabla inventario."
    }
}

def normalize_query_id(raw_id: str) -> str:
    """Normaliza identificadores tipo 'q1', 'Q1', 'Q1_mercancia_retenida_china'."""
    clean = raw_id.strip().upper()
    if clean in AUTHORIZED_QUERIES:
        return clean
    # Buscar coincidencia por prefijo (ej. Q1_...)
    for key, info in AUTHORIZED_QUERIES.items():
        if clean == key or clean.startswith(key + "_") or clean == info["file"].upper():
            return key
    return clean

def open_database_readonly(db_path: str) -> sqlite3.Connection:
    """
    Abre la base de datos en modo estrictamente de solo lectura (mode=ro).
    Verifica previamente que el archivo exista para evitar la creación accidental
    de bases de datos vacías en rutas incorrectas.
    """
    if not os.path.exists(db_path):
        raise FileNotFoundError(
            f"La base de datos requerida no existe en la ruta esperada: '{db_path}'"
        )
    
    if os.path.getsize(db_path) == 0:
        raise ValueError(
            f"El archivo de base de datos '{db_path}' tiene tamaño 0 bytes (vacío o corrupto)."
        )

    # Convertir a URI SQLite de solo lectura
    # Sintaxis: file:C:/ruta/aduana.db?mode=ro
    formatted_path = os.path.abspath(db_path).replace(os.sep, "/")
    uri = f"file:{formatted_path}?mode=ro"
    
    conn = sqlite3.connect(uri, uri=True, timeout=10.0)
    
    # Habilitar claves foráneas en la sesión
    conn.execute("PRAGMA foreign_keys = ON;")
    
    # Verificación de integridad básica: comprobar que las 13 tablas existan
    cursor = conn.cursor()
    cursor.execute("SELECT count(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
    table_count = cursor.fetchone()[0]
    if table_count < 13:
        conn.close()
        raise ValueError(
            f"La base de datos abierta contiene únicamente {table_count} tablas (se esperaban 13). "
            "Es posible que se esté apuntando a una base incompleta o vacía."
        )
        
    return conn

def execute_authorized_query(query_id: str, db_path: str = DB_PATH) -> dict:
    """
    Ejecuta una consulta autorizada de la lista blanca y retorna un diccionario estructurado.
    """
    start_time = time.perf_counter()
    normalized_id = normalize_query_id(query_id)
    
    if normalized_id not in AUTHORIZED_QUERIES:
        return {
            "status": "error",
            "error_code": "UNAUTHORIZED_QUERY",
            "message": f"La consulta solicitada '{query_id}' no está autorizada en la lista blanca de seguridad.",
            "authorized_queries": list(AUTHORIZED_QUERIES.keys()),
            "catalog": {k: v["title"] for k, v in AUTHORIZED_QUERIES.items()}
        }
    
    query_info = AUTHORIZED_QUERIES[normalized_id]
    sql_file_path = os.path.join(QUERIES_DIR, query_info["file"])
    
    if not os.path.exists(sql_file_path):
        return {
            "status": "error",
            "error_code": "FILE_NOT_FOUND",
            "message": f"No se encontró el archivo SQL asociado: '{sql_file_path}'"
        }
    
    try:
        with open(sql_file_path, "r", encoding="utf-8") as f:
            sql_text = f.read().strip()
    except Exception as e:
        return {
            "status": "error",
            "error_code": "FILE_READ_ERROR",
            "message": f"Error al leer el archivo de consulta: {str(e)}"
        }
    
    conn = None
    try:
        conn = open_database_readonly(db_path)
        cursor = conn.cursor()
        
        cursor.execute(sql_text)
        raw_rows = cursor.fetchall()
        
        columns = [desc[0] for desc in cursor.description] if cursor.description else []
        
        # Mapear cada fila como diccionario con nombres de columnas
        data = [dict(zip(columns, row)) for row in raw_rows]
        
        duration_ms = round((time.perf_counter() - start_time) * 1000, 2)
        
        return {
            "status": "success",
            "query_id": normalized_id,
            "query_title": query_info["title"],
            "description": query_info["description"],
            "sql_file": os.path.relpath(sql_file_path, BASE_DIR).replace(os.sep, "/"),
            "read_only": True,
            "row_count": len(data),
            "columns": columns,
            "data": data,
            "execution_time_ms": duration_ms
        }
        
    except sqlite3.OperationalError as e:
        return {
            "status": "error",
            "error_code": "SQLITE_OPERATIONAL_ERROR",
            "message": f"Error operacional en SQLite: {str(e)}"
        }
    except Exception as e:
        return {
            "status": "error",
            "error_code": "DATABASE_ERROR",
            "message": f"Error al procesar la base de datos: {str(e)}"
        }
    finally:
        if conn:
            conn.close()

def main():
    parser = argparse.ArgumentParser(
        description="Conector de solo lectura para el Sistema de Inventario Aduanero en SQLite.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos de uso:
  python query_sqlite.py Q1
  python query_sqlite.py --query Q6
  python query_sqlite.py --json-input '{"query": "Q3"}'
  python query_sqlite.py --list
        """
    )
    
    parser.add_argument("query_pos", nargs="?", default=None, help="Identificador de la consulta (Q1 a Q6)")
    parser.add_argument("-q", "--query", dest="query_flag", help="Identificador de la consulta (Q1 a Q6)")
    parser.add_argument("--json-input", help="Parámetro en formato JSON (útil para integración directa con n8n)")
    parser.add_argument("--list", action="store_true", help="Listar las consultas autorizadas en JSON")
    parser.add_argument("--db", default=DB_PATH, help="Ruta alternativa a la base de datos (por defecto aduana.db)")
    
    args = parser.parse_args()
    
    if args.list:
        print(json.dumps({
            "status": "success",
            "available_queries": AUTHORIZED_QUERIES
        }, indent=2, ensure_ascii=False))
        sys.exit(0)
        
    target_query = None
    
    # 1. Si viene por --json-input
    if args.json_input:
        try:
            payload = json.loads(args.json_input)
            target_query = payload.get("query") or payload.get("query_id")
        except json.JSONDecodeError as e:
            print(json.dumps({
                "status": "error",
                "error_code": "INVALID_JSON_INPUT",
                "message": f"Error al decodificar el argumento --json-input: {str(e)}"
            }, indent=2, ensure_ascii=False))
            sys.exit(1)
            
    # 2. Si viene por flag o posicional
    if not target_query:
        target_query = args.query_flag or args.query_pos
        
    # 3. Si no se especificó nada, intentar leer stdin (si hay tubería)
    if not target_query and not sys.stdin.isatty():
        try:
            stdin_content = sys.stdin.read().strip()
            if stdin_content:
                payload = json.loads(stdin_content)
                target_query = payload.get("query") or payload.get("query_id")
        except Exception:
            pass
            
    if not target_query:
        print(json.dumps({
            "status": "error",
            "error_code": "MISSING_QUERY_PARAMETER",
            "message": "Debe especificar una consulta autorizada (Q1 a Q6). Use --list para ver el catálogo.",
            "authorized_queries": list(AUTHORIZED_QUERIES.keys())
        }, indent=2, ensure_ascii=False))
        sys.exit(1)
        
    result = execute_authorized_query(target_query, db_path=args.db)
    
    print(json.dumps(result, indent=2, ensure_ascii=False))
    
    # Salir con código 0 si fue exitoso, 1 si hubo error
    if result.get("status") == "success":
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
