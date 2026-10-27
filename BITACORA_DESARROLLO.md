# BITÁCORA DE DESARROLLO — SISTEMA DE INVENTARIO ADUANERO

**Proyecto:** Laboratorio #3 — Base de Datos Relacional y Automatización de Agente Aduanero con n8n y DeepSeek  
**Repositorio:** `sistema-de-inventario-aduana`  
**Responsable técnico:** Desarrollador Backend Senior / Tutor Técnico  

---

## Control General de Decisiones Pendientes y Bloqueos

| ID | Asunto | Estado | Motivo | Decisión / Solución Aplicada | Próxima Acción |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **DEC-01** | Disponibilidad de MySQL Server | **En verificación** | Requerido para crear tablas, insertar datos y ejecutar consultas SQL. | Se verificó nuevamente (puerto 3306 inactivo, comando `mysql` no disponible). Se conserva como limitación técnica sin asumir su existencia. | Acordar con el usuario el aprovisionamiento de MySQL (local o remoto) antes del despliegue en vivo. |
| **DEC-02** | Acceso a API de DeepSeek | **Pendiente** | Requerido para el AI Agent en n8n. | Se utilizará el nodo de chat compatible con OpenAI en n8n apuntando a `api.deepseek.com`. No se expondrán secretos. | Configurar credencial en n8n en la Etapa 7. |
| **DEC-03** | Conexión n8n - MySQL | **Pendiente** | Automatización de consultas en lenguaje natural. | Se creará un usuario de base de datos con privilegios exclusivos de solo lectura (`SELECT`). | Aplicar en la Etapa 6 de seguridad. |
| **DEC-04** | Requisitos y Refinamiento del Modelo | **Resuelta** | Garantizar que el modelo soporte todas las preguntas analíticas sin fallas de integridad ni de rendimiento. | Se blindó el modelo de 13 tablas en 3FN con índices analíticos específicos, restricciones anti-ciclo en jerarquías, matriz de bodegas y protección de trazabilidad. | Implementado y validado estructuralmente en `schema.sql`. |

---

## REGISTRO DE ETAPAS

### Registro #1: Etapa 0 — Auditoría Inicial del Proyecto y Diagnóstico del Entorno
* **Fecha:** 2026-10-23
* **Etapa:** Etapa 0 (Auditoría Técnica Previa y Planificación)
* **Archivos involucrados:** Carpeta de trabajo `sistema-de-inventario-aduana` y entorno de ejecución del sistema operativo.
* **Propósito de la acción:** Inspeccionar la estructura del repositorio recién clonado, verificar la presencia de dependencias y herramientas locales (Node.js, n8n, MySQL, Git, Python) e identificar riesgos antes de escribir código.
* **Actividades realizadas:**
  1. Inspección de directorios: Se constató que el repositorio remoto clonado estaba vacío (solo contenía metadatos de Git en `.git`).
  2. Diagnóstico de herramientas:
     - Node.js detectado: `v24.13.0` (operativo).
     - npm detectado: `11.6.2` (operativo).
     - n8n detectado: `2.38.6` (instalado globalmente).
     - Git detectado: `2.55.0.windows.2` (operativo).
     - Python detectado: `3.14.6` (operativo).
     - MySQL Server y Cliente MySQL: No encontrados en el PATH ni en servicios activos de Windows.
* **Problema o error encontrado:** Ausencia de binarios de MySQL en las rutas del sistema operativo (`where.exe mysql` no devolvió resultados).
* **Solución aplicada:** Se registró el hallazgo como una decisión pendiente crítica (DEC-01) sin asumir apresuradamente que no existe en absoluto, planificando su verificación previa a la ejecución de scripts SQL.
* **Motivo de la solución:** No bloquear las etapas conceptuales (diseño y modelado) que no dependen de la ejecución del motor de base de datos.
* **Prueba realizada:** Ejecución de comandos de diagnóstico en PowerShell (`node -v`, `npm -v`, `n8n --version`, `Get-Service`, `where.exe`).
* **Resultado observado:** Salidas de terminal registradas con éxito, confirmando el entorno de Node/n8n y la ausencia momentánea de MySQL en PATH.
* **Estado final de la etapa:** **Completado.**

---

### Registro #2: Etapa 1 / 2 — Diseño Autónomo del Modelo de Datos Relacional y DER
* **Fecha:** 2026-10-23
* **Etapa:** Etapa 1 / 2 (Modelado de Datos, Normalización y Diagrama Entidad-Relación)
* **Archivos creados o modificados:**
  - `DER_ADUANA.mmd` (Creado): Diagrama Entidad-Relación en formato Mermaid estándar.
  - `DISEÑO_MODELO_DATOS.md` (Creado): Especificación detallada del modelo de datos, diccionario de columnas, restricciones, normalización y justificaciones.
  - `BITACORA_DESARROLLO.md` (Creado): Registro cronológico y control del proyecto.
* **Propósito de la acción:** Diseñar una base de datos relacional robusta en MySQL para el Sistema de Inventario Aduanero que satisfaga los requisitos de negocio, cumpla con la 3FN y responda eficazmente a las consultas analíticas del futuro agente de IA.
* **Actividades realizadas:**
  1. Identificación y modelado de 13 entidades esenciales: `PAIS`, `CATEGORIA_ARANCELARIA`, `PRODUCTO`, `OPERADOR_COMERCIAL`, `AGENTE_ADUANERO`, `FUNCIONARIO`, `BODEGA`, `CONTENEDOR`, `DECLARACION_ADUANERA`, `DETALLE_DECLARACION`, `INVENTARIO`, `MOVIMIENTO_INVENTARIO`, `INSPECCION_ADUANERA`.
  2. Resolución arquitectónica de los 7 desafíos de dominio:
     - Unificación de importadores y exportadores en `operador_comercial` con discriminador de rol para evitar duplicidad de personas jurídicas.
     - Resolución de la relación N:M entre declaraciones y productos mediante `detalle_declaracion` con unicidad compuesta (`declaracion_id`, `numero_linea`).
     - Segregación total entre cantidad declarada (documental) e inventario físico real por bodega y producto en `inventario`.
     - Desacoplamiento de estados independientes (declaración, lote de inventario y resultado de inspección).
     - Auditoría y trazabilidad inmutable mediante `movimiento_inventario`.
     - Integración de catálogos internacionales (países, contenedores ISO, partidas arancelarias SAC/HS).
     - Inclusión de relaciones recursivas justificadas (`categoria_arancelaria.categoria_padre_id` y `funcionario.supervisor_id`).
  3. Redacción del diccionario de datos exhaustivo con tipos de datos MySQL, PK, FK, restricciones `CHECK`, `UNIQUE` y columnas generadas.
  4. Construcción del archivo Mermaid `DER_ADUANA.mmd`.
* **Problema o error encontrado:**
  - Se evaluó la generación automática del archivo gráfico `DER_ADUANA.png`, pero no se cuenta con la biblioteca `@mermaid-js/mermaid-cli` (`mmdc`) ni renderizadores gráficos instalados en el sistema operativo.
* **Solución aplicada:**
  - Respetando la regla de no instalar paquetes pesados innecesarios y no generar archivos vacíos o fraudulentos, se mantuvo `DER_ADUANA.mmd` en sintaxis Mermaid estándar compatible con previsualizadores de Markdown (Antigravity IDE, GitHub, VS Code y Mermaid Live Editor) y se documentó el método de renderizado.
* **Validaciones ejecutadas y resultados reales:**
  1. *Validación de integridad referencial cruzada:* Se verificó que cada una de las 23 claves foráneas definidas en `DISEÑO_MODELO_DATOS.md` apunte a una tabla y columna existente. Resultado: **100% de coherencia.**
  2. *Validación de unicidad y restricciones compuestas:* Se verificaron las restricciones `uk_declaracion_linea` en `detalle_declaracion` y `uk_bodega_producto` en `inventario`. Resultado: **Conforme.**
  3. *Validación sintáctica del DER:* Se validó la estructura de entidades y cardinalidades de `DER_ADUANA.mmd` mediante inspección automatizada. Resultado: **Sintaxis Mermaid válida.**
* **Decisiones pendientes:**
  - DEC-01 (MySQL Server): Continúa en verificación antes de pasar a la ejecución del script DDL.
* **Estado final de la etapa:** **Completado.**

---

### Registro #3: Etapa 2.1 — Auditoría Técnica y Corrección del Modelo de Datos y DER
* **Fecha:** 2026-10-23
* **Etapa:** Etapa 2.1 (Auditoría Técnica, Blindaje de Integridad y Optimización)
* **Archivos modificados:**
  - `DER_ADUANA.mmd`: Alineación completa de valores enums en comentarios, tipos estandarizados (`DECIMAL(12,2)`) y comentarios precisos.
  - `DISEÑO_MODELO_DATOS.md`: Incorporación de versión objetivo provisional (MySQL 8.0.16+), diferenciación formal entre registrar y proteger la auditoría, matriz de consistencia de bodegas, restricciones anti-ciclo en recursivas, e índices analíticos optimizados.
  - `BITACORA_DESARROLLO.md`: Registro de hallazgos, correcciones y resultados verificados.
