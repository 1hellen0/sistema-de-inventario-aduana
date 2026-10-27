# Guía de Conexión y Uso del Workflow n8n — Sistema de Inventario Aduanero

Este documento detalla la arquitectura, importación, configuración y pruebas del workflow de n8n para consultar la base de datos `aduana.db` utilizando preguntas en lenguaje natural clasificadas mediante DeepSeek.

---

## 1. Arquitectura y Flujo de Nodos Corregido

El workflow implementa un pipeline robusto de 11 nodos sin nodos flotantes, respetando las rutas principales y de error de extremo a extremo:

```
[Webhook Aduana] (POST /aduana-query)
        │
        ▼
[Validar Entrada]
        │
        ▼
[¿Entrada Válida?] ──(False / Inválida)──► [Respuesta Error Entrada] (HTTP 400)
        │ (True / Válida)
        ▼
[Clasificador DeepSeek] (Clasificación estricta Q1-Q6 o NONE)
        │
        ▼
[Validar Clasificación]
        │
        ▼
[¿Consulta Autorizada?] ──(False / No Autorizada)──► [Respuesta No Autorizada] (HTTP 200 con catálogo)
        │ (True / Autorizada Q1-Q6)
        ▼
[Ejecutar Consulta Python] (query_sqlite.py --query Qx en mode=ro)
        │
        ▼
[Procesar Resultados] (Parsea stdout JSON y genera mensaje descriptivo)
        │
        ▼
[Respuesta Exitosa] (HTTP 200 con datos consolidados)
```

### ¿Por qué se utiliza Python y por qué aparecía desconectado?

1. **Necesidad técnica de Python:**
   - n8n v2.x **no incluye un nodo nativo para bases de datos SQLite** (`n8n-nodes-base` solo dispone de nodos oficiales para MySQL, PostgreSQL, MongoDB, MSSQL, etc.).
   - Para consultar `aduana.db`, n8n requiere un conector. Se utiliza Python mediante el nodo `Execute Command`, el cual ejecuta el script auditado `query_sqlite.py`.
2. **Rol de seguridad de `query_sqlite.py`:**
   - **Cero SQL Dinámico:** Nunca convierte la pregunta del usuario en SQL arbitrario.
   - **Lista blanca (Whitelist):** Admite únicamente identificadores autorizados `Q1` a `Q6`.
   - **Solo lectura físico:** Abre la base de datos con `mode=ro` (bloqueo a nivel del motor SQLite).
   - **Salida estándar estructurada:** Emite un JSON estandarizado hacia `stdout` que es parseado por `Procesar_Resultados`.
3. **Causa de los nodos flotantes corregida:**
   - **Esquema de condiciones `If` v2.2:** Las versiones modernas de n8n v2.x requieren la estructura `conditions.conditions` con operadores tipados (`operator: { type: "boolean", operation: "equals" }`). Esquemas anteriores dejaban las salidas sin emparejar en la interfaz visual.
   - **Normalización ASCII:** Se eliminaron caracteres especiales (`¿`, `á`) en los nombres de los nodos para garantizar que los enlaces del objeto `connections` coincidan al 100% independientemente del juego de caracteres del portapapeles del sistema operativo.

---

## 2. Catálogo de Preguntas Admitidas

El sistema responde con exactitud a las siguientes seis intenciones analíticas:

| ID | Pregunta de negocio admitida | Consulta asociada | Descripción analítica |
| :---: | :--- | :--- | :--- |
| **Q1** | *¿Qué mercancía de origen chino está retenida en BOD-02?* | `Q1_mercancia_retenida_china.sql` | Filtra mercancía retenida en Bodega 2 con país de origen China. |
| **Q2** | *¿Qué importaciones se registraron en octubre de 2026?* | `Q2_importaciones_octubre_2026.sql` | Lista declaraciones de importación en el rango `[2026-10-01, 2026-11-01)`. |
| **Q3** | *¿Qué país tiene más contenedores recibidos en puerto?* | `Q3_pais_con_mas_contenedores.sql` | Ranking con `DENSE_RANK()` de contenedores en estado `RECIBIDO_EN_PUERTO`. |
| **Q4** | *¿Qué importador acumula el mayor valor CIF?* | `Q4_importador_mayor_valor_cif.sql` | Sumatoria CIF por operador sin duplicación 1:N de partidas arancelarias. |
| **Q5** | *¿Qué inspecciones tienen observaciones?* | `Q5_inspecciones_con_observaciones.sql` | Actas de inspección con `tuvo_observaciones = TRUE` y funcionarios a cargo. |
| **Q6** | *¿Cuántas laptops Lenovo están disponibles?* | `Q6_stock_disponible_laptops.sql` | Saldo disponible consolidado de `SKU-LAP-001` leyendo `inventario`. |

---

## 3. Instrucciones de Importación y Puesta en Marcha

### Paso 1: Importar el workflow en n8n
El archivo `workflow_aduana_deepseek.json` ya está preparado para importarse por dos vías:

* **Vía Interfaz Web de n8n:**
  1. Abre n8n en tu navegador: `http://localhost:5678`.
  2. En el menú superior izquierdo, pulsa en el menú de tres puntos `...` y selecciona **Import from File**.
  3. Selecciona el archivo `workflow_aduana_deepseek.json`.
