import os
import sqlite3
import sys

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "aduana.db")
SCHEMA_PATH = os.path.join(BASE_DIR, "schema_sqlite.sql")
DATA_PATH = os.path.join(BASE_DIR, "data_sqlite.sql")
QUERIES_DIR = os.path.join(BASE_DIR, "sql", "consultas_sqlite")

print("=" * 70)
print("SISTEMA DE INVENTARIO ADUANERO — DESPLIEGUE Y VALIDACION REAL EN SQLITE")
print(f"Ruta de base de datos: {DB_PATH}")
print(f"Version de SQLite: {sqlite3.sqlite_version}")
print("=" * 70)

# 1. Eliminar base de datos previa si existe para asegurar estado limpio
if os.path.exists(DB_PATH):
    os.remove(DB_PATH)
    print("Base de datos previa eliminada para inicio en limpio.")

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

# Habilitar claves foraneas
cursor.execute("PRAGMA foreign_keys = ON;")

# 2. Despliegue de schema_sqlite.sql
print("\n--- 1. EJECUTANDO schema_sqlite.sql ---")
with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
    schema_sql = f.read()

cursor.executescript(schema_sql)
conn.commit()
print("schema_sqlite.sql ejecutado con exito.")

# Verificar tablas creadas
cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;")
tables = [row[0] for row in cursor.fetchall()]
print(f"Tablas detectadas en aduana.db ({len(tables)}/13): {tables}")
assert len(tables) == 13, f"Se esperaban 13 tablas, se encontraron {len(tables)}"

# Verificar indices creados
cursor.execute("SELECT name, tbl_name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%' ORDER BY tbl_name, name;")
indexes = cursor.fetchall()
print(f"Indices creados ({len(indexes)}):")
for idx_name, tbl_name in indexes:
    print(f"  - {idx_name} en tabla {tbl_name}")

# 3. Despliegue de data_sqlite.sql
print("\n--- 2. EJECUTANDO data_sqlite.sql ---")
with open(DATA_PATH, "r", encoding="utf-8") as f:
    data_sql = f.read()

cursor.executescript(data_sql)
conn.commit()
print("data_sqlite.sql ejecutado con exito.")

# 4. Verificacion de conteo de registros por tabla
print("\n--- 3. CONTEO DE REGISTROS POR TABLA ---")
expected_counts = {
    "pais": 10,
    "categoria_arancelaria": 10,
    "operador_comercial": 6,
    "agente_aduanero": 4,
    "funcionario": 6,
    "bodega": 4,
    "contenedor": 8,
    "producto": 8,
    "declaracion_aduanera": 6,
    "detalle_declaracion": 6,
    "inventario": 8,
    "inspeccion_aduanera": 4,
    "movimiento_inventario": 17
}

total_rows = 0
for table, exp_count in expected_counts.items():
    cursor.execute(f"SELECT COUNT(*) FROM {table}")
    cnt = cursor.fetchone()[0]
    total_rows += cnt
    status = "OK" if cnt == exp_count else "ERROR"
    print(f"  - {table:25}: {cnt:2} filas (Esperado: {exp_count:2}) -> {status}")
    assert cnt == exp_count, f"Discrepancia en {table}: {cnt} != {exp_count}"

print(f"Total registros sembrados en SQLite: {total_rows} (Esperado: 97)")
assert total_rows == 97, f"Total incorrecto: {total_rows}"

# 5. Integridad referencial (PRAGMA foreign_key_check)
print("\n--- 4. PRUEBA DE CLAVES FORANEAS (PRAGMA foreign_key_check) ---")
cursor.execute("PRAGMA foreign_key_check;")
fk_violations = cursor.fetchall()
if not fk_violations:
    print("PRAGMA foreign_key_check: 0 violaciones detectadas. Integridad referencial 100% valida.")
else:
    print(f"ERROR: Se detectaron violaciones de foreign key: {fk_violations}")
    sys.exit(1)

# 6. Verificacion de columna generada STORED en inventario
print("\n--- 5. VERIFICACION DE COLUMNA GENERADA STORED (cantidad_total) ---")
cursor.execute("SELECT id_inventario, bodega_id, producto_id, cantidad_disponible, cantidad_retenida, cantidad_total FROM inventario")
inv_rows = cursor.fetchall()
for row in inv_rows:
    id_inv, b_id, p_id, disp, ret, tot = row
    calc = round(disp + ret, 2)
    assert round(tot, 2) == calc, f"Fallo en columna generada: {tot} != {calc}"
    print(f"  - Inv #{id_inv} (Bodega {b_id}, Prod {p_id}): Disp={disp:.2f}, Ret={ret:.2f} => Total={tot:.2f} (Calc={calc:.2f}) OK")

# 7. Ejecucion real de las 6 consultas analiticas
print("\n--- 6. EJECUCION REAL DE LAS 6 CONSULTAS ANALITICAS ---")
queries = [
    ("Q1", "Q1_mercancia_retenida_china.sql"),
    ("Q2", "Q2_importaciones_octubre_2026.sql"),
    ("Q3", "Q3_pais_con_mas_contenedores.sql"),
    ("Q4", "Q4_importador_mayor_valor_cif.sql"),
    ("Q5", "Q5_inspecciones_con_observaciones.sql"),
    ("Q6", "Q6_stock_disponible_laptops.sql"),
]