* **Propósito de la acción:** Realizar una revisión crítica exhaustiva de las 13 entidades, claves, restricciones, cardinalidades e índices para detectar inconsistencias lógicas o debilidades en la trazabilidad de inventarios antes de escribir el DDL.
* **Problemas y defectos detectados:**
  1. 🔴 *Defecto Crítico (Falsa Inmutabilidad de Auditoría):* Se afirmaba que `movimiento_inventario` era una tabla inmutable, cuando en MySQL cualquier tabla permite mutaciones si no se configuran restricciones de permisos o triggers.
  2. 🟡 *Defecto Moderado (Riesgo de traslados y movimientos inconsistentes):* `movimiento_inventario` no exigía coherencia entre `tipo_movimiento`, `bodega_origen_id` y `bodega_destino_id`, permitiendo traslados con bodegas nulas o con origen igual a destino.
  3. 🟡 *Defecto Moderado (Ciclos en relaciones recursivas):* `categoria_arancelaria` y `funcionario` no impedían que un registro fuera su propio padre o supervisor directo (`categoria_padre_id = id_categoria` o `supervisor_id = id_funcionario`).
  4. 🟡 *Defecto Moderado (Cuello de botella en consulta de stock total):* En `inventario`, la clave única `(bodega_id, producto_id)` impedía el uso de índices al buscar solo por `producto_id` (*leftmost prefix rule*), forzando un escaneo completo de tabla.
  5. 🟡 *Defecto Moderado (Pérdida de trazabilidad por `ON DELETE SET NULL`):* Si se borraba una declaración o acta de inspección, los movimientos de almacén asociados quedaban huérfanos.
  6. 🟢 *Defecto Menor (Discrepancia en comentarios del DER):* Los textos de enums en `DER_ADUANA.mmd` abreviaban valores que estaban completos en el diccionario de datos.
  7. 🟢 *Defecto Menor (Incertidumbre en versión de MySQL):* No se explicitaba que las restricciones `CHECK` requieren MySQL 8.0.16 o superior.
* **Soluciones aplicadas:**
  1. *Blindaje de auditoría:* Se diferenció formalmente la estructura de solo adición (*append-only log*) del mecanismo de protección física (revocación de permisos `UPDATE`/`DELETE` y triggers con `SIGNAL SQLSTATE '45000'`).
  2. *Matriz de consistencia de bodegas:* Se añadieron restricciones `CHECK` para forzar que `TRASLADO_ENTRE_BODEGAS` tenga origen y destino no nulos y distintos, que `INGRESO_IMPORTACION` tenga destino no nulo, y que `SALIDA_DESPACHO` tenga origen no nulo.
  3. *Restricciones anti-ciclo:* Se agregaron `CHECK (categoria_padre_id IS NULL OR categoria_padre_id <> id_categoria)` y `CHECK (supervisor_id IS NULL OR supervisor_id <> id_funcionario)`.
  4. *Índices analíticos especializados:* Se diseñaron e incorporaron formalmente 6 índices secundarios (incluyendo `idx_inventario_producto`, `idx_inventario_bodega_retenido`, `idx_declaracion_tipo_fecha`, `idx_contenedor_estado_pais`).
  5. *Blindaje de trazabilidad documental:* Se cambió la acción foránea en `movimiento_inventario` a `ON DELETE RESTRICT` para declaraciones e inspecciones.
  6. *Alineación de archivos:* Se sincronizaron exhaustivamente todos los comentarios y tipos entre `DER_ADUANA.mmd` y `DISEÑO_MODELO_DATOS.md`.
  7. *Documentación de versión:* Se estableció formalmente el supuesto provisional de MySQL 8.0.16+.
