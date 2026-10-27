# DISEÑO DEL MODELO DE DATOS — SISTEMA DE INVENTARIO ADUANERO

**Laboratorio #3: Base de Datos Relacional y Automatización de Agente Aduanero**  
**Motor previsto:** MySQL 8.0.16+ / InnoDB (Juego de caracteres: `utf8mb4`, Collation: `utf8mb4_unicode_ci`)  
**Repositorio:** `sistema-de-inventario-aduana`  
**Estado:** Auditado, Corregido y Optimizado para Consultas Analíticas (Etapa 2.1)

---

## 1. Objetivo de la Base de Datos

El **Sistema de Inventario Aduanero** tiene como objetivo central estructurar, persistir y auditar con máxima integridad referencial todas las operaciones del despacho aduanero y control logístico en recintos fiscales. 

El modelo de datos está diseñado para dar respuesta operativa inmediata y servir como base de conocimiento analítica para un **Agente de Inteligencia Artificial (n8n + DeepSeek)**, permitiéndole responder preguntas complejas en lenguaje natural sobre:
- Localización y estado de mercancías retenidas o en custodia por bodega y país de origen.
- Trazabilidad y volúmenes de declaraciones aduaneras tramitadas por período y régimen.
- Control de contenedores según procedencia internacional y línea naviera.
- Fiscalización de importadores y exportadores según valores totales declarados (FOB/CIF) y tributos liquidados.
- Historial de inspecciones aduaneras, actas con observaciones e inspectores responsables.
- Saldos exactos de inventario físico disponible vs. retenido en la totalidad de bodegas.

---

## 2. Requisitos Utilizados y Supuestos de Diseño

### 2.1. Requisitos de Dominio Confirmados
1. Registro de actores del comercio exterior: importadores, exportadores y agentes aduanales habilitados.
2. Catálogos normalizados de origen internacional: países (estándar ISO) y clasificación arancelaria de mercancías (Sistema Armonizado / SAC).
3. Maestro de mercancías/productos clasificados técnica y arancelariamente.
4. Gestión de declaraciones aduaneras (DUA / Pedimento) con desglose detallado de partidas (líneas arancelarias) con cantidades y valores monetarios.
5. Control físico de unidades de transporte intermodal (contenedores) recibidos y despachados.
6. Custodia física en recintos aduaneros: bodegas diferenciadas y registro del inventario segregado por estado (disponible vs. retenido).
7. Bitácora de movimientos de almacén para auditoría de entradas, traslados, retenciones y despachos.
8. Registro de fiscalización: inspecciones aduaneras físicas y documentales (aforo verde, amarillo y rojo) con identificación del funcionario actuante y dictamen de observaciones.

### 2.2. Supuestos de Diseño Expresamente Identificados
- **Versión objetivo de MySQL (Supuesto Provisional):** Se adopta formalmente como versión objetivo **MySQL 8.0.16 o superior**.
  * *Justificación técnica:* Antes de la versión 8.0.16, MySQL aceptaba la sintaxis de restricciones `CHECK` pero las ignoraba silenciosamente en tiempo de ejecución. A partir de 8.0.16, las cláusulas `CHECK` son forzadas de manera estricta por el motor, lo que garantiza la prevención de saldos negativos sin depender de triggers externos. Si el entorno final usase MySQL 5.7 o MariaDB antiguo, se requerirá implementar triggers sustitutivos.
- **Moneda de referencia:** Los valores monetarios (`valor_total_cif`, `precio_unitario_fob`, `monto_arancel`) se asumen expresados en dólares estadounidenses (**USD**) para evitar distorsiones por tipos de cambio fluctuantes en la etapa analítica del agente de IA.
- **Régimen de contenedores:** Se modela la relación en la que una declaración aduanera puede asociarse directamente a un contenedor principal de arribo (`declaracion_aduanera.contenedor_id`), manteniendo el contenedor como entidad independiente para rastreo de procedencia portuaria.
- **Regla de inventario físico vs. documental:** El inventario no se deduce de forma estática sumando declaraciones; se materializa en una tabla transaccional `inventario` cuya conciliación y variación se audita mediante `movimiento_inventario`.
- **Selectivo de aforo (Semáforo aduanero):** Se asume la regla estándar de comercio exterior donde el canal se clasifica en:
  - `VERDE`: Levante automático (sin inspección física ni documental previa obligatoria).
  - `AMARILLO`: Revisión documental previa.
  - `ROJO`: Inspección física intrusiva obligatoria antes de autorizar el levante.

### 2.3. Clarificación de Relaciones Logísticas y Opcionalidades en Datos de Prueba
Para evitar confusiones entre restricciones del modelo relacional e instancias operativas del escenario aduanero, se documenta la justificación técnica de las siguientes relaciones opcionales (`NULL` permitido) presentes en `data.sql`:
1. **Contenedores sin Declaración (`contenedor` recibido sin asignar a `declaracion_aduanera`):**
   - En la operativa portuaria real, los buques desembarcan contenedores en el patio de maniobras portuario (`RECIBIDO_EN_PUERTO`) antes de que la agencia de aduanas radique la declaración aduanera definitiva. Por ello, es logísticamente consistente que existan contenedores registrados sin clave foránea dependiente en `declaracion_aduanera.contenedor_id` (ej. contenedores 3, 4 y 8 de prueba).
2. **Declaraciones sin Contenedor (`declaracion_aduanera.contenedor_id IS NULL`):**
   - El transporte internacional no es exclusivamente marítimo contenerizado. Operaciones aéreas, terrestres consolidadas o exportaciones de mercancía a granel / paletizada (ej. Declaración 5 de exportación de café) no utilizan contenedor marítimo, justificando que la columna admita `NULL`.
3. **Disparidad entre Bandera del Contenedor y Procedencia de la Carga:**
   - La tabla `contenedor.pais_origen_id` registra la matrícula, bandera o país de la línea naviera titular de la unidad de transporte (ej. Contenedor 6: naviera APL, EE. UU.), mientras que `declaracion_aduanera.pais_procedencia_id` registra el puerto internacional de embarque de la mercancía (ej. Japón en Declaración 3). En el transporte marítimo intermodal esto es estándar y representa fletes de armadores internacionales.