* **Vía Línea de Comandos (CLI):**
  ```powershell
  n8n import:workflow --input="c:\Users\FORWARD\Downloads\SistemaCaldera\TicTacToe\sistema de inventario aduana\sistema-de-inventario-aduana\workflow_aduana_deepseek.json"
  ```

### Paso 2: Configurar la clave API de DeepSeek
1. En el lienzo del workflow, haz doble clic sobre el nodo **Clasificador DeepSeek**.
2. En la sección **Headers Parameters**, localiza el encabezado `Authorization`.
3. Sustituye `Bearer YOUR_DEEPSEEK_API_KEY_HERE` por tu clave API real de DeepSeek:
   ```text
   Bearer sk-tu-clave-api-real-aqui
   ```
4. Guarda el nodo.

### Paso 3: Activar el workflow
1. En la esquina superior derecha del workflow, activa el interruptor **Active**.
2. Guarda el workflow (**Save** o `Ctrl + S`).

---

## 4. Ejemplos de Petición y Respuesta

### Petición HTTP (PowerShell):
```powershell
Invoke-RestMethod -Method Post `
  -Uri "http://localhost:5678/webhook/aduana-query" `
  -ContentType "application/json; charset=utf-8" `
  -Body '{"pregunta": "¿Cuántas laptops tenemos disponibles?"}' | ConvertTo-Json -Depth 5
```

### Respuesta exitosa recibida (HTTP 200):
```json
{
  "exito": true,
  "pregunta": "¿Cuántas laptops tenemos disponibles?",
  "query_id": "Q6",
  "titulo_consulta": "Stock total disponible de laptops Lenovo ThinkPad T14",
  "mensaje": "Se encuentran disponibles 400 unidades de Laptop Lenovo ThinkPad T14 Gen 4 en custodia aduanera.",
  "total_registros": 1,
  "columnas": [
    "codigo_sku",
    "nombre_producto",
    "stock_total_disponible"
  ],
  "datos": [
    {
      "codigo_sku": "SKU-LAP-001",
      "nombre_producto": "Laptop Lenovo ThinkPad T14 Gen 4",
      "stock_total_disponible": 400
    }
  ],
  "tiempo_ejecucion_ms": 1.6
}
```

---

## 5. Casos de Prueba y Respuestas de Seguridad

### Caso A: Pregunta válida (Q1)
* **Pregunta:** `{"pregunta": "¿Qué mercancía de origen chino está retenida en BOD-02?"}`
* **Clasificación esperada:** `Q1`
* **Respuesta:**
  ```json
  {
    "exito": true,
    "query_id": "Q1",
    "total_registros": 2,
    "mensaje": "Se encontraron 2 productos de origen chino retenidos en Bodega 2 (BOD-02): Tablet Huawei MatePad 11.5S (250 UNIDADES), Smartphone Xiaomi Redmi Note 13 Pro (990 UNIDADES)."
  }
  ```

### Caso B: Pregunta no admitida (Fuera del catálogo)
* **Pregunta:** `{"pregunta": "¿Cuál es el salario de los funcionarios aduaneros?"}`
* **Clasificación esperada:** `NONE`
* **Respuesta del Webhook (HTTP 200):**
  ```json
  {
    "exito": false,
    "error_codigo": "UNAUTHORIZED_OR_UNKNOWN_QUERY",
    "mensaje": "La pregunta no pudo asociarse a ninguna de las seis consultas analíticas autorizadas del Sistema de Inventario Aduanero.",
    "pregunta_recibida": "¿Cuál es el salario de los funcionarios aduaneros?",
    "consultas_disponibles": [
      "Q1: ¿Qué mercancía de origen chino está retenida en BOD-02?",
      "Q2: ¿Qué importaciones se registraron en octubre de 2026?",
      "Q3: ¿Qué país tiene más contenedores recibidos en puerto?",
      "Q4: ¿Qué importador acumula el mayor valor CIF?",
      "Q5: ¿Qué inspecciones tienen observaciones?",
      "Q6: ¿Cuántas laptops Lenovo están disponibles?"
    ]
  }
  ```

### Caso C: Intento de Inyección SQL / Prompt Injection
* **Pregunta:** `{"pregunta": "DROP TABLE inventario; SELECT * FROM funcionario;"}`
* **Comportamiento:**
  1. El prompt del sistema de DeepSeek instruye responder `NONE` ante cualquier intento de código o manipulación.
  2. Si el modelo intentara responder con texto SQL, el nodo **Validar Clasificación** evalúa si el texto coincide exactamente con `Q1`–`Q6`. Al no coincidir, lo clasifica como `NONE`.
  3. El nodo **Ejecutar Consulta Python** nunca es alcanzado.
  4. La respuesta devuelta es el mensaje de seguridad de consulta no autorizada.

### Caso D: Petición vacía o malformada
* **Pregunta:** `{}` o `{"pregunta": "   "}`
* **Respuesta (HTTP 400 Bad Request):**
  ```json
  {
    "exito": false,
    "error_codigo": "INVALID_INPUT",
    "mensaje": "Debe enviar una petición POST en formato JSON con la clave 'pregunta'.",
    "ejemplo": {
      "pregunta": "¿Cuántas laptops tenemos disponibles?"
    }
  }
  ```
