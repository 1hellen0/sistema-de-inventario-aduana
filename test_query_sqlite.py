import subprocess
import json
import os
import sys

BASE_DIR = r"c:\Users\FORWARD\Downloads\SistemaCaldera\TicTacToe\sistema de inventario aduana\sistema-de-inventario-aduana"
SCRIPT_PATH = os.path.join(BASE_DIR, "query_sqlite.py")

print("=" * 70)
print("PRUEBAS EXHAUSTIVAS DE query_sqlite.py")
print("=" * 70)

def run_query_cli(args, cwd=BASE_DIR):
    cmd = [sys.executable, SCRIPT_PATH] + args
    res = subprocess.run(cmd, cwd=cwd, capture_output=True, text=encoding_safe())
    try:
        data = json.loads(res.stdout)
    except Exception as e:
        data = {"raw_stdout": res.stdout, "raw_stderr": res.stderr, "parse_error": str(e)}
    return res.returncode, data

def encoding_safe():
    return "utf-8"

# 1. Probar cada una de las 6 consultas autorizadas
expected = {
    "Q1": 2, # 2 productos retenidos de China en BOD-02
    "Q2": 4, # 4 DUAs de importacion en oct 2026
    "Q3": 1, # 1 pais lider (China con 4)
    "Q4": 1, # 1 importador lider (TechGlobal con 771000)
    "Q5": 2, # 2 inspecciones con observaciones
    "Q6": 1  # 1 fila con 400 laptops
}

for q_id, exp_rows in expected.items():
    code, out = run_query_cli([q_id])
    assert code == 0, f"Error al ejecutar {q_id}: code {code}, {out}"
    assert out.get("status") == "success", f"Status no exitoso en {q_id}: {out}"
    row_count = out.get("row_count")
    assert row_count == exp_rows, f"Filas inesperadas en {q_id}: {row_count} != {exp_rows}"
    print(f"[OK] {q_id:2}: Retorno {row_count} filas en {out.get('execution_time_ms')} ms")

# 2. Probar entrada por argumento JSON (--json-input)
code, out = run_query_cli(["--json-input", '{"query": "Q6"}'])
assert code == 0 and out.get("status") == "success"
laptop_stock = out["data"][0]["stock_total_disponible"]
print(f"[OK] --json-input '{{\"query\": \"Q6\"}}': Stock laptops = {laptop_stock}")
assert laptop_stock == 400.0 or laptop_stock == 400

# 3. Probar rechazo de consulta no autorizada (SQL Injection / Arbitrario)
code, out = run_query_cli(["SELECT * FROM usuario"])
assert code == 1 and out.get("status") == "error"
assert out.get("error_code") == "UNAUTHORIZED_QUERY"
print(f"[OK] Rechazo de SQL arbitrario: {out.get('error_code')} - {out.get('message')[:60]}...")

code, out = run_query_cli(["Q99"])
assert code == 1 and out.get("status") == "error"
print(f"[OK] Rechazo de ID inexistente Q99: {out.get('error_code')}")

# 4. Probar ejecución desde OTRA carpeta (p. ej. C:\) para validar independencia de CWD
cwd_test = r"C:\Users\FORWARD"
code, out = run_query_cli(["Q1"], cwd=cwd_test)
assert code == 0 and out.get("status") == "success"
print(f"[OK] Ejecucion desde directorio externo '{cwd_test}': Exito garantizado sin bases vacias.")

# 5. Probar que base inexistente falle limpiamente
code, out = run_query_cli(["Q1", "--db", "inexistente.db"])
assert code == 1 and out.get("status") == "error"
print(f"[OK] Base inexistente rechazada limpiamente: {out.get('message')}")

print("\n" + "=" * 70)
print("TODAS LAS PRUEBAS DE query_sqlite.py PASARON SATISFACTORIAMENTE (100% OK)")
print("=" * 70)