4. **Movimientos de Inventario sin DUA o sin Acta de Inspección:**
   - En `movimiento_inventario`, las columnas `declaracion_id` e `inspeccion_id` son opcionales (`NULL`). Operaciones como traslados logísticos entre bodegas, ajustes por merma física en manipulación (`AJUSTE_MERMA`), o recepciones de carga consolidadora no se originan forzosamente en un aforo físico ni requieren un acta judicial vinculada.
5. **Mercancías de Exportación sin Inventario en Bodegas Fiscales:**
   - Mercancías destinadas al régimen de exportación definitiva (ej. café de Producto 5) despachadas desde plantas agroindustriales directamente al muelle de embarque no ingresan a bodegas de depósito fiscal aduanero de importación, por lo que justificadamente no generan saldos en `inventario` ni movimientos en `movimiento_inventario`.

---

## 3. Justificación de Decisiones Técnicas Fundamentales

A continuación se fundamentan las decisiones de arquitectura y modelado revisadas tras la auditoría técnica:

### 3.1. Importadores y Exportadores: Entidad Unificada (`operador_comercial`)
* **Problema:** En el comercio internacional, una empresa puede actuar simultáneamente como importadora de materias primas y exportadora de productos manufacturados.
* **Solución adoptada:** Se implementó una tabla única `operador_comercial` con un campo discriminador `tipo_operador ENUM('IMPORTADOR', 'EXPORTADOR', 'AMBOS')`.
* **Justificación técnica:** 
  1. Evita duplicación de esquemas y de registros tributarios (mismo NIT / RUT / Cédula fiscal).
  2. Simplifica las relaciones de clave foránea en la tabla `declaracion_aduanera`, apuntando a un solo catálogo de entidades comerciales.
  3. Mantiene flexibilidad para consultas analíticas del tipo: *"¿Qué operadores importan y a la vez exportan?"*.

### 3.2. Relación Muchos a Muchos (N:M) entre Declaraciones y Productos
* **Problema:** Una declaración aduanera contiene múltiples productos con cantidades y precios distintos; asimismo, un mismo producto puede importarse en cientos de declaraciones diferentes a lo largo del tiempo.
* **Solución adoptada:** Se diseñó la tabla intermedia y asociativa `detalle_declaracion` (partida de declaración).
* **Justificación técnica:** Permite registrar atributos propios de cada transacción: número de línea o partida correlativa, cantidad declarada, unidad de medida específica, precio unitario FOB, valor total FOB, tasa arancelaria aplicada y arancel liquidado. Incorpora una restricción de unicidad compuesta `UNIQUE(declaracion_id, numero_linea)` que impide partidas duplicadas en un mismo documento aduanero.

### 3.3. Segregación entre Inventario Físico Real y Cantidad Declarada
* **Problema:** Confundir la cantidad documental estipulada en una factura de importación con el stock que realmente reposa en un pasillo o estante de una bodega aduanera provoca discrepancias graves de inventario (mermas, retenciones parciales o robos).
* **Solución adoptada:** La tabla `detalle_declaracion` registra la *intención legal y documental* declarada ante la aduana. Por separado, la tabla `inventario` almacena la existencia física real por `(bodega_id, producto_id)`, desglosando `cantidad_disponible` y `cantidad_retenida`.
* **Justificación técnica:** Permite responder con exactitud consultas de control como *"¿Cuánto inventario de China sigue retenido en la bodega 2?"* sin tener que recalcular ni depender del estado del trámite en la declaración.

### 3.4. Diferenciación de Estados (Declaración vs. Inventario vs. Inspección)
* **Problema:** Unificar estados en un único campo genera ambigüedad semántica (ej. decir que una mercancía está "aprobada" cuando el trámite está listo pero la bodega sigue bloqueada por inspección).
* **Solución adoptada:** Se desacoplaron 3 dimensiones de estado con dominios controlados (`ENUM`):
  1. `declaracion_aduanera.estado`: Estado legal del expediente administrativo (`REGISTRADA`, `EN_TRAMITE`, `EN_INSPECCION`, `AUTORIZADA`, `RETENIDA`, `CANCELADA`).
  2. `inventario.estado_inventario`: Estado físico del lote custodiado (`DISPONIBLE`, `RETENIDO_TOTAL`, `RETENIDO_PARCIAL`, `DECOMISADO`, `EN_CUARENTENA`).
  3. `inspeccion_aduanera.resultado`: Veredicto del oficial de aforo (`CONFORME_SIN_OBSERVACIONES`, `OBSERVACIONES_LEVES`, `RETENCION_PREVENTIVA`, `DECOMISO_MERCANCIA`, `RECHAZADO`).

### 3.5. Auditoría vs. Inmutabilidad en Movimientos de Inventario (`movimiento_inventario`)
* **Aclaración crítica de auditoría:** Un modelo de datos relacional no es inmutable por sí solo; una tabla es susceptible de modificación si el usuario de conexión posee permisos de mutación.
* **Solución adoptada:** 
  1. **Estructura lógica:** `movimiento_inventario` se diseña bajo el patrón de *registro de solo adición (append-only log)*.
  2. **Protección física en motor:** La inmutabilidad real se garantizará mediante la configuración de permisos (revocando `UPDATE` y `DELETE` para los usuarios operativos) y mediante un Trigger en MySQL (`BEFORE UPDATE` / `BEFORE DELETE`) que emita un `SIGNAL SQLSTATE '45000'` si se intenta modificar un registro histórico.
  3. **Blindaje referencial:** Las relaciones con `declaracion_aduanera` e `inspeccion_aduanera` se fijan con `ON DELETE RESTRICT` para evitar desvinculaciones por borrado cascada.