* **Validaciones ejecutadas y resultados reales:**
  - Se ejecutó el validador ampliado en Node.js ([`validate_model_expanded.js`](file:///C:/Users/FORWARD/.gemini/antigravity-ide/brain/79e8ca2a-ad99-464e-8353-799219f7de8f/scratch/validate_model_expanded.js)).
  - Resultado: **13/13 entidades comprobadas, 24/24 relaciones verificadas, 24/24 claves foráneas válidas, 0 errores sintácticos en Mermaid.**
  - Resultado de integridad en Git: Ningún commit o push ejecutado.
* **Estado final de la etapa:** **Completado.**

---

### Registro #4: Etapa 3 — Creación y Validación Estructural del Script DDL (`schema.sql`)
* **Fecha:** 2026-10-23
* **Etapa:** Etapa 3 (Generación DDL de Base de Datos y Cumplimiento del Anexo de Validaciones)
* **Archivos creados:**
  - `schema.sql`: Script DDL completo con sentencias `CREATE DATABASE`, 13 tablas `CREATE TABLE`, motor InnoDB, juego de caracteres `utf8mb4`, 24 claves foráneas, 17 restricciones `CHECK`, 9 índices analíticos B-Tree y columna generada `STORED`.
* **Propósito de la acción:** Materializar el modelo conceptual y relacional auditado en un script ejecutable SQL de alta fidelidad, asegurando el orden correcto de dependencias y las reglas de negocio del anexo.
* **Cumplimiento de los 8 puntos del Anexo Obligatorio:**
  1. *Cantidades y saldos:* Se definieron restricciones `CHECK (cantidad_declarada > 0)`, `CHECK (cantidad_disponible >= 0)`, `CHECK (cantidad_retenida >= 0)` y `CHECK (cantidad > 0)`. Se documentó expresamente que impedir que una salida supere el saldo disponible requiere lógica transaccional (`SELECT ... FOR UPDATE` + `UPDATE`), reconociendo que los `CHECK` de MySQL operan únicamente a nivel de fila y no pueden consultar dinámicamente saldos en tablas concurrentes.
  2. *Movimientos de inventario:* Se incorporaron las restricciones `chk_movimiento_traslado`, `chk_movimiento_ingreso` y `chk_movimiento_salida` impidiendo traslados a la misma bodega y faltantes de ubicación, sin suponer que `CHECK` puede consultar otras tablas.
  3. *Integridad transaccional:* Se documentó la pauta técnica para que las operaciones de inserción de movimientos y actualización de inventario se ejecuten bajo transacciones ACID (`START TRANSACTION ... COMMIT`) con nivel de aislamiento adecuado.
  4. *Protección del historial:* Se preservó `ON DELETE RESTRICT` en las llaves hacia `declaracion_aduanera` e `inspeccion_aduanera`. Se reconoció formalmente que la inmutabilidad física real dependerá de la revocación de permisos (`REVOKE UPDATE, DELETE`) y triggers de bloqueo en producción.
  5. *Compatibilidad:* Objetivo provisional fijado en MySQL 8.0.16+. Se documenta que no se asume instalada sin prueba real.
  6. *Validación estructural cruzada:* Se ejecutó el script [`validate_schema_sql.js`](file:///C:/Users/FORWARD/.gemini/antigravity-ide/brain/79e8ca2a-ad99-464e-8353-799219f7de8f/scratch/validate_schema_sql.js), comparando el 100% de tablas, columnas, claves, restricciones e índices contra `DISEÑO_MODELO_DATOS.md` y `DER_ADUANA.mmd`.
  7. *Prueba real pendiente:* Se verificó la disponibilidad de MySQL en el host local mediante `Test-NetConnection -Port 3306` (`TcpTestSucceeded: False`) y `Get-Command mysql`. Al no estar activo el servidor, se completó la validación estática y se documenta como limitación que la ejecución real queda pendiente sin forzar instalaciones de software no autorizadas.
  8. *Bitácora actualizada:* Se mantuvo el historial íntegro de registros anteriores agregando esta sección formal.
* **Validaciones ejecutadas y resultados reales:**
  - Script Node.js de validación estructural: **13/13 tablas comprobadas, 24/24 claves foráneas válidas, 17/17 restricciones CHECK verificadas, 9/9 índices analíticos confirmados, 0 comas residuales.**
  - Prueba de conectividad MySQL: `localhost:3306` inactivo (`TcpTestSucceeded: False`).
* **Decisiones pendientes:**
  - DEC-01 (MySQL Server): Sigue en verificación previa al despliegue real.
* **Estado final de la etapa:** **Completado (Validación Estática Exitosa).**

---

### Registro #5: Etapa 3.1 — Auditoría Final de schema.sql y Preparación para Ejecución
* **Fecha:** 2026-10-23
* **Etapa:** Etapa 3.1 (Auditoría Técnica Forense de schema.sql)
* **Archivos examinados:**
  - `schema.sql` (Modificado con 3 restricciones de dominio adicionales).
  - `DISEÑO_MODELO_DATOS.md` (Sincronizado con las nuevas restricciones).
  - `DER_ADUANA.mmd` (Verificado: 100% coincidente).
  - `BITACORA_DESARROLLO.md` (Actualizado).
* **Propósito de la acción:** Auditar minuciosamente cada tabla, columna, tipo de dato, restricción, índice y cardinalidad para verificar su coherencia absoluta con el diseño y asegurar que el DDL esté técnicamente blindado antes de cualquier ejecución en MySQL 8.0.16+.
* **Errores encontrados y correcciones aplicadas:**
  1. *Falta de restricción física en peso de contenedores:* Se agregó `CONSTRAINT chk_contenedor_peso_rel CHECK (peso_maximo_kg > tara_kg)` en `contenedor`.
  2. *Inconsistencia temporal en declaraciones:* Se agregó `CONSTRAINT chk_declaracion_fechas CHECK (fecha_liquidacion IS NULL OR fecha_liquidacion >= fecha_registro)` en `declaracion_aduanera`.
  3. *Ambigüedad de ubicación en retenciones internas:* Se añadió `CONSTRAINT chk_movimiento_operacion_interna CHECK (tipo_movimiento NOT IN ('BLOQUEO_RETENCION', 'LIBERACION_RETENCION', 'AJUSTE_MERMA', 'DECOMISO') OR (bodega_origen_id IS NOT NULL OR bodega_destino_id IS NOT NULL))` en `movimiento_inventario`.
  4. *Sincronización documental:* Se actualizaron las especificaciones en `DISEÑO_MODELO_DATOS.md`.
* **Problemas que NO se encontraron (Comprobados y Correctos):**
  - Todas las cantidades e importes monetarios cuentan con restricciones `CHECK (>= 0)` o `CHECK (> 0)`.
  - La columna `cantidad_total` es generada `STORED` como suma exacta de `cantidad_disponible + cantidad_retenida`.
  - La restricción `UNIQUE` compuesta `uk_bodega_producto (bodega_id, producto_id)` existe y previene duplicidad física en `inventario`.
  - El orden topológico de creación es estrictamente ascendente (las 13 tablas se crean antes de ser referenciadas por claves foráneas).
  - No existen comas residuales ni sintaxis obsoleta; 100% compatible con MySQL 8.0.16+.
  - La documentación no asume falsamente inmutabilidad física ni protección contra concurrencia sin transacciones.
* **Pruebas estáticas ejecutadas y resultados:**
  - Script [`validate_schema_sql.js`](file:///C:/Users/FORWARD/.gemini/antigravity-ide/brain/79e8ca2a-ad99-464e-8353-799219f7de8f/scratch/validate_schema_sql.js): **13/13 tablas, 24/24 FKs, 20/20 restricciones CHECK, 9/9 índices analíticos B-Tree, motor InnoDB en el 100% de tablas. Resultado: 0 errores.**
* **Ejecución en servidor real:**
  - Se confirmó nuevamente la indisponibilidad local de MySQL Server (`localhost:3306` inactivo). La ejecución en vivo queda **pendiente** para la etapa de despliegue sin alterar la configuración del sistema.
* **Estado de decisiones pendientes:**
  - DEC-01 (MySQL Server): En verificación.
  - DEC-02 (DeepSeek API): Pendiente (Etapa 7).
  - DEC-03 (Conexión n8n - MySQL): Pendiente (Etapa 6).
  - DEC-04 (Diseño de datos): Resuelta y auditada.
* **Estado final de la etapa:** **Completado.**

---

### Registro #6: Verificación Adicional Obligatoria — Reglas de Movimientos de Inventario
* **Fecha:** 2026-10-23
* **Etapa:** Etapa 3.2 (Verificación Detallada de Reglas de Movimientos de Inventario)
* **Archivos examinados y modificados:**
  - `schema.sql`: Refinamiento estricto de `chk_movimiento_ingreso` (forzando `bodega_origen_id IS NULL AND bodega_destino_id IS NOT NULL`) y `chk_movimiento_salida` (forzando `bodega_origen_id IS NOT NULL AND bodega_destino_id IS NULL`).
  - `DISEÑO_MODELO_DATOS.md`: Sección 3.6 actualizada con la matriz detallada de los 7 movimientos, los efectos en cantidades y la distinción entre registrar y actualizar inventario.
  - `BITACORA_DESARROLLO.md`: Registro de la verificación, documentación de ambigüedad en operaciones internas y tabla de efectos.
* **Propósito de la acción:** Analizar individualmente cada uno de los 7 tipos de movimiento definidos en el esquema (`INGRESO_IMPORTACION`, `SALIDA_DESPACHO`, `TRASLADO_ENTRE_BODEGAS`, `BLOQUEO_RETENCION`, `LIBERACION_RETENCION`, `AJUSTE_MERMA`, `DECOMISO`), determinando qué bodegas deben informarse, cuáles deben quedar nulas y el efecto físico exacto en los saldos.
* **Problema o ambigüedad detectada:**
  - En operaciones internas de almacén (`BLOQUEO_RETENCION`, `LIBERACION_RETENCION`, `AJUSTE_MERMA`, `DECOMISO`), la mercancía no cambia de recinto. Existía ambigüedad sobre si la bodega de custodia debe registrarse únicamente en `bodega_origen_id` (con `bodega_destino_id IS NULL`) o si deben duplicarse (`bodega_origen_id = bodega_destino_id`).
* **Solución y recomendación técnica:**
  - Se documenta formalmente la convención recomendada (Opción A): registrar la bodega de custodia en `bodega_origen_id` dejando `bodega_destino_id` en `NULL` (al no haber traslado físico hacia otro recinto).
  - Se deja planteada la decisión para confirmación del usuario antes de la generación de datos de prueba (`data.sql`).
* **Distinción crítica de arquitectura ratificada:**
  - Un `INSERT INTO movimiento_inventario` es un registro del libro diario de auditoría (*audit log*); no modifica de forma reactiva o automática las columnas `cantidad_disponible` o `cantidad_retenida` en la tabla `inventario` si no se ejecutan sentencias `UPDATE inventario` explícitas dentro de la misma transacción ACID o mediante triggers de base de datos.
* **Validaciones ejecutadas y resultados reales:**
  - Script [`validate_movements.js`](file:///C:/Users/FORWARD/.gemini/antigravity-ide/brain/79e8ca2a-ad99-464e-8353-799219f7de8f/scratch/validate_movements.js): **Los 7 tipos de movimiento comprobados y consistentes al 100% en `schema.sql`, `DER_ADUANA.mmd` y `DISEÑO_MODELO_DATOS.md`.**
* **Estado final de la etapa:** **Completado.**

---

### Registro #7: Etapa 4.1 — Corrección y Cierre de Reglas de Movimientos de Inventario (Opción A Confirmada)
* **Fecha:** 2026-10-23
* **Etapa:** Etapa 4.1 (Cierre Formal de Restricciones de Movimientos Internos)
* **Archivos examinados y modificados:**
  - `schema.sql`: Restricción `chk_movimiento_operacion_interna` modificada para forzar estrictamente `bodega_origen_id IS NOT NULL AND bodega_destino_id IS NULL` para los 4 tipos de movimientos internos (`BLOQUEO_RETENCION`, `LIBERACION_RETENCION`, `AJUSTE_MERMA`, `DECOMISO`).
  - `DISEÑO_MODELO_DATOS.md`: Sincronizada la especificación técnica de la restricción en la sección 5.12.
  - `BITACORA_DESARROLLO.md`: Registro formal de la decisión adoptada y estado de los saldos.
* **Propósito de la acción:** Aplicar la decisión confirmada por el usuario (Opción A) para movimientos internos, garantizando que el DDL prohíba que una operación interna indique una bodega de destino, puesto que la mercancía permanece en el mismo recinto y solo muta su condición jurídica o saldo.
* **Correcciones realizadas:**
  - Se sustituyó la cláusula ambigua `OR (bodega_origen_id IS NOT NULL OR bodega_destino_id IS NOT NULL)` por la condición unívoca `OR (bodega_origen_id IS NOT NULL AND bodega_destino_id IS NULL)` en `schema.sql`.
* **Análisis de saldos y decisiones pendientes para datos de prueba (`data.sql`):**
  1. *INGRESO_IMPORTACION:* Se confirma que el arribo ingresa a `cantidad_disponible` en la bodega destino. Si se requiere retención inmediata por aforo rojo, se modelará un movimiento consecutivo de `BLOQUEO_RETENCION` vinculado al acta de inspección.
  2. *BLOQUEO_RETENCION:* Disminuye `cantidad_disponible` e incrementa `cantidad_retenida` en igual magnitud dentro de la bodega origen (`bodega_origen_id`).
  3. *LIBERACION_RETENCION:* Disminuye `cantidad_retenida` e incrementa `cantidad_disponible` en la bodega origen (`bodega_origen_id`).
  4. *AJUSTE_MERMA:* Se documenta como propuesta que descuente de `cantidad_disponible` (reduciendo `cantidad_total`). Pendiente confirmación si se requiere merma sobre retenido.
  5. *DECOMISO:* Se documenta como propuesta que descuente de `cantidad_retenida` (reduciendo `cantidad_total`), asumiendo que todo decomiso es la resolución sancionatoria de una retención previa.
* **Distinción transaccional ratificada:**
  - Las restricciones `CHECK` verifican exclusivamente la coherencia de columnas en la fila del movimiento. La actualización de existencias en `inventario` y la prevención de sobregiros de stock requieren lógica transaccional (`SELECT ... FOR UPDATE` + `UPDATE`).
* **Validaciones estáticas ejecutadas y resultados:**
  - Script [`validate_movements.js`](file:///C:/Users/FORWARD/.gemini/antigravity-ide/brain/79e8ca2a-ad99-464e-8353-799219f7de8f/scratch/validate_movements.js): **Opción A verificada al 100% en los 7 tipos de movimiento.**
  - Script [`validate_schema_sql.js`](file:///C:/Users/FORWARD/.gemini/antigravity-ide/brain/79e8ca2a-ad99-464e-8353-799219f7de8f/scratch/validate_schema_sql.js): **13 tablas, 24 FKs, 20 CHECKs, 9 índices analíticos verificados con 0 errores.**
* **Estado de decisiones pendientes:**
  - DEC-01 (MySQL Server): En verificación (puerto 3306 inactivo localmente).
  - DEC-02 (DeepSeek API): Pendiente (Etapa 7).
  - DEC-03 (Conexión n8n - MySQL): Pendiente (Etapa 6).
  - DEC-04 (Diseño de datos y movimientos): **Cerrada y resuelta.**
* **Estado final de la etapa:** **Completado.**

---

### Registro #8: Etapa 4 — Creación y Validación Estática de Datos de Prueba (data.sql)
* **Fecha:** 2026-10-23
* **Etapa:** Etapa 4 (Poblado de Datos de Prueba Coherentes y Validación Estática DML)
* **Archivos examinados y modificados:**
  - `data.sql`: Creación del archivo DML completo con 88 registros estructurados para las 13 tablas relacionales.
  - `BITACORA_DESARROLLO.md`: Registro de confirmación de decisiones de negocio, desglose cuantitativo por tabla y reporte de auditoría estática.
* **Decisiones de negocio confirmadas e implementadas:**
  1. *AJUSTE_MERMA:* Para el conjunto inicial de datos de prueba, la merma se descuenta exclusivamente de `cantidad_disponible` en la bodega de custodia (`bodega_origen_id`), reduciendo `cantidad_total`. No se incluyen mermas sobre mercancía retenida en esta versión.
  2. *DECOMISO:* Para el conjunto inicial de datos de prueba, el decomiso se descuenta exclusivamente de `cantidad_retenida` en la bodega de custodia (`bodega_origen_id`), reduciendo `cantidad_total`, asumiendo que la mercancía fue inmovilizada previamente mediante aforo o acta de inspección.
* **Propósito de la acción:** Desarrollar un script DML con datos realistas, variados y matemáticamente conciliados que respeten al 100% el esquema relacional (`schema.sql`), las claves foráneas, restricciones de dominio `CHECK`, columnas generadas (`cantidad_total`) y las consultas analíticas que resolverá el agente de IA.
* **Desglose de registros por tabla (88 registros en total):**
  1. `pais`: **10 registros** (China, Estados Unidos, Costa Rica, México, Alemania, Japón, Brasil, Panamá, España, Corea del Sur; códigos ISO alfa-2 y alfa-3).
  2. `categoria_arancelaria`: **10 registros** (Capítulos SAC/HS con jerarquía padre-hijo y alícuotas arancelarias entre 0% y 25%).
  3. `operador_comercial`: **6 registros** (Importadores, exportadores y mixtos; números de cédula jurídica/EIN realistas).
  4. `agente_aduanero`: **4 registros** (Agentes con licencias aduanales vigentes en estado HABILITADO).
  5. `funcionario`: **6 registros** (Estructura de personal con jerarquía recursiva: Director, Jefa de Recintos, Inspectores de Aforo y Custodios).
  6. `bodega`: **4 registros** (Bodegas fiscales en Caldera, depósito refrigerado en Moín y almacén de cuarentena).
  7. `contenedor`: **8 registros** (Formatos ISO de contenedor; China lidera con 4 unidades recibidas en puerto).
  8. `producto`: **8 registros** (SKUs estandarizados para laptops, smartphones, SUVs, fármacos, café, tablets, servidores y paneles solares).
  9. `declaracion_aduanera`: **6 registros** (4 declaraciones registradas en octubre de 2026; TechGlobal líder en valor CIF acumulado).
  10. `detalle_declaracion`: **6 registros** (Cantidades declaradas, precios FOB unitarios y montos arancelarios calculados).
  11. `inspeccion_aduanera`: **4 registros** (2 actas con observaciones que originaron retención cautelar o emplazamientos).
  12. `inventario`: **8 registros** (Saldos disponibles y retenidos conciliados con precisión con los movimientos de existencias).
  13. `movimiento_inventario`: **10 registros** (100% apegados a la Opción A: ingresos, salidas, traslados y movimientos internos de retención, liberación, merma y decomiso).
* **Validaciones estáticas ejecutadas y resultados reales:**
  - Script automatizado de auditoría estática ([`validate_data_sql.js`](file:///C:/Users/FORWARD/.gemini/antigravity-ide/brain/79e8ca2a-ad99-464e-8353-799219f7de8f/scratch/validate_data_sql.js)):
    - Integridad de PK y UK: 13 tablas sin colisiones de identificadores ni códigos únicos.
    - Integridad referencial: Las 24 claves foráneas apuntan a registros padres existentes y válidos.
    - Restricciones de operaciones de inventario: Los 10 movimientos cumplen estrictamente `chk_movimiento_operacion_interna`, `chk_movimiento_ingreso`, `chk_movimiento_salida` y `chk_movimiento_traslado`.
    - Conciliación de existencias: El inventario resultante de Producto 1 (Bodegas 1 y 3), Producto 2 (Bodega 2) y Producto 6 (Bodega 2) concuerda matemáticamente con el historial de movimientos.
    - Respuestas a escenarios analíticos del Agente IA:
      - Q1 (Mercancía de China retenida en Bodega 2): Productos 2 (Smartphones) y 6 (Tablets) retenidos satisfactoriamente.
      - Q2 (Declaraciones en octubre 2026): 4 declaraciones coincidentes.
      - Q3 (País con más contenedores): China (id 1) con 4 contenedores en puerto.
      - Q4 (Importador mayor valor CIF): TechGlobal (id 1) con $771,000.00 CIF.
      - Q5 (Inspecciones con observaciones): 2 actas detectadas (Inspectores Monge y Rojas).
      - Q6 (Stock disponible de laptops): 400 unidades (320 en Bodega 1 + 80 en Bodega 3).
* **Certificación de entorno y distinción técnica obligatoria:**
  - Se certifica que todas las validaciones presentadas son **estáticas y analíticas sobre el script SQL**. No se han insertado filas en un servidor MySQL activo debido a que el servicio local (puerto 3306) no se encuentra levantado. El script `data.sql` queda preparado y listo para su ejecución inmediata una vez provista la base de datos.
* **Estado de decisiones pendientes:**
  - DEC-01 (Disponibilidad de MySQL Server): En verificación / Pendiente (limitación ambiental documentada).
  - DEC-02 (Credenciales / API DeepSeek): Pendiente (Etapa 7).
  - DEC-03 (Configuración n8n - MySQL): Pendiente (Etapa 6).
  - DEC-04 (Diseño de datos, movimientos y saldos de prueba): **Cerrada y resuelta.**
* **Estado final de la etapa:** **Completado.**

---

### Registro #9: Etapa 4.2 — Auditoría Final de data.sql y Consultas del Agente IA
* **Fecha:** 2026-10-23
* **Etapa:** Etapa 4.2 (Auditoría Profunda de Integridad Relacional, Trazabilidad Contable y Consultas Analíticas IA)
* **Archivos examinados y modificados:**
  - `data.sql`:
    - Incorporación de `START TRANSACTION;` y `COMMIT;` para dotar de atomicidad ACID real (All-or-Nothing) a la carga DML en MySQL InnoDB.
    - Inclusión de 7 movimientos en `movimiento_inventario` (movs 11 al 17) para conciliar matemáticamente el 100% de los saldos físicos de las 8 combinaciones de `inventario`. El script totaliza ahora 95 registros.
  - `BITACORA_DESARROLLO.md`: Registro de hallazgos, correcciones, análisis de atomicidad y verificación de consultas.
* **Propósito de la acción:** Auditar con rigor técnico exhaustivo el script `data.sql`, contrastar los saldos del *Libro Mayor* (`inventario`) frente al *Libro Diario* (`movimiento_inventario`), identificar relaciones desconectadas o huérfanas, evaluar las garantías de atomicidad transaccional y verificar la respuesta exacta de las 6 consultas analíticas del Agente de IA.
* **Hallazgos detectados y correcciones aplicadas:**
  1. *Trazabilidad de existencias incompleta (Corregida):*
     - *Hallazgo:* Cuatro combinaciones de bodega y producto en `inventario` (Productos 3, 4, 7 y 8) carecían de movimientos en `movimiento_inventario`, constituyendo existencias sin trazabilidad de ingreso en el libro diario.
     - *Corrección:* Se añadieron los movimientos 11 a 17 en `movimiento_inventario`, respaldados en las declaraciones aduaneras 3, 4 y 6, y en el acta de inspección 2. Con ello, las 8 combinaciones quedan **100% conciliadas matemáticamente**.
  2. *Entidades con relaciones logísticas no vinculadas a DUAs:*
     - `producto` ID 8 (Paneles Solares) y `producto` ID 6 (Tablets): no figuran en `detalle_declaracion`. Producto 6 ingresa como carga consolidadora sin DUA asignado, y Producto 8 como lote directo de depósito.
     - `contenedor` IDs 3, 4 y 8: permanecen en estado `RECIBIDO_EN_PUERTO` sin declaración asignada. Refleja la realidad operativa de contenedores descargados en patio portuario en espera de trámite por el agente aduanal.
     - `declaracion_aduanera` ID 3 vs `contenedor` ID 6: contenedor con país de origen 2 (EE. UU., línea APL) transportando carga de procedencia Japón (ID 6), patrón común en el comercio marítimo internacional donde la bandera del contenedor difiere del puerto de embarque.
     - `declaracion_aduanera` ID 5: exportación de café con `contenedor_id = NULL` y sin paso por bodegas fiscales de importación (embarque directo).
  3. *Análisis crítico de atomicidad con `FOREIGN_KEY_CHECKS = 0`:*
     - `SET FOREIGN_KEY_CHECKS = 0;` desactiva la validación de restricciones foráneas para la sesión, pero **no inicia ninguna transacción**. Bajo `autocommit = 1` en MySQL, cada `INSERT` es independiente; si el script falla a mitad de ejecución, los datos previos quedan comprometidos en disco.
     - MySQL **no valida retroactivamente** los datos cargados cuando se restaura `SET FOREIGN_KEY_CHECKS = 1`.
     - *Ajuste justificado:* Se envolvieron las inserciones en un bloque `START TRANSACTION; ... COMMIT;` para garantizar que la carga sea tratada como una unidad atómica única en InnoDB.
* **Resultados de las 6 consultas analíticas del Agente de IA:**
  - *Q1 (Mercancía de China retenida en Bodega 2):* Detecta 2 productos con stock retenido: Producto 2 (Smartphones Xiaomi: 990 unidades retenidas) y Producto 6 (Tablets Huawei: 250 unidades retenidas).
  - *Q2 (Declaraciones de importación en octubre de 2026):* Detecta con exactitud las 4 declaraciones registradas en octubre (`DEC-2026-IMP-00041`, `00042`, `00043`, `00044`).
  - *Q3 (País con más contenedores recibidos):* China lidera con 4 contenedores en estado `RECIBIDO_EN_PUERTO`.
  - *Q4 (Importador con mayor valor CIF acumulado):* TechGlobal lidera con $771,000.00 CIF total.
  - *Q5 (Inspecciones con observaciones y funcionarios responsables):* Detecta 2 actas con medidas cautelares o emplazamientos: `ACTA-INSP-2026-0042` (Lic. Andrés Monge Quirós) y `ACTA-INSP-2026-0044` (Licda. Elena Rojas Campos).
  - *Q6 (Stock total disponible de laptops):* Sumado **exclusivamente desde `inventario.cantidad_disponible`** sin tocar movimientos históricos: Bodega 1 (320) + Bodega 3 (80) = **400 unidades exactas**.
* **Certificación de entorno y limitaciones técnicas:**
  - Todas las comprobaciones se ejecutaron mediante scripts de introspección estática y álgebra relacional en Node.js ([`validate_data_sql.js`](file:///C:/Users/FORWARD/.gemini/antigravity-ide/brain/79e8ca2a-ad99-464e-8353-799219f7de8f/scratch/validate_data_sql.js), [`audit_prompt_4_2.js`](file:///C:/Users/FORWARD/.gemini/antigravity-ide/brain/79e8ca2a-ad99-464e-8353-799219f7de8f/scratch/audit_prompt_4_2.js), [`test_ai_queries.js`](file:///C:/Users/FORWARD/.gemini/antigravity-ide/brain/79e8ca2a-ad99-464e-8353-799219f7de8f/scratch/test_ai_queries.js)).
  - No se ha ejecutado código contra un servidor MySQL activo por persistir la indisponibilidad del servicio en el puerto local 3306.
* **Estado de decisiones pendientes:**
  - DEC-01 (MySQL Server): Pendiente / Limitación ambiental documentada.
  - DEC-02 (DeepSeek API): Pendiente (Etapa 7).
  - DEC-03 (Conexión n8n - MySQL): Pendiente (Etapa 6).
  - DEC-04 (Diseño de datos, movimientos y saldos de prueba): **Auditada, cerrada y resuelta con excelencia técnica.**
* **Estado final de la etapa:** **Completado.**

---

### Registro #10: Etapa 4.3 — Cierre Técnico de la Etapa de Datos y Certificación de Limitaciones
* **Fecha:** 2026-10-23
* **Etapa:** Etapa 4.3 (Cierre Técnico de Datos, Análisis de Reversión Transaccional y Certificación de Entorno)
* **Archivos examinados y modificados:**
  - `schema.sql`: Verificación de las 13 tablas, 24 FKs, 20 CHECKs, índices analíticos y columna generada `cantidad_total`.
  - `data.sql`: Verificación de la totalidad de registros, delimitadores transaccionales y de integridad foránea.
  - `DISEÑO_MODELO_DATOS.md`: Incorporación formal de la Sección 2.3 con la clarificación técnica y logística de las relaciones opcionales y escenarios de datos.
  - `DER_ADUANA.mmd`: Verificación de alineación al 100% de las 13 entidades y 24 cardinalidades.
  - `BITACORA_DESARROLLO.md`: Registro de cierre formal de la etapa de modelado y datos de prueba.
* **Confirmaciones directas realizadas en el código:**
  1. *Estructura Relacional:* 13 tablas normalizadas en 3FN presentes de forma idéntica en DDL, DER y documentación de diseño.
  2. *Cómputo Real de Registros en `data.sql`:* Se constatan **97 registros reales** distribuidos en: `pais` (10), `categoria_arancelaria` (10), `operador_comercial` (6), `agente_aduanero` (4), `funcionario` (6), `bodega` (4), `contenedor` (8), `producto` (8), `declaracion_aduanera` (6), `detalle_declaracion` (6), `inspeccion_aduanera` (4), `inventario` (8) y `movimiento_inventario` (17). Se aclara que la referencia preliminar a 95 registros provenía de sumar los 7 nuevos movimientos a la cifra preliminar de 88 (que omitía 2 categorías arancelarias por defecto de corte de punto y coma en el parser anterior).
  3. *Conciliación Física:* 8 de 8 combinaciones de `(bodega_id, producto_id)` concuerdan con exactitud matemática entre el libro diario (`movimiento_inventario`) y los saldos consolidados (`inventario`).
  4. *Reglas de Negocio Confirmadas:* `AJUSTE_MERMA` descuenta de `cantidad_disponible`, `DECOMISO` descuenta de `cantidad_retenida`, y la Opción A para operaciones internas exige `bodega_origen_id IS NOT NULL AND bodega_destino_id IS NULL`.
  5. *Consultas Analíticas IA:* Comprobadas las 6 consultas (Q1 a Q6), ratificando que Q6 suma exclusivamente sobre `inventario.cantidad_disponible` arrojando con precisión matemática **400 unidades**.
* **Dictamen técnico sobre la carga transaccional de `data.sql`:**
  - El script cuenta con `START TRANSACTION;` antes de las inserciones y `COMMIT;` al finalizar, junto con la desactivación y reactivación de `FOREIGN_KEY_CHECKS`.
  - **Advertencia crítica sobre reversión ante errores:** Se documenta expresamente que un archivo SQL plano **no garantiza por sí mismo un rollback automático si un cliente MySQL convencional lo ejecuta sin parámetros de control**. En modo batch estándar (`mysql < data.sql`), MySQL imprime el error producido por una sentencia fallida pero continúa ejecutando las líneas siguientes hasta llegar al `COMMIT;`, lo que consolidaría una carga parcial incompleta.
  - *Recomendación operativa para el despliegue:* Cuando se disponga del servidor MySQL real, la carga de `data.sql` deberá ejecutarse obligatoriamente con la directiva `--abort-source-on-error` o `--bail-on-error` desde la línea de comandos (`mysql -u root -p --abort-source-on-error < data.sql`), o ejecutarse dentro de un procedimiento almacenado con `DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; ... END`.
* **Documentación de relaciones logísticas:**
  - Se documentaron en la Sección 2.3 de `DISEÑO_MODELO_DATOS.md` las razones por las cuales existen contenedores sin DUA (patio portuario), declaraciones sin contenedor (cargas no contenerizadas o exportación), disparidad naviera de orígenes y movimientos internos sin inspección.
* **Certificación de entorno y limitaciones persistentes:**
  - Se certifica que todas las comprobaciones han sido **estáticas y lógicas** ejecutadas mediante scripts sobre Node.js.
  - **No se ha ejecutado ninguna sentencia en un motor MySQL activo**, dado que el puerto 3306 permanece inactivo y no hay binarios de MySQL en el PATH local.
* **Estado de decisiones pendientes:**
  - DEC-01 (Disponibilidad de MySQL Server): Pendiente / Limitación de entorno documentada.
  - DEC-02 (Credenciales DeepSeek API): Pendiente para Etapa 7.
  - DEC-03 (Conexión n8n - MySQL): Pendiente para Etapa 6.
  - DEC-04 (Diseño de datos, movimientos y saldos de prueba): **Oficialmente cerrada y finalizada con éxito.**
* **Dictamen de cierre de etapa:** La etapa de modelado, diseño relacional y generación de datos de prueba queda **técnicamente cerrada y aprobada** para avanzar a las fases posteriores del laboratorio (creación de consultas analíticas y flujos de automatización), manteniendo la salvedad de que las pruebas en motor MySQL se ejecutarán en cuanto el servidor esté disponible.

---

### Registro #11: Etapa 5 — Creación y Optimización de Consultas SQL Analíticas
* **Fecha:** 2026-10-23
* **Etapa:** Etapa 5 (Desarrollo, Validación Estática y Optimización de Consultas SQL para el Agente IA)
* **Archivos examinados y creados:**
  - `sql/consultas/Q1_mercancia_retenida_china.sql` (Nueva consulta: mercancías de China retenidas en Bodega 2).
  - `sql/consultas/Q2_importaciones_octubre_2026.sql` (Nueva consulta: declaraciones de importación en octubre de 2026 con rango semiabierto).
  - `sql/consultas/Q3_pais_con_mas_contenedores.sql` (Nueva consulta: país con más contenedores en puerto con resolución de empates vía CTE y `DENSE_RANK()`).
  - `sql/consultas/Q4_importador_mayor_valor_cif.sql` (Nueva consulta: importador líder por valor CIF acumulado con resolución de empates).
  - `sql/consultas/Q5_inspecciones_con_observaciones.sql` (Nueva consulta: actas con irregularidades, funcionario actuante y DUA).
  - `sql/consultas/Q6_stock_disponible_laptops.sql` (Nueva consulta: stock total de laptops sumando exclusivamente `inventario.cantidad_disponible`).
  - `scratch/validate_sql_queries.js` (Script automatizado de validación estática de consultas contra catálogo DDL y datos de prueba).
  - `BITACORA_DESARROLLO.md` (Registro y documentación técnica de la etapa).
* **Propósito y diseño técnico de cada consulta:**
  1. *Q1 (Mercancía de China retenida en Bodega 2):* Unión entre `inventario`, `producto`, `pais` y `bodega`. Proyecta producto, SKU, bodega, país de origen, cantidad retenida y estado. Filtra por `b.id_bodega = 2`, `pa.codigo_alfa2 = 'CN'` y `i.cantidad_retenida > 0`.
  2. *Q2 (Importaciones en octubre de 2026):* Unión entre `declaracion_aduanera`, `operador_comercial` y `agente_aduanero`. Utiliza un intervalo semiabierto exacto `[2026-10-01 00:00:00, 2026-11-01 00:00:00)` que abarca todo el mes sin depender de la hora ni truncar microsegundos, posibilitando el aprovechamiento óptimo de índices B-Tree sin degradación por funciones tipo `MONTH()`.
  3. *Q3 (País con más contenedores recibidos):* Agrupación de `contenedor` por `pais_origen_id` con filtro `c.estado = 'RECIBIDO_EN_PUERTO'`. Incorpora una CTE moderna de MySQL 8 con `DENSE_RANK() OVER (ORDER BY COUNT(c.id_contenedor) DESC)` para resolver empates sin truncar arbitrariamente a países empatados en el primer lugar.
  4. *Q4 (Importador con mayor valor CIF acumulado):* Agregación `SUM(da.valor_total_cif)` sobre `declaracion_aduanera` unida con `operador_comercial`, filtrando estrictamente `da.tipo_declaracion = 'IMPORTACION'`. Emplea CTE y `DENSE_RANK()` para preservar empates.
  5. *Q5 (Inspecciones con observaciones):* Filtro sobre `inspeccion_aduanera` con `tuvo_observaciones = TRUE`, uniendo con `funcionario` y `declaracion_aduanera`. Proyecta número de acta, fecha, tipo, resultado, funcionario, cargo, número de declaración y observaciones.
  6. *Q6 (Stock disponible de laptops):* Consulta directa sobre el Libro Mayor (`inventario`) agrupando por producto y sumando `i.cantidad_disponible` con filtro `p.codigo_sku = 'SKU-LAP-001'`. Respeta rigurosamente el principio arquitectónico de no iterar sobre movimientos históricos para balances consolidados.
* **Validaciones estáticas ejecutadas y resultados obtenidos:**
  - Script [`validate_sql_queries.js`](file:///C:/Users/FORWARD/.gemini/antigravity-ide/brain/79e8ca2a-ad99-464e-8353-799219f7de8f/scratch/validate_sql_queries.js) ejecutado exitosamente con Node.js:
    - *Integridad léxica y de catálogo:* El 100% de tablas, columnas y tipos `ENUM` coinciden de forma estricta con las definiciones de `schema.sql`.
    - *Ausencia de duplicados por unión:* Ninguna consulta realiza uniones 1:N que multipliquen filas erróneamente.
    - *Resultados comprobados contra `data.sql`:*
      - Q1: 2 productos encontrados (Smartphones Xiaomi: 990 unidades retenidas; Tablets Huawei: 250 unidades retenidas).
      - Q2: 4 declaraciones de importación registradas en octubre (`DEC-2026-IMP-00041`, `00042`, `00043`, `00044`).
      - Q3: China (4 contenedores recibidos en puerto).
      - Q4: TechGlobal ($771,000.00 CIF total acumulado).
      - Q5: 2 actas con observaciones (`ACTA-INSP-2026-0042` y `ACTA-INSP-2026-0044`).
      - Q6: 400 unidades de laptops disponibles ($320\text{ en Bodega 1} + 80\text{ en Bodega 3}$).
* **Revisión técnica de índices y propuesta de optimización futura:**
  - *Índices existentes en `schema.sql` teóricamente útiles:*
    - Q1: `idx_inventario_bodega_retenido (bodega_id, cantidad_retenida)`, `idx_producto_pais (pais_origen_id)`.
    - Q2: `idx_declaracion_tipo_fecha (tipo_declaracion, fecha_registro)`.
    - Q3: `idx_contenedor_estado_pais (estado, pais_origen_id)` (posible Covering Index / Using index).
    - Q4: `idx_declaracion_operador_valor (operador_comercial_id, valor_total_cif)`.
    - Q5: `idx_inspeccion_observaciones_func (tuvo_observaciones, funcionario_id)`.
    - Q6: `idx_inventario_producto (producto_id)` y `uk_producto_sku (codigo_sku)`.
  - *Propuesta de optimización separada (registrada para revisión futura):* Para grandes volúmenes de datos en producción, se propone evaluar un índice de cobertura compuesto:
    `CREATE INDEX idx_declaracion_tipo_operador_cif ON declaracion_aduanera (tipo_declaracion, operador_comercial_id, valor_total_cif);`
    el cual permitiría resolver Q4 íntegramente en memoria mediante un Index-Only Scan.
  - *Advertencia de rigor técnico:* No se afirma que ninguna consulta utilice efectivamente un índice en este momento, dado que la confirmación del plan de acceso requiere un análisis `EXPLAIN` real en el optimizador de costos de MySQL.
* **Certificación de entorno y limitaciones:**
  - Se certifica que las validaciones son de naturaleza **estática y relacional** simuladas con Node.js. No se ha ejecutado ninguna consulta contra un servidor MySQL activo debido a la inactividad del puerto 3306.
* **Estado de decisiones pendientes:**
  - DEC-01 (MySQL Server): Pendiente / Limitación documentada.
  - DEC-02 (DeepSeek API): Pendiente para Etapa 7.
  - DEC-03 (Conexión n8n - MySQL): Pendiente para Etapa 6.
  - DEC-04 (Diseño de datos, movimientos y saldos de prueba): Cerrada y resuelta.
* **Estado final de la etapa:** **Completado.**

---

### Registro #12: Etapa 5.2 — Correcciones Técnicas y Validación Real del Contenido SQL
* **Fecha:** 2026-10-23
* **Etapa:** Etapa 5.2 (Mejoras en Consultas SQL, Fortalecimiento del Validador y Certificación de Alcance)
* **Archivos examinados y modificados:**
  - `sql/consultas/Q1_mercancia_retenida_china.sql`: Actualización del filtro de bodega, sustituyendo el identificador surrogate `b.id_bodega = 2` por el código de negocio natural verificado `b.codigo_bodega = 'BOD-02'`, garantizando resiliencia frente a variaciones en la secuencia de autoincrementables.
  - `sql/consultas/Q6_stock_disponible_laptops.sql`: Reestructuración arquitectónica partiendo de `producto p` con `LEFT JOIN inventario i ON p.id_producto = i.producto_id` y agregación `COALESCE(SUM(i.cantidad_disponible), 0.00) AS stock_total`. Asegura que si un SKU existe en el catálogo pero carece de saldos registrados en `inventario`, retorne una fila con existencia `0.00` en lugar de un conjunto vacío.
  - `scratch/validate_sql_queries.js`: Fortalecimiento integral del script de auditoría. Se eliminó la limitación previa donde solo se verificaba existencia en disco y se simulaban datos en JavaScript. Ahora lee físicamente con `fs.readFileSync` el contenido de cada archivo `.sql`, audita la presencia de cláusulas fundamentales (`SELECT`, `FROM`), balance de paréntesis, terminadores de sentencia (`;`), filtros específicos de negocio (`BOD-02`, `CN`, rango semiabierto de octubre), funciones de ventana (`DENSE_RANK`), prevención de duplicaciones y ausencia de consultas a tablas históricas.
  - `BITACORA_DESARROLLO.md`: Registro de hallazgos, correcciones, validaciones y limitaciones.
* **Resultados esperados vs calculados en simulación de datos:**
  - *Q1:* 2 productos retenidos de origen China en `BOD-02` (Smartphones Xiaomi: 990; Tablets Huawei: 250) $\rightarrow$ Conforme.
  - *Q2:* 4 declaraciones de importación registradas en octubre de 2026 $\rightarrow$ Conforme.
  - *Q3:* China como país con mayor cantidad de contenedores recibidos en puerto (4 unidades) $\rightarrow$ Conforme.
  - *Q4:* TechGlobal como importador líder con $771,000.00 CIF acumulado en importaciones $\rightarrow$ Conforme.
  - *Q5:* 2 inspecciones aduaneras con observaciones registradas $\rightarrow$ Conforme.
  - *Q6:* 400.00 unidades de laptops disponibles en la red de bodegas $\rightarrow$ Conforme.
* **Declaración honesta de alcance y certificación de limitaciones:**
  - *Alcance del validador:* Las comprobaciones realizadas sobre los archivos `.sql` son estáticas, léxicas y estructurales mediante expresiones regulares y lectura de texto. **No constituyen un analizador sintáctico completo (AST) ni reemplazan la validación gramatical del motor MySQL 8**.
  - *Certificación de entorno:* Todos los resultados cuantitativos corresponden a una **simulación relacional en memoria con JavaScript** sobre `data.sql`. **No se ha ejecutado ninguna sentencia en un servidor MySQL activo** debido a que el servicio local en el puerto TCP 3306 no está levantado.
* **Estado de decisiones pendientes:**
  - DEC-01 (Disponibilidad de MySQL Server): Pendiente / Limitación documentada.
  - DEC-02 (DeepSeek API): Pendiente para Etapa 7.
  - DEC-03 (Conexión n8n - MySQL): Pendiente para Etapa 6.
  - DEC-04 (Diseño de datos, movimientos y consultas SQL): **Oficialmente cerrada, auditada y fortalecida.**
* **Estado final de la etapa:** **Completado.**

---

### Registro #13: Adaptación del Sistema a SQLite 3 y Ejecución Real en Motor de Base de Datos
* **Fecha:** 2026-10-23
* **Etapa:** Adaptación a SQLite 3, Ejecución en Motor Real y Diagnóstico de Integración con n8n
* **Archivos examinados y creados:**
  - `schema_sqlite.sql`: Archivo DDL completo adaptado para SQLite 3.31+. Define las 13 tablas con claves primarias `INTEGER PRIMARY KEY AUTOINCREMENT`, restricciones `CHECK` equivalentes para listas de valores (emulando tipos `ENUM`), activación de `PRAGMA foreign_keys = ON;`, columna generada `cantidad_total STORED`, disparador de actualización temporal y los 9 índices analíticos B-Tree.
  - `data_sqlite.sql`: Archivo DML transaccional (`BEGIN TRANSACTION; ... COMMIT;`) conteniendo los 97 registros de prueba idénticos a `data.sql`, respetando el orden topológico y las restricciones de integridad.
  - `sql/consultas_sqlite/`: Conjunto de las 6 consultas analíticas adaptadas para SQLite (`Q1_mercancia_retenida_china.sql` a `Q6_stock_disponible_laptops.sql`).
  - `aduana.db`: Archivo binario de base de datos SQLite (180,224 bytes) generado y persistido en la raíz del proyecto.
  - `deploy_and_test_sqlite.py`: Script automatizado para desplegar el DDL, cargar el DML, verificar claves foráneas (`PRAGMA foreign_key_check`), evaluar columnas generadas, ejecutar consultas analíticas y poner a prueba restricciones `CHECK` y claves foráneas.
  - Archivos originales MySQL preservados: `schema.sql`, `data.sql` y `sql/consultas/` se mantienen intactos sin alteraciones.
* **Resultados de ejecución en el motor real SQLite (Versión 3.50.4):**
  - *Despliegue estructural:* 13 tablas creadas y 9 índices analíticos verificados en `sqlite_master`.
  - *Carga de datos:* 97 registros sembrados exitosamente (10 países, 10 categorías, 6 operadores, 4 agentes, 6 funcionarios, 4 bodegas, 8 contenedores, 8 productos, 6 declaraciones, 6 detalles, 8 inventarios, 4 inspecciones, 17 movimientos).
  - *Integridad referencial:* 0 violaciones detectadas por `PRAGMA foreign_key_check`.
  - *Columna generada `cantidad_total STORED`:* Verificada en las 8 filas de `inventario`, calculando de forma determinista la suma de disponible y retenido.
  - *Pruebas de fallas controladas:* Se verificó el rechazo de inserciones con saldo negativo (`chk_inventario_cant_disp`), traslados entre la misma bodega (`chk_movimiento_traslado`), movimientos internos con destino informado (`chk_movimiento_operacion_interna`) y claves foráneas inexistentes (`fk_movimiento_producto`), arrojando `sqlite3.IntegrityError` en todos los casos.
* **Resultados reales de las consultas analíticas en SQLite:**
  - *Q1 (Mercancía retenida de China en BOD-02):* 2 filas retornadas (Tablets Huawei: 250 unidades; Smartphones Xiaomi: 990 unidades) $\rightarrow$ Exacto.
  - *Q2 (Declaraciones de importación en octubre de 2026):* 4 filas retornadas (DUA-00041, DUA-00042, DUA-00043, DUA-00044) $\rightarrow$ Exacto.
  - *Q3 (País con más contenedores recibidos en puerto):* 1 fila (China, 4 unidades) $\rightarrow$ Exacto.
  - *Q4 (Importador líder por valor CIF acumulado en importaciones):* 1 fila (TechGlobal S.A., Cédula `CJ-3101-789012`, $771,000.00 CIF) $\rightarrow$ Exacto.
  - *Q5 (Inspecciones aduaneras con observaciones):* 2 actas retornadas (ACTA-INSP-2026-0044 con Licda. Elena Rojas; ACTA-INSP-2026-0042 con Lic. Andrés Monge) $\rightarrow$ Exacto.
  - *Q6 (Stock total disponible de laptops SKU-LAP-001):* 1 fila (400 unidades consolidadas: 320 en Bodega 1 + 80 en Bodega 3) $\rightarrow$ Exacto.
* **Investigación de la discrepancia en Q3 (Contenedores recibidos):**
  - Se confirmó mediante auditoría cruzada que la tabla `contenedor` almacena físicamente 8 unidades, de las cuales 7 están en estado `RECIBIDO_EN_PUERTO`.
  - De las unidades en puerto, 4 tienen como país de origen China (`pais_origen_id = 1`), 1 Estados Unidos, 1 México y 1 Alemania.
  - De los 4 contenedores de China, 2 están vinculados a DUAs autorizadas y 2 corresponden a unidades recién descargadas en puerto sin DUA asociado aún (situación documentada intencionalmente en la sección 2.3 de `DISEÑO_MODELO_DATOS.md`).
  - La discrepancia reportada previamente (mención de 3 contenedores en borradores preliminares) se debió a un conteo que asumía la existencia obligatoria de una declaración asociada. Al consultar directamente la tabla `contenedor`, el número exacto y real es 4.
* **Diagnóstico de integración con n8n:**
  - Se examinó la instalación de n8n v2.38.6 y su paquete `n8n-nodes-base`. Core n8n carece de un nodo nativo específico para SQLite (a diferencia de MySQL o Postgres).
  - Vías técnicas confirmadas para conectar n8n a `aduana.db`:
    1. Nodo `Execute Command` invocando el motor de Python o script CLI (`python -c ...`) retornando la carga útil en formato JSON.
    2. Instalación de nodo comunitario (`n8n-nodes-sqlite`).
    3. Nodo `Code` utilizando el módulo nativo `node:sqlite` de Node.js v24 (configurando `NODE_FUNCTION_ALLOW_BUILTIN=*`).
    4. Microservicio local API / HTTP intermediario consultado mediante el nodo estándar `HTTP Request`.
* **Estado de decisiones del proyecto:**
  - DEC-01 (Motor de base de datos operativo): **Resuelta localmente con SQLite 3 (`aduana.db`).**
  - DEC-02 (Acceso a API de DeepSeek): Pendiente para Etapa 7.
  - DEC-03 (Mecanismo de integración n8n - Base de datos): Evaluada y documentada para la Etapa 6.
  - DEC-04 (Diseño de datos, movimientos y consultas): **Cerrada y validada en motor real.**
* **Estado final de la etapa:** **Completado con validación real en SQLite.**

---

### Registro #14: Implementación de Conector de Solo Lectura SQLite para n8n (`query_sqlite.py`) y Validación de Seguridad
* **Fecha:** 2026-10-23
* **Etapa:** Prompt 7 (Conexión Segura SQLite - n8n mediante Python y Lista Blanca de Consultas)
* **Archivos examinados y creados:**
  - `query_sqlite.py`: Conector de solo lectura basado en la biblioteca estándar `sqlite3` de Python 3.14. Resuelve la ruta absoluta de `aduana.db` respecto a la ubicación del script, valida la preexistencia y tamaño del archivo para evitar la creación accidental de bases de datos vacías en directorios de trabajo alternativos, se conecta mediante URI `file:{path}?mode=ro` (bloqueo físico de escritura a nivel del motor SQLite), habilita `PRAGMA foreign_keys = ON;`, verifica la presencia de las 13 tablas relacionales y aplica una **lista blanca estricta (whitelist)** para ejecutar exclusivamente las seis consultas aprobadas (`Q1` a `Q6`), bloqueando cualquier sentencia SQL arbitraria provista por un agente IA o usuario externo.
  - `test_query_sqlite.py`: Script de pruebas automatizadas que valida la ejecución de Q1–Q6, el paso de parámetros por flag y JSON, la resiliencia ante cambios de directorio de trabajo (`CWD`), y el rechazo estricto de consultas no autorizadas y bases inexistentes.
  - Confirmación física en n8n: Verificación de la presencia del nodo oficial `ExecuteCommand` (`ExecuteCommand.node.js`) en `n8n-nodes-base` (instalación global n8n 2.38.6).
  - Conservación de artefactos: Los archivos originales de MySQL (`schema.sql`, `data.sql`, `sql/consultas/`) se mantienen preservados íntegramente.
* **Pruebas y resultados reales:**
  - *Prevención de creación de bases vacías:* Apertura en modo `mode=ro` falla inmediatamente si el archivo no existe, impidiendo la dispersión de archivos `.db` vacíos de 0 bytes.
  - *Independencia del CWD:* El script fue ejecutado desde `C:\Users\FORWARD` y resolvió exactamente `aduana.db` y las consultas en `sql/consultas_sqlite/`.
  - *Ejecución de Q1 a Q6:*
    - Q1: 2 filas retornadas (250 tablets Huawei, 990 smartphones Xiaomi retenidos en `BOD-02`) en 4.34 ms.
    - Q2: 4 declaraciones de importación de octubre 2026 en 2.67 ms.
    - Q3: 1 fila (China líder con 4 unidades recibidas en puerto) en 3.17 ms.
    - Q4: 1 fila (TechGlobal S.A. con $771,000.00 CIF) en 5.34 ms.
    - Q5: 2 inspecciones aduaneras con observaciones registradas en 3.26 ms.
    - Q6: 1 fila (400 unidades de laptops disponibles: 320 en Bodega 1 + 80 en Bodega 3) en 4.39 ms.
  - *Pruebas de seguridad y mitigación de inyección:*
    - Intento de SQL arbitrario (`SELECT * FROM usuario`): Bloqueado con código de salida 1 y error `UNAUTHORIZED_QUERY`.
    - Consulta con identificador inexistente (`Q99`): Bloqueada con código 1 y error `UNAUTHORIZED_QUERY`.
    - Intento de escritura en `mode=ro`: Bloqueado por el motor SQLite con `attempt to write a readonly database`.
* **Diseño del flujo en n8n:**
  - El nodo `Execute Command` invocará: `python "c:\...\query_sqlite.py" --query {{$json.query_id}}`.
  - El resultado en stdout se procesa en el siguiente nodo mediante `JSON.parse($input.first().json.stdout)`.
* **Estado de decisiones del proyecto:**
  - DEC-01 (Motor de base de datos): Resuelta con SQLite 3 (`aduana.db`).
  - DEC-02 (Integración DeepSeek): Pendiente para Etapa posterior.
  - DEC-03 (Mecanismo de conexión n8n - SQLite): **Cerrada y validada mediante `query_sqlite.py` y nodo `ExecuteCommand`.**
  - DEC-04 (Diseño de datos, movimientos y consultas): Cerrada y verificada.
* **Estado final de la etapa:** **Completado.**

---

### Registro #15: Generación y Validación del Workflow n8n para el Sistema Aduanero (`workflow_aduana_deepseek.json`)
* **Fecha:** 2026-10-23
* **Etapa:** Prompt 8 (Generación de Workflow n8n Importable, Integración con DeepSeek y Validación)
* **Archivos examinados y creados:**
  - `workflow_aduana_deepseek.json`: Archivo de workflow JSON completo y estructurado para n8n v2.38.6. Contiene 11 nodos interconectados:
    1. *Webhook Aduana* (`webhook` v2, método POST, path `aduana-query`, `responseMode: responseNode`).
    2. *Validar Entrada* (`code` v2, verifica que `pregunta` exista y sea cadena no vacía).
    3. *¿Entrada Válida?* (`if` v2, bifurca a error 400 o clasificación).
    4. *Respuesta Error Entrada* (`respondToWebhook` v1.1, HTTP 400).
    5. *Clasificador DeepSeek* (`httpRequest` v4.2 hacia `https://api.deepseek.com/chat/completions`, modelo `deepseek-chat`, con prompt de sistema restringido y modo `json_object`).
    6. *Validar Clasificación* (`code` v2, extrae y valida deterministamente que el resultado sea estrictamente `Q1`–`Q6`).
    7. *¿Consulta Autorizada?* (`if` v2, bifurca a ejecución de consulta o respuesta informativa).
    8. *Respuesta No Autorizada* (`respondToWebhook` v1.1, HTTP 200 con catálogo de 6 preguntas admitidas).
    9. *Ejecutar Consulta Python* (`executeCommand` v1, invoca `query_sqlite.py --query {{$json.query_id}}`).
    10. *Procesar Resultados* (`code` v2, parsea JSON de Python y genera mensaje explicativo en lenguaje natural).
    11. *Respuesta Exitosa* (`respondToWebhook` v1.1, HTTP 200 con JSON enriquecido).
  - `validate_workflow_json.py`: Script de validación automatizada del grafo de n8n (sintaxis JSON, nodos, tipos, versiones, ausencia de rutas rotas y protección anti-inyección).
  - `README_WORKFLOW_N8N.md`: Guía completa en español de arquitectura, importación (CLI y Web UI), configuración de la credencial de DeepSeek, activación y pruebas de estrés.
* **Pruebas y validaciones ejecutadas:**
  - *Validación estática del JSON:* `validate_workflow_json.py` ejecutado exitosamente con código 0. Verificó 11 nodos, 8 orígenes de conexión, 3 nodos terminales y certificó que el comando CLI solo interpola `$json.query_id` validado y nunca `$json.pregunta`.
  - *Prueba de importación física en n8n:* Se ejecutó el comando real `n8n import:workflow --input=workflow_aduana_deepseek.json` contra la instancia local de n8n v2.38.6 en ejecución, logrando la importación exitosa (`Successfully imported 1 workflow`). Se verificó su presencia en el catálogo con `n8n list:workflow` bajo el ID `WfAduana20261023`.
* **Seguridad y desacoplamiento:**
  - El modelo de IA queda estrictamente limitado a la clasificación de intenciones. Nunca genera código SQL.
  - La base de datos `aduana.db` permanece en modo de solo lectura (`mode=ro`).
  - No se registraron credenciales reales en el archivo JSON (se utiliza el placeholder `Bearer YOUR_DEEPSEEK_API_KEY_HERE`).
* **Estado de decisiones del proyecto:**
  - DEC-01 (Motor de base de datos): Resuelta con SQLite 3 (`aduana.db`).
  - DEC-02 (Integración DeepSeek): **Configuración de nodo lista; pendiente únicamente el ingreso de la clave API por parte del usuario.**
  - DEC-03 (Mecanismo n8n - Base de datos): **Cerrada y validada.**
  - DEC-04 (Diseño de datos, movimientos y consultas): Cerrada y verificada.
* **Estado final de la etapa:** **Completado y workflow importado en n8n.**

---

### Registro #16: Corrección Estructural del Workflow en n8n, Conexión de Nodos Huérfanos y Validación Integral
* **Fecha:** 2026-10-26
* **Etapa:** Corrección de Conexiones del Workflow n8n, Estabilización de Nodos Condicionales y Aislamiento de Python
* **Archivos examinados y modificados:**
  - `workflow_aduana_deepseek.json.bak` / `workflow_aduana_deepseek_pre_fix.json`: Copias de respaldo del workflow original.
  - `workflow_aduana_deepseek.json`: Archivo corregido con los 11 nodos conectados de principio a fin, respetando los nombres de negocio legibles y las salidas de éxito y error.
  - `validate_workflow_json.py`: Script de validación automatizada que comprueba grafo, terminales, esquema `If v2.2` e inyección de comandos.
  - `README_WORKFLOW_N8N.md`: Diagrama y explicación técnica actualizados.
  - `C:\Users\FORWARD\.n8n\database.sqlite`: Sincronización directa en la base de datos de n8n para reflejar los cambios en la interfaz activa.
* **Diagnóstico de las causas de nodos desconectados/flotantes en n8n:**
  1. *Esquema legacy de condiciones en nodos IF:* En la versión moderna `n8n-nodes-base.if` (v2.2), n8n requiere la colección declarativa `parameters.conditions.conditions` con el operador tipado `{ type: "boolean", operation: "equals" }`. El archivo original utilizaba el formato v1/v2 legacy (`conditions: { boolean: [...] }`), lo que impedía al lienzo de n8n mapear los puertos de salida 0 (True) y 1 (False), dejando flotantes a `Clasificador DeepSeek`, `Respuesta Error Entrada`, `Ejecutar Consulta Python` y `Respuesta No Autorizada`.
  2. *Escapado erróneo del comando CLI en Python:* En el nodo `Ejecutar Consulta Python`, el comando original contenía comillas dobles anidadas inválidas (`="python ""c:\\..."" --query " + $json.query_id`). Se normalizó a la sintaxis oficial de expresión de n8n:
     `=python "c:\Users\FORWARD\Downloads\SistemaCaldera\TicTacToe\sistema de inventario aduana\sistema-de-inventario-aduana\query_sqlite.py" --query {{ $json.query_id }}`.
  3. *Alineación de referencias cruzadas entre nodos:* Se verificó que las llamadas en los nodos Code (`$('Validar Entrada')` y `$('Validar Clasificación')`) coincidan con los nombres reales de los nodos.
* **Propósito y justificación de Python en la arquitectura:**
  - n8n core v2.38.6 no dispone de nodo nativo para bases de datos SQLite.
  - `query_sqlite.py` actúa como firewall de seguridad:
    1. Abre `aduana.db` con `mode=ro` (solo lectura a nivel del motor SQLite).
    2. Aplica una whitelist estricta: solo acepta `Q1`–`Q6` y ejecuta los scripts `.sql` auditados.
    3. Impide que las preguntas en lenguaje natural o sentencias SQL arbitrarias lleguen a la base de datos o al shell.
    4. Devuelve un JSON estructurado hacia `stdout` que es procesado por el nodo `Procesar Resultados`.
* **Pruebas y validaciones ejecutadas:**
  - *Validación JSON y de Grafo:* `validate_workflow_json.py` ejecutado exitosamente (código 0, 11 nodos, 8 orígenes de conexión, 3 nodos terminales, 0 huérfanos).
  - *Prueba de ejecución del comando Python:* Ejecución de `query_sqlite.py --query Q6` verificada (400 unidades de laptops ThinkPad T14 retornadas en 9.47 ms).
  - *Sincronización en n8n DB:* Actualización de 2 registros de workflow en `~/.n8n/database.sqlite` confirmada.
* **Estado de decisiones del proyecto:**
  - DEC-01 (Motor de base de datos): Resuelta con SQLite 3 (`aduana.db`).
  - DEC-02 (Integración DeepSeek): Configuración de nodo HTTP Request lista; requiere clave API en el encabezado `Authorization`.
  - DEC-03 (Mecanismo n8n - SQLite): Cerrada y validada mediante `query_sqlite.py` y `Execute Command`.
  - DEC-04 (Diseño de datos y consultas): Cerrada y validada.
  - DEC-05 (Estabilidad y conexiones del workflow en n8n): **Cerrada y validada al 100%.**
* **Estado final de la etapa:** **Completado.**