for q_id, q_file in queries:
    file_path = os.path.join(QUERIES_DIR, q_file)
    print(f"\n==================== {q_id}: {q_file} ====================")
    with open(file_path, "r", encoding="utf-8") as f:
        sql_content = f.read()
    
    cursor.execute(sql_content)
    rows = cursor.fetchall()
    cols = [desc[0] for desc in cursor.description]
    print(f"Columnas: {cols}")
    print(f"Filas retornadas: {len(rows)}")
    for r in rows:
        print(f"  {r}")

# 8. Investigacion detallada de la discrepancia de Q3 (Contenedores)
print("\n--- 7. INVESTIGACION DETALLADA DE LA DISCREPANCIA EN Q3 ---")
cursor.execute("""
SELECT 
    c.id_contenedor,
    c.numero_contenedor,
    c.estado,
    p.nombre AS pais_origen,
    da.numero_declaracion
FROM contenedor c
INNER JOIN pais p ON c.pais_origen_id = p.id_pais
LEFT JOIN declaracion_aduanera da ON da.contenedor_id = c.id_contenedor
ORDER BY p.nombre, c.id_contenedor;
""")
cont_detail = cursor.fetchall()
print("Detalle de todos los contenedores y su vinculo con declaraciones aduaneras:")
for cd in cont_detail:
    c_id, c_num, c_est, c_pais, c_dua = cd
    dua_str = c_dua if c_dua else "[SIN DUA / EN PUERTO]"
    print(f"  - Contenedor #{c_id} ({c_num}): Origen={c_pais}, Estado={c_est}, DUA={dua_str}")

cursor.execute("""
SELECT 
    p.nombre AS pais,
    COUNT(c.id_contenedor) AS total_en_puerto,
    SUM(CASE WHEN da.id_declaracion IS NOT NULL THEN 1 ELSE 0 END) AS vinculados_a_dua,
    SUM(CASE WHEN da.id_declaracion IS NULL THEN 1 ELSE 0 END) AS sin_dua_en_puerto
FROM contenedor c
INNER JOIN pais p ON c.pais_origen_id = p.id_pais
LEFT JOIN declaracion_aduanera da ON da.contenedor_id = c.id_contenedor
WHERE c.estado = 'RECIBIDO_EN_PUERTO'
GROUP BY p.id_pais, p.nombre
ORDER BY total_en_puerto DESC;
""")
q3_analysis = cursor.fetchall()
print("\nResumen comparativo de contenedores recibidos en puerto:")
print("  Pais | Total RECIBIDO_EN_PUERTO | Con DUA asociado | Sin DUA (Recien descargado)")
for row in q3_analysis:
    print(f"  {row[0]:12} | {row[1]:24} | {row[2]:16} | {row[3]:27}")

# 9. Prueba de integridad de restricciones CHECK (Saldos negativos y traslados invalidos)
print("\n--- 8. PRUEBAS ACTIVAS DE RESTRICCIONES CHECK Y REGLAS DE NEGOCIO ---")

# Test CHECK 1: Intentar saldo negativo en inventario
try:
    cursor.execute("INSERT INTO inventario (bodega_id, producto_id, cantidad_disponible, cantidad_retenida) VALUES (1, 8, -50.00, 0.00)")
    print("ERROR: Se permitio cantidad_disponible negativa en inventario.")
    sys.exit(1)
except sqlite3.IntegrityError as e:
    print(f"CHECK chk_inventario_cant_disp verificado: {e}")

# Test CHECK 2: Intentar traslado con misma bodega origen y destino
try:
    cursor.execute("""
    INSERT INTO movimiento_inventario (tipo_movimiento, producto_id, bodega_origen_id, bodega_destino_id, cantidad, funcionario_id, motivo)
    VALUES ('TRASLADO_ENTRE_BODEGAS', 1, 1, 1, 10.00, 5, 'Traslado invalido misma bodega')
    """)
    print("ERROR: Se permitio traslado entre la misma bodega.")
    sys.exit(1)
except sqlite3.IntegrityError as e:
    print(f"CHECK chk_movimiento_traslado verificado: {e}")

# Test CHECK 3: Intentar operacion interna (BLOQUEO_RETENCION) con bodega_destino informada (violando Opcion A)
try:
    cursor.execute("""
    INSERT INTO movimiento_inventario (tipo_movimiento, producto_id, bodega_origen_id, bodega_destino_id, cantidad, funcionario_id, motivo)
    VALUES ('BLOQUEO_RETENCION', 1, 1, 2, 10.00, 5, 'Bloqueo con destino invalido')
    """)
    print("ERROR: Se permitio BLOQUEO_RETENCION con bodega_destino_id no nula.")
    sys.exit(1)
except sqlite3.IntegrityError as e:
    print(f"CHECK chk_movimiento_operacion_interna verificado: {e}")

# Test FOREIGN KEY: Intentar insertar movimiento con producto inexistente
try:
    cursor.execute("""
    INSERT INTO movimiento_inventario (tipo_movimiento, producto_id, bodega_origen_id, bodega_destino_id, cantidad, funcionario_id, motivo)
    VALUES ('SALIDA_DESPACHO', 9999, 1, NULL, 5.00, 5, 'Producto inexistente')
    """)
    print("ERROR: Se permitio clave foranea inexistente.")
    sys.exit(1)
except sqlite3.IntegrityError as e:
    print(f"FOREIGN KEY fk_movimiento_producto verificado: {e}")

conn.close()
print("\n" + "=" * 70)
print("TODAS LAS PRUEBAS REALES EN SQLITE SE COMPLETARON SATISFACTORIAMENTE.")
print(f"Archivo persistido: {DB_PATH} ({os.path.getsize(DB_PATH)} bytes)")
print("=" * 70)