### 3.6. Matriz de Consistencia para Movimientos de Almacén y Efectos en Saldos
Para impedir registros ilógicos y garantizar la coherencia física de inventarios, se establecen reglas formales para cada tipo de movimiento:
1. `INGRESO_IMPORTACION`: La carga proviene del exterior. Requiere obligatoriamente `bodega_origen_id IS NULL` y `bodega_destino_id IS NOT NULL`. Efecto: incrementa `cantidad_disponible` en la bodega de destino.
2. `SALIDA_DESPACHO`: La carga sale definitivamente del recinto fiscal hacia levante nacional o exportación. Requiere obligatoriamente `bodega_origen_id IS NOT NULL` y `bodega_destino_id IS NULL`. Efecto: disminuye `cantidad_disponible` en la bodega de origen (requiere verificación transaccional de saldo suficiente).
3. `TRASLADO_ENTRE_BODEGAS`: Reubicación física entre depósitos aduaneros. Requiere `bodega_origen_id IS NOT NULL`, `bodega_destino_id IS NOT NULL` y `bodega_origen_id <> bodega_destino_id`. Efecto: disminuye `cantidad_disponible` en origen e incrementa en destino.
4. `BLOQUEO_RETENCION`: Medida cautelar por aforo o discrepancia. La mercancía permanece en la bodega de custodia (`bodega_origen_id IS NOT NULL`). Efecto: disminuye `cantidad_disponible` e incrementa `cantidad_retenida` en la misma bodega (`cantidad_total` no varía).
5. `LIBERACION_RETENCION`: Alzamiento de medida cautelar. Ocurre en la bodega de custodia (`bodega_origen_id IS NOT NULL`). Efecto: disminuye `cantidad_retenida` e incrementa `cantidad_disponible` en la misma bodega (`cantidad_total` no varía).
6. `AJUSTE_MERMA`: Pérdida, merma o daño físico comprobado en la bodega de custodia (`bodega_origen_id IS NOT NULL`). Efecto: disminuye `cantidad_disponible` (o retenida) y disminuye `cantidad_total`.
7. `DECOMISO`: Incautación o pérdida definitiva a favor del fisco en la bodega de custodia (`bodega_origen_id IS NOT NULL`). Efecto: disminuye `cantidad_retenida` (o disponible) y disminuye `cantidad_total` del stock comercial.

> **Distinción Crítica de Arquitectura:** Insertar una fila en `movimiento_inventario` **no** actualiza automáticamente las cantidades en la tabla `inventario`. Representa el libro diario (*audit log*). La actualización física del libro mayor (*stock balances*) debe ejecutarse mediante sentencias `UPDATE inventario` explícitas dentro de la misma transacción ACID (`START TRANSACTION ... COMMIT`) o mediante triggers dedicados.

### 3.7. Relaciones Recursivas Protegidas contra Ciclos
* Se incorporaron dos relaciones jerárquicas esenciales con protección explícita contra autoreferencias inmediatas:
  1. `categoria_arancelaria.categoria_padre_id`: Modela la jerarquía del Sistema Armonizado (Capítulo $\to$ Partida $\to$ Subpartida). Protegida con `CHECK (categoria_padre_id IS NULL OR categoria_padre_id <> id_categoria)`.
  2. `funcionario.supervisor_id`: Modela la cadena de mando aduanera. Protegida con `CHECK (supervisor_id IS NULL OR supervisor_id <> id_funcionario)`.

---

## 4. Normalización del Modelo Relacional

El modelo fue concebido aplicando rigurosamente las tres formas normales:

* **Primera Forma Normal (1FN):**
  - Todos los atributos contienen valores indivisibles (atómicos). No hay listas separadas por comas ni arreglos serializados dentro de celdas.
  - Cada registro posee una clave primaria única que lo identifica inequívocamente (`id_*`).

* **Segunda Forma Normal (2FN):**
  - Cumple 1FN.
  - En tablas con claves compuestas o intermedias (`detalle_declaracion`), ningún atributo no clave depende de un subconjunto de la clave primaria. El precio unitario, la cantidad y la tasa de arancel dependen del conjunto completo de la partida y declaración.

* **Tercera Forma Normal (3FN):**
  - Cumple 2FN.
  - No existen dependencias funcionales transitivas ($X \to Y \to Z$). Por ejemplo: la descripción arancelaria o la tasa no se almacenan en `producto` ni en `detalle_declaracion`, sino en `categoria_arancelaria`. El país del operador comercial no se repite en la declaración; se obtiene vinculando la tabla `operador_comercial` con `pais`.

---

## 5. Diccionario de Datos y Especificación de Tablas

### 5.1. Tabla: `pais`
* **Propósito:** Catálogo oficial de naciones soberanas para control de origen, procedencia y destino de embarques.
* **Motor:** InnoDB | **Collation:** utf8mb4_unicode_ci

| Columna | Tipo MySQL | Modificadores | Descripción y Restricciones |
| :--- | :--- | :--- | :--- |
| `id_pais` | `INT` | `AUTO_INCREMENT PK` | Identificador secuencial interno. |
| `codigo_alfa2` | `CHAR(2)` | `NOT NULL UNIQUE` | Código estándar ISO 3166-1 alpha-2 (ej. 'CN', 'US', 'CR'). |
| `codigo_alfa3` | `CHAR(3)` | `NOT NULL UNIQUE` | Código estándar ISO 3166-1 alpha-3 (ej. 'CHN', 'USA', 'CRI'). |
| `nombre` | `VARCHAR(100)` | `NOT NULL` | Nombre común oficial del país en español. |
| `region` | `VARCHAR(60)` | `NOT NULL` | Continente o bloque comercial (ej. 'Asia', 'América del Norte'). |

---

### 5.2. Tabla: `categoria_arancelaria`
* **Propósito:** Estructura jerárquica del Sistema Armonizado (SAC/HS) para clasificación impositiva de mercancías.

| Columna | Tipo MySQL | Modificadores | Descripción y Restricciones |
| :--- | :--- | :--- | :--- |
| `id_categoria` | `INT` | `AUTO_INCREMENT PK` | Identificador interno de categoría arancelaria. |
| `codigo_arancelario`| `VARCHAR(20)` | `NOT NULL UNIQUE` | Código arancelario oficial de 8 a 10 dígitos (ej. '8471.30.00'). |
| `descripcion` | `TEXT` | `NOT NULL` | Glosa descriptiva oficial de la partida o subpartida. |
| `porcentaje_arancel`| `DECIMAL(5,2)` | `NOT NULL DEFAULT 0.00`| Tasa del arancel ad-valorem (DAI), rango 0.00% a 100.00%. |
| `categoria_padre_id`| `INT` | `NULL FK` | Clave foránea recursiva a `categoria_arancelaria(id_categoria)`. |

* **Restricción de dominio anti-ciclo:** `CHECK (categoria_padre_id IS NULL OR categoria_padre_id <> id_categoria)`.
* **Relaciones:** `FK categoria_padre_id -> categoria_arancelaria(id_categoria) ON DELETE RESTRICT ON UPDATE CASCADE`.

---

### 5.3. Tabla: `producto`
* **Propósito:** Maestro de mercancías y bienes físicos sujetos a fiscalización y almacenamiento.

| Columna | Tipo MySQL | Modificadores | Descripción y Restricciones |
| :--- | :--- | :--- | :--- |
| `id_producto` | `INT` | `AUTO_INCREMENT PK` | Identificador numérico del producto. |
| `codigo_sku` | `VARCHAR(50)` | `NOT NULL UNIQUE` | Código de referencia o SKU comercial del fabricante. |
| `nombre` | `VARCHAR(150)` | `NOT NULL` | Denominación comercial o nombre del producto. |
| `descripcion` | `TEXT` | `NULL` | Ficha técnica o especificaciones del producto. |
| `categoria_arancelaria_id` | `INT` | `NOT NULL FK` | Vínculo a `categoria_arancelaria(id_categoria)`. |
| `unidad_medida` | `VARCHAR(20)` | `NOT NULL` | Unidad de embalaje/conteo ('UNIDADES', 'KG', 'LITROS', 'BULTOS'). |
| `pais_origen_id` | `INT` | `NOT NULL FK` | País donde fue fabricado o producido (`pais.id_pais`). |
| `precio_referencia` | `DECIMAL(12,2)` | `NOT NULL DEFAULT 0.00 CHECK (precio_referencia >= 0)` | Valor estimado de referencia en USD para aforo tributario. |

* **Relaciones:**
  - `FK categoria_arancelaria_id -> categoria_arancelaria(id_categoria) ON DELETE RESTRICT ON UPDATE CASCADE`.
  - `FK pais_origen_id -> pais(id_pais) ON DELETE RESTRICT ON UPDATE CASCADE`.
* **Índices de consulta:** `INDEX idx_producto_pais (pais_origen_id)`.

---

### 5.4. Tabla: `operador_comercial`
* **Propósito:** Registro maestro de empresas o personas jurídicas/físicas autorizadas para importar o exportar.

| Columna | Tipo MySQL | Modificadores | Descripción y Restricciones |
| :--- | :--- | :--- | :--- |
| `id_operador` | `INT` | `AUTO_INCREMENT PK` | Identificador único del operador. |
| `numero_identificacion` | `VARCHAR(30)` | `NOT NULL UNIQUE`| Cédula jurídica, RFC, RUC o NIT fiscal del operador. |
| `razon_social` | `VARCHAR(150)` | `NOT NULL` | Nombre legal societario registrado. |
| `nombre_comercial` | `VARCHAR(150)` | `NULL` | Nombre de fantasía o marca de operaciones. |
| `tipo_operador` | `ENUM` | `NOT NULL` | Valores válidos: `'IMPORTADOR'`, `'EXPORTADOR'`, `'AMBOS'`. |
| `direccion` | `TEXT` | `NOT NULL` | Domicilio legal o fiscal del operador. |
| `telefono` | `VARCHAR(25)` | `NULL` | Número de contacto directo. |
| `email` | `VARCHAR(100)` | `NOT NULL` | Correo oficial para notificaciones aduaneras. |
| `pais_id` | `INT` | `NOT NULL FK` | País sede de la empresa (`pais.id_pais`). |
| `estado` | `ENUM` | `NOT NULL DEFAULT 'ACTIVO'`| `'ACTIVO'`, `'INACTIVO'`, `'SUSPENDIDO'`. |

* **Relaciones:** `FK pais_id -> pais(id_pais) ON DELETE RESTRICT ON UPDATE CASCADE`.

---

### 5.5. Tabla: `agente_aduanero`
* **Propósito:** Agentes y agencias aduanales matriculadas y habilitadas legalmente ante la Dirección General de Aduanas.

| Columna | Tipo MySQL | Modificadores | Descripción y Restricciones |
| :--- | :--- | :--- | :--- |
| `id_agente` | `INT` | `AUTO_INCREMENT PK` | Identificador interno del agente aduanal. |
| `numero_licencia` | `VARCHAR(30)` | `NOT NULL UNIQUE` | Número de patente o registro aduanal habilitante. |
| `nombre_completo` | `VARCHAR(150)` | `NOT NULL` | Nombre completo del agente de aduana profesional. |
| `agencia` | `VARCHAR(150)` | `NOT NULL` | Razón social de la agencia aduanal a la que pertenece. |
| `telefono` | `VARCHAR(25)` | `NULL` | Teléfono corporativo. |
| `email` | `VARCHAR(100)` | `NOT NULL UNIQUE` | Correo profesional registrado ante la aduana. |
| `estado` | `ENUM` | `NOT NULL DEFAULT 'HABILITADO'` | `'HABILITADO'`, `'SUSPENDIDO'`, `'REVOCADO'`. |

---

### 5.6. Tabla: `funcionario`
* **Propósito:** Empleados y fiscalizadores de la autoridad aduanera (inspectores de aforo, jefes de recinto, auditores).

| Columna | Tipo MySQL | Modificadores | Descripción y Restricciones |
| :--- | :--- | :--- | :--- |
| `id_funcionario` | `INT` | `AUTO_INCREMENT PK` | Identificador único del funcionario. |
| `identificacion` | `VARCHAR(30)` | `NOT NULL UNIQUE` | Cédula institucional o código de empleado público. |
| `nombre_completo` | `VARCHAR(150)` | `NOT NULL` | Nombre y apellidos del funcionario aduanero. |
| `cargo` | `VARCHAR(100)` | `NOT NULL` | Puesto ('Inspector de Aforo', 'Jefe de Bodega', 'Auditor Fiscal'). |
| `departamento` | `VARCHAR(100)` | `NOT NULL` | Unidad operativa ('Fiscalización', 'Operaciones Portuarias'). |
| `email` | `VARCHAR(100)` | `NOT NULL UNIQUE` | Correo electrónico gubernamental/institucional. |
| `supervisor_id` | `INT` | `NULL FK` | Jerarquía institucional recursiva a `funcionario(id_funcionario)`. |
| `activo` | `BOOLEAN` | `NOT NULL DEFAULT TRUE` | Indicador de funcionario en servicio activo. |

* **Restricción de dominio anti-ciclo:** `CHECK (supervisor_id IS NULL OR supervisor_id <> id_funcionario)`.
* **Relaciones:** `FK supervisor_id -> funcionario(id_funcionario) ON DELETE SET NULL ON UPDATE CASCADE`.

---

### 5.7. Tabla: `bodega`
* **Propósito:** Almacenes, recintos cerrados o depósitos fiscales bajo control aduanero primario.

| Columna | Tipo MySQL | Modificadores | Descripción y Restricciones |
| :--- | :--- | :--- | :--- |
| `id_bodega` | `INT` | `AUTO_INCREMENT PK` | Identificador interno de la bodega. |
| `codigo_bodega` | `VARCHAR(20)` | `NOT NULL UNIQUE` | Código operativo alfanumérico (ej. 'BOD-01', 'BOD-02'). |
| `nombre` | `VARCHAR(100)` | `NOT NULL` | Nombre del almacén (ej. 'Bodega Central de Depósito 2'). |
| `tipo_bodega` | `ENUM` | `NOT NULL DEFAULT 'FISCAL'` | `'GENERAL'`, `'FISCAL'`, `'REFRIGERADA'`, `'VALORES'`, `'CUARENTENA'`. |
| `ubicacion` | `VARCHAR(200)` | `NOT NULL` | Muelle, terminal portuaria o coordenadas del recinto. |
| `capacidad_m3` | `DECIMAL(10,2)` | `NULL CHECK (capacidad_m3 > 0)`| Volumen máximo de almacenamiento cúbico. |
| `funcionario_responsable_id` | `INT` | `NOT NULL FK` | Funcionario encargado de la custodia (`funcionario.id_funcionario`). |
| `activo` | `BOOLEAN` | `NOT NULL DEFAULT TRUE` | Indicador de disponibilidad operativa de la bodega. |

* **Relaciones:** `FK funcionario_responsable_id -> funcionario(id_funcionario) ON DELETE RESTRICT ON UPDATE CASCADE`.

---

### 5.8. Tabla: `contenedor`
* **Propósito:** Registro y estado logístico de unidades de transporte de carga contenerizada.

| Columna | Tipo MySQL | Modificadores | Descripción y Restricciones |
| :--- | :--- | :--- | :--- |
| `id_contenedor` | `INT` | `AUTO_INCREMENT PK` | Identificador numérico del contenedor. |
| `numero_contenedor`| `VARCHAR(20)` | `NOT NULL UNIQUE` | Identificador internacional ISO 6346 (ej. 'MSCU7823419'). |
| `tipo_contenedor` | `ENUM` | `NOT NULL DEFAULT '40_DRY'` | `'20_DRY'`, `'40_DRY'`, `'40_HIGH_CUBE'`, `'REEFER'`, `'OPEN_TOP'`. |
| `tara_kg` | `DECIMAL(8,2)` | `NOT NULL CHECK (tara_kg > 0)` | Peso en vacío de la estructura del contenedor. |
| `peso_maximo_kg` | `DECIMAL(8,2)` | `NOT NULL CHECK (peso_maximo_kg > 0)` | Capacidad bruta de carga permitida. |
| (Restricción de relación) | `CHECK (peso_maximo_kg > tara_kg)` | | La capacidad bruta máxima debe superar la tara de la estructura. |
| `pais_origen_id` | `INT` | `NOT NULL FK` | País desde donde zarpó/embarcó el contenedor (`pais.id_pais`). |
| `linea_naviera` | `VARCHAR(100)` | `NOT NULL` | Empresa naviera o transportista (ej. 'Maersk', 'MSC', 'Cosco'). |
| `estado` | `ENUM` | `NOT NULL DEFAULT 'RECIBIDO_EN_PUERTO'` | `'EN_TRANSITO'`, `'RECIBIDO_EN_PUERTO'`, `'EN_INSPECCION'`, `'DESCONSOLIDADO'`, `'DESPACHADO'`, `'RETENIDO'`. |

* **Relaciones:** `FK pais_origen_id -> pais(id_pais) ON DELETE RESTRICT ON UPDATE CASCADE`.
* **Índices de consulta:** `INDEX idx_contenedor_estado_pais (estado, pais_origen_id)`.

---

### 5.9. Tabla: `declaracion_aduanera`
* **Propósito:** Documento legal central (DUA/Pedimento) que formaliza la solicitud de despacho y liquidación arancelaria.

| Columna | Tipo MySQL | Modificadores | Descripción y Restricciones |
| :--- | :--- | :--- | :--- |
| `id_declaracion` | `INT` | `AUTO_INCREMENT PK` | Identificador interno de la declaración. |
| `numero_declaracion`| `VARCHAR(35)` | `NOT NULL UNIQUE` | Número de expediente oficial (ej. 'DEC-2026-IMP-00042'). |
| `tipo_declaracion` | `ENUM` | `NOT NULL DEFAULT 'IMPORTACION'` | `'IMPORTACION'`, `'EXPORTACION'`, `'TRANSITO'`. |
| `regimen_aduanero` | `VARCHAR(50)` | `NOT NULL` | Modalidad aduanera ('Definitivo', 'Temporal', 'Depósito Fiscal'). |
| `fecha_registro` | `DATETIME` | `NOT NULL DEFAULT CURRENT_TIMESTAMP` | Fecha y hora de radicación ante el sistema aduanero. |
| `fecha_liquidacion` | `DATETIME` | `NULL` | Fecha y hora en que se pagaron tributos y autorizó levante. |
| `operador_comercial_id` | `INT` | `NOT NULL FK` | Sujeto declarante (`operador_comercial.id_operador`). |
| `agente_aduanero_id` | `INT` | `NOT NULL FK` | Agente apoderado que tramita (`agente_aduanero.id_agente`). |
| `pais_procedencia_id` | `INT` | `NOT NULL FK` | País desde donde partió la carga (`pais.id_pais`). |
| `pais_destino_id` | `INT` | `NOT NULL FK` | País receptor final de la carga (`pais.id_pais`). |
| `contenedor_id` | `INT` | `NULL FK` | Contenedor principal de transporte (`contenedor.id_contenedor`). |
| `canal_aforo` | `ENUM` | `NOT NULL DEFAULT 'VERDE'` | Canal de selectividad: `'VERDE'`, `'AMARILLO'`, `'ROJO'`. |
| `estado` | `ENUM` | `NOT NULL DEFAULT 'REGISTRADA'` | `'REGISTRADA'`, `'EN_TRAMITE'`, `'EN_INSPECCION'`, `'AUTORIZADA'`, `'RETENIDA'`, `'CANCELADA'`. |
| `valor_total_cif` | `DECIMAL(14,2)`| `NOT NULL DEFAULT 0.00 CHECK (valor_total_cif >= 0)` | Suma consolidada del valor Costo, Seguro y Flete en USD. |
| `total_tributos` | `DECIMAL(14,2)`| `NOT NULL DEFAULT 0.00 CHECK (total_tributos >= 0)` | Impuestos totales a pagar a la hacienda pública. |
| (Restricción temporal) | `CHECK (fecha_liquidacion IS NULL OR fecha_liquidacion >= fecha_registro)` | | La fecha de autorización de levante no puede preceder a la emisión. |

* **Relaciones:**
  - `FK operador_comercial_id -> operador_comercial(id_operador) ON DELETE RESTRICT ON UPDATE CASCADE`.
  - `FK agente_aduanero_id -> agente_aduanero(id_agente) ON DELETE RESTRICT ON UPDATE CASCADE`.
  - `FK pais_procedencia_id -> pais(id_pais) ON DELETE RESTRICT ON UPDATE CASCADE`.
  - `FK pais_destino_id -> pais(id_pais) ON DELETE RESTRICT ON UPDATE CASCADE`.
  - `FK contenedor_id -> contenedor(id_contenedor) ON DELETE SET NULL ON UPDATE CASCADE`.
* **Índices de consulta:** 
  - `INDEX idx_declaracion_tipo_fecha (tipo_declaracion, fecha_registro)` (optimiza conteos mensuales de importaciones).
  - `INDEX idx_declaracion_operador_valor (operador_comercial_id, valor_total_cif)` (optimiza rankings de importadores por valor).

---

### 5.10. Tabla: `detalle_declaracion`
* **Propósito:** Tabla asociativa e histórica que desglosa las líneas o partidas arancelarias de cada declaración aduanera (resolución de relación N:M).

| Columna | Tipo MySQL | Modificadores | Descripción y Restricciones |
| :--- | :--- | :--- | :--- |
| `id_detalle` | `INT` | `AUTO_INCREMENT PK` | Identificador de la partida. |
| `declaracion_id` | `INT` | `NOT NULL FK` | Vínculo a `declaracion_aduanera(id_declaracion)`. |
| `producto_id` | `INT` | `NOT NULL FK` | Mercancía declarada (`producto.id_producto`). |
| `numero_linea` | `INT` | `NOT NULL CHECK (numero_linea > 0)`| Número correlativo de partida (1, 2, 3...) dentro de la declaración. |
| `cantidad_declarada`| `DECIMAL(12,2)`| `NOT NULL CHECK (cantidad_declarada > 0)`| Unidades amparadas en factura de comercio exterior. |
| `unidad_medida` | `VARCHAR(20)` | `NOT NULL` | Unidad de medida aplicable. |
| `precio_unitario_fob`| `DECIMAL(12,2)`| `NOT NULL CHECK (precio_unitario_fob >= 0)` | Precio unitario Free on Board en USD. |
| `valor_total_fob` | `DECIMAL(14,2)`| `NOT NULL CHECK (valor_total_fob >= 0)` | Subtotal FOB de la partida (`cantidad_declarada * precio_unitario_fob`). |
| `tasa_arancelaria` | `DECIMAL(5,2)` | `NOT NULL DEFAULT 0.00 CHECK (tasa_arancelaria >= 0)` | Porcentaje de arancel específico liquidado para este ítem. |
| `monto_arancel` | `DECIMAL(12,2)`| `NOT NULL DEFAULT 0.00 CHECK (monto_arancel >= 0)` | Monto calculado de arancel por esta partida. |

* **Restricción de unicidad compuesta:** `UNIQUE KEY uk_declaracion_linea (declaracion_id, numero_linea)`.
* **Relaciones:**
  - `FK declaracion_id -> declaracion_aduanera(id_declaracion) ON DELETE CASCADE ON UPDATE CASCADE`.
  - `FK producto_id -> producto(id_producto) ON DELETE RESTRICT ON UPDATE CASCADE`.

---

### 5.11. Tabla: `inventario`
* **Propósito:** Existencias físicas reales de mercancías ubicadas dentro de cada bodega, distinguiendo disponibilidad de retención legal.

| Columna | Tipo MySQL | Modificadores | Descripción y Restricciones |
| :--- | :--- | :--- | :--- |
| `id_inventario` | `INT` | `AUTO_INCREMENT PK` | Identificador del registro de inventario. |
| `bodega_id` | `INT` | `NOT NULL FK` | Bodega física donde reposa la mercancía (`bodega.id_bodega`). |
| `producto_id` | `INT` | `NOT NULL FK` | Producto inventariado (`producto.id_producto`). |
| `cantidad_disponible`| `DECIMAL(12,2)`| `NOT NULL DEFAULT 0.00 CHECK (cantidad_disponible >= 0)` | Stock con autorización de salida y levante libre. |
| `cantidad_retenida` | `DECIMAL(12,2)`| `NOT NULL DEFAULT 0.00 CHECK (cantidad_retenida >= 0)` | Stock bajo medida cautelar, aforo rojo o discrepancia. |
| `cantidad_total` | `DECIMAL(12,2)`| `GENERATED ALWAYS AS (cantidad_disponible + cantidad_retenida) STORED` | Saldo físico total custodiado en la bodega. |
| `estado_inventario` | `ENUM` | `NOT NULL DEFAULT 'DISPONIBLE'` | `'DISPONIBLE'`, `'RETENIDO_TOTAL'`, `'RETENIDO_PARCIAL'`, `'DECOMISADO'`, `'EN_CUARENTENA'`. |
| `fecha_ultima_actualizacion`| `DATETIME` | `NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | Momento de última modificación o arqueo físico. |

* **Restricción de unicidad compuesta:** `UNIQUE KEY uk_bodega_producto (bodega_id, producto_id)`.
* **Relaciones:**
  - `FK bodega_id -> bodega(id_bodega) ON DELETE RESTRICT ON UPDATE CASCADE`.
  - `FK producto_id -> producto(id_producto) ON DELETE RESTRICT ON UPDATE CASCADE`.
* **Índices de consulta:**
  - `INDEX idx_inventario_producto (producto_id)` (vital para la consulta *"¿Cuánto inventario queda de un producto en todas las bodegas?"* evitando escaneo completo de tabla).
  - `INDEX idx_inventario_bodega_retenido (bodega_id, cantidad_retenida)` (vital para la consulta *"¿Qué mercancías de China siguen retenidas en la bodega 2?"*).

---

### 5.12. Tabla: `movimiento_inventario`
* **Propósito:** Registro histórico y trazabilidad de operaciones físicas de almacén. Funciona como bitácora de solo adición (*append-only*).

| Columna | Tipo MySQL | Modificadores | Descripción y Restricciones |
| :--- | :--- | :--- | :--- |
| `id_movimiento` | `INT` | `AUTO_INCREMENT PK` | Identificador único de transacción. |
| `tipo_movimiento` | `ENUM` | `NOT NULL` | `'INGRESO_IMPORTACION'`, `'SALIDA_DESPACHO'`, `'TRASLADO_ENTRE_BODEGAS'`, `'BLOQUEO_RETENCION'`, `'LIBERACION_RETENCION'`, `'AJUSTE_MERMA'`, `'DECOMISO'`. |
| `producto_id` | `INT` | `NOT NULL FK` | Producto objeto de la operación (`producto.id_producto`). |
| `bodega_origen_id` | `INT` | `NULL FK` | Bodega emisora (NULL en arribo exterior). |
| `bodega_destino_id`| `INT` | `NULL FK` | Bodega receptora (NULL en levante y salida final). |
| `cantidad` | `DECIMAL(12,2)`| `NOT NULL CHECK (cantidad > 0)` | Cantidad transferida o ajustada. |
| `fecha_movimiento` | `DATETIME` | `NOT NULL DEFAULT CURRENT_TIMESTAMP` | Fecha y hora exacta de ejecución. |
| `declaracion_id` | `INT` | `NULL FK` | Declaración de origen o trámite (`declaracion_aduanera.id_declaracion`). |
| `inspeccion_id` | `INT` | `NULL FK` | Acta de inspección que motivó la retención/ajuste (`inspeccion_aduanera.id_inspeccion`). |
| `funcionario_id` | `INT` | `NOT NULL FK` | Funcionario aduanero que fiscalizó/autorizó el movimiento. |
| `motivo` | `TEXT` | `NOT NULL` | Justificación técnica, folio o causa del movimiento. |

* **Restricciones de consistencia de bodegas:**
  - `CHECK (tipo_movimiento <> 'TRASLADO_ENTRE_BODEGAS' OR (bodega_origen_id IS NOT NULL AND bodega_destino_id IS NOT NULL AND bodega_origen_id <> bodega_destino_id))`
  - `CHECK (tipo_movimiento <> 'INGRESO_IMPORTACION' OR bodega_destino_id IS NOT NULL)`
  - `CHECK (tipo_movimiento <> 'SALIDA_DESPACHO' OR bodega_origen_id IS NOT NULL)`
  - `CHECK (tipo_movimiento NOT IN ('BLOQUEO_RETENCION', 'LIBERACION_RETENCION', 'AJUSTE_MERMA', 'DECOMISO') OR (bodega_origen_id IS NOT NULL AND bodega_destino_id IS NULL))`
* **Relaciones con protección de trazabilidad:**
  - `FK producto_id -> producto(id_producto) ON DELETE RESTRICT ON UPDATE CASCADE`.
  - `FK bodega_origen_id -> bodega(id_bodega) ON DELETE RESTRICT ON UPDATE CASCADE`.
  - `FK bodega_destino_id -> bodega(id_bodega) ON DELETE RESTRICT ON UPDATE CASCADE`.
  - `FK declaracion_id -> declaracion_aduanera(id_declaracion) ON DELETE RESTRICT ON UPDATE CASCADE`.
  - `FK inspeccion_id -> inspeccion_aduanera(id_inspeccion) ON DELETE RESTRICT ON UPDATE CASCADE`.
  - `FK funcionario_id -> funcionario(id_funcionario) ON DELETE RESTRICT ON UPDATE CASCADE`.

---

### 5.13. Tabla: `inspeccion_aduanera`
* **Propósito:** Registro detallado de revisiones físicas (canal rojo) y documentales (canal amarillo) ejecutadas por la fiscalización aduanera.

| Columna | Tipo MySQL | Modificadores | Descripción y Restricciones |
| :--- | :--- | :--- | :--- |
| `id_inspeccion` | `INT` | `AUTO_INCREMENT PK` | Identificador de la inspección. |
| `numero_acta` | `VARCHAR(35)` | `NOT NULL UNIQUE` | Folio oficial del acta de aforo (ej. 'ACTA-INSP-2026-0089'). |
| `declaracion_id` | `INT` | `NOT NULL FK` | Declaración sometida a revisión (`declaracion_aduanera.id_declaracion`). |
| `funcionario_id` | `INT` | `NOT NULL FK` | Inspector oficial actuante (`funcionario.id_funcionario`). |
| `fecha_inspeccion` | `DATETIME` | `NOT NULL DEFAULT CURRENT_TIMESTAMP` | Momento en que se practicó el reconocimiento. |
| `tipo_inspeccion` | `ENUM` | `NOT NULL` | `'FISICA_INTRUSIVA'`, `'DOCUMENTAL'`, `'SCANNER_NO_INTRUSIVO'`, `'ALEATORIA'`. |
| `resultado` | `ENUM` | `NOT NULL` | `'CONFORME_SIN_OBSERVACIONES'`, `'OBSERVACIONES_LEVES'`, `'RETENCION_PREVENTIVA'`, `'DECOMISO_MERCANCIA'`, `'RECHAZADO'`. |
| `tuvo_observaciones`| `BOOLEAN` | `NOT NULL DEFAULT FALSE` | Bandera booleana para indexación ágil de actas con incidencias. |
| `observaciones` | `TEXT` | `NULL` | Glosa con hallazgos (ej. 'Discrepancia en peso', 'Falta de certificado'). |
| `acciones_tomadas` | `TEXT` | `NULL` | Medidas ordenadas (ej. 'Retención en Bodega 2', 'Reavalúo'). |

* **Relaciones:**
  - `FK declaracion_id -> declaracion_aduanera(id_declaracion) ON DELETE RESTRICT ON UPDATE CASCADE`.
  - `FK funcionario_id -> funcionario(id_funcionario) ON DELETE RESTRICT ON UPDATE CASCADE`.
* **Índices de consulta:**
  - `INDEX idx_inspeccion_observaciones_func (tuvo_observaciones, funcionario_id)` (vital para la consulta *"¿Qué inspecciones tuvieron observaciones y quién las realizó?"*).

---

## 6. Reglas de Integridad Referencial y de Negocio

1. **Integridad de Claves Primarias:** Todas las tablas utilizan enteros con incremento automático (`AUTO_INCREMENT`) como clave primaria técnica (surrogate key) para optimizar el árbol B+ en índices de MySQL InnoDB, complementados con índices únicos (`UNIQUE`) en los códigos de negocio naturales (`numero_declaracion`, `codigo_sku`, `numero_contenedor`, `numero_licencia`, `identificacion`, `numero_acta`, `codigo_alfa2`).
2. **Acciones en Cascada Restringidas (`ON DELETE RESTRICT`):** No se permite eliminar un país, una categoría arancelaria, un operador comercial, una bodega, un funcionario, una declaración con movimientos o un acta de inspección con movimientos si existen registros dependientes vinculados.
3. **Cascada Permitida en Detalle (`ON DELETE CASCADE`):** Si una declaración en estado borrador o cancelada es eliminada legalmente de la base de datos, sus partidas en `detalle_declaracion` se purgan automáticamente para evitar registros huérfanos.
4. **Desvinculación Nula Opcional (`ON DELETE SET NULL`):** Únicamente en relaciones puramente organizacionales no forenses:
   - `declaracion_aduanera.contenedor_id`: Si se retira un contenedor del catálogo general.
   - `funcionario.supervisor_id`: Si un supervisor es dado de baja institucionalmente, los empleados subordinados no se eliminan, sino que su supervisor pasa a `NULL`.
5. **Restricciones de Dominio y Verificación (`CHECK`):**
   - Cantidades físicas y precios deben ser estrictamente positivos o cero según corresponda (`CHECK (cantidad_declarada > 0)`, `CHECK (precio_unitario_fob >= 0)`, `CHECK (cantidad_disponible >= 0)`).
   - El inventario total almacenado corresponde a la suma de disponible y retenido (`GENERATED ALWAYS AS (cantidad_disponible + cantidad_retenida) STORED`).
   - Validación cruzada de bodegas en traslados para impedir saldos fantasmas o autoreferencias de bodega.

---

## 7. Decisiones Pendientes (Control de Estado Actualizado)

| # | Decisión / Parámetro | Estado | Motivo de Importancia | Opciones Analizadas | Decisión Técnica Tomada / Plan de Acción | Etapa Límite de Resolución |
| :- | :--- | :--- | :--- | :--- | :--- | :--- |
| **DEC-01** | **Disponibilidad de MySQL Server** | **En verificación** | Requerido para desplegar el DDL y ejecutar consultas reales. | 1. Instalación local de MySQL Community Server.<br>2. XAMPP/WAMP local.<br>3. Instancia remota/Docker. | Se confirmó que no hay binarios de MySQL en PATH ni servicio activo. Se requiere coordinar con el usuario la instalación de MySQL Server o provisión de host antes de ejecutar SQL. | Previo a Etapa 3 (Creación de tablas SQL). |
| **DEC-02** | **Acceso y Credencial de DeepSeek** | **Pendiente** | Requerido para que el Agente en n8n responda en lenguaje natural. | 1. API directa de DeepSeek (`https://api.deepseek.com`).<br>2. Modelo local vía Ollama. | Utilizar el nodo nativo OpenAI-compatible en n8n apuntando a la URL base de DeepSeek con API Key sin exponerla en código. | Etapa 7 (Configuración del agente n8n). |
| **DEC-03** | **Conexión n8n con MySQL** | **Pendiente** | Puente entre el flujo de automatización y los datos. | 1. Usuario con permisos totales.<br>2. Usuario exclusivo de solo lectura (`SELECT`). | Se creará un usuario `n8n_readonly` con privilegios mínimos para prevenir SQL Injection o mutaciones accidentales desde el LLM. | Etapa 6 (Usuario de solo lectura). |
| **DEC-04** | **Requisitos y Refinamiento del Modelo** | **Resuelta** | Asegurar que el diseño soporte todas las preguntas del laboratorio sin tablas redundantes ni fallas de integridad. | Modelo base inicial vs. Modelo auditado con índices analíticos y reglas anti-ciclo. | Se blindó el modelo de 13 entidades normalizadas (3FN) con índices específicos para las 6 preguntas de IA, restricciones contra ciclos y matriz de bodegas. | Resuelta en Etapa 2.1. |

---

## 8. Limitaciones Conocidas y Recomendaciones para la Siguiente Etapa

1. **Supuesto de MySQL 8.0.16+:** Las restricciones `CHECK` documentadas son nativas y activas en MySQL 8.0.16+. Si al instalar o conectar MySQL se utilizase una versión anterior (MySQL 5.7 o MariaDB antiguo), el script `schema.sql` deberá complementarse con triggers para salvaguardar la no negatividad de los inventarios.
2. **Generación gráfica del DER:** El diagrama se entrega en sintaxis pura Mermaid (`DER_ADUANA.mmd`). Al no contar con herramientas de compilación gráfica instaladas en el sistema local, se documenta la visualización mediante visores Markdown y herramientas web.
3. **Recomendación para Etapa 3 (DDL):** Crear el archivo `schema.sql` integrando formalmente los índices analíticos diseñados (`idx_inventario_producto`, `idx_inventario_bodega_retenido`, `idx_declaracion_tipo_fecha`, `idx_contenedor_estado_pais`, etc.) para garantizar tiempos de respuesta subsegundo al agente n8n.
