-- =====================================================================
-- SISTEMA DE INVENTARIO ADUANERO — LABORATORIO #3
-- SCRIPT DDL: CREACION DE ESTRUCTURA RELACIONAL PARA SQLITE (schema_sqlite.sql)
-- Motor objetivo: SQLite 3.31.0+ (Soporte de STORED Generated Columns y Window Functions)
-- Modo de integridad referencial: PRAGMA foreign_keys = ON;
-- =====================================================================

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------
-- 1. TABLA: pais
-- Catalogo maestro de naciones soberanas para origen, procedencia y destino
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS pais;
CREATE TABLE pais (
  id_pais INTEGER PRIMARY KEY AUTOINCREMENT,
  codigo_alfa2 TEXT NOT NULL,
  codigo_alfa3 TEXT NOT NULL,
  nombre TEXT NOT NULL,
  region TEXT NOT NULL,
  CONSTRAINT uk_pais_codigo_alfa2 UNIQUE (codigo_alfa2),
  CONSTRAINT uk_pais_codigo_alfa3 UNIQUE (codigo_alfa3)
);

-- ---------------------------------------------------------------------
-- 2. TABLA: categoria_arancelaria
-- Estructura jerarquica arancelaria del Sistema Armonizado (SAC/HS)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS categoria_arancelaria;
CREATE TABLE categoria_arancelaria (
  id_categoria INTEGER PRIMARY KEY AUTOINCREMENT,
  codigo_arancelario TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  porcentaje_arancel NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  categoria_padre_id INTEGER NULL,
  CONSTRAINT uk_categoria_codigo UNIQUE (codigo_arancelario),
  CONSTRAINT fk_categoria_padre FOREIGN KEY (categoria_padre_id)
    REFERENCES categoria_arancelaria(id_categoria)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_categoria_padre_anticiclo CHECK (categoria_padre_id IS NULL OR categoria_padre_id <> id_categoria),
  CONSTRAINT chk_porcentaje_arancel CHECK (porcentaje_arancel >= 0 AND porcentaje_arancel <= 100)
);

-- ---------------------------------------------------------------------
-- 3. TABLA: operador_comercial
-- Entidades comerciales unificadas (importadores, exportadores o ambos)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS operador_comercial;
CREATE TABLE operador_comercial (
  id_operador INTEGER PRIMARY KEY AUTOINCREMENT,
  numero_identificacion TEXT NOT NULL,
  razon_social TEXT NOT NULL,
  nombre_comercial TEXT NULL,
  tipo_operador TEXT NOT NULL DEFAULT 'IMPORTADOR' CHECK (tipo_operador IN ('IMPORTADOR', 'EXPORTADOR', 'AMBOS')),
  direccion TEXT NOT NULL,
  telefono TEXT NULL,
  email TEXT NOT NULL,
  pais_id INTEGER NOT NULL,
  estado TEXT NOT NULL DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO', 'SUSPENDIDO')),
  CONSTRAINT uk_operador_identificacion UNIQUE (numero_identificacion),
  CONSTRAINT fk_operador_pais FOREIGN KEY (pais_id)
    REFERENCES pais(id_pais)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- 4. TABLA: agente_aduanero
-- Agentes y agencias aduanales legalmente habilitadas
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS agente_aduanero;
CREATE TABLE agente_aduanero (
  id_agente INTEGER PRIMARY KEY AUTOINCREMENT,
  numero_licencia TEXT NOT NULL,
  nombre_completo TEXT NOT NULL,
  agencia TEXT NOT NULL,
  telefono TEXT NULL,
  email TEXT NOT NULL,
  estado TEXT NOT NULL DEFAULT 'HABILITADO' CHECK (estado IN ('HABILITADO', 'SUSPENDIDO', 'REVOCADO')),
  CONSTRAINT uk_agente_licencia UNIQUE (numero_licencia),
  CONSTRAINT uk_agente_email UNIQUE (email)
);

-- ---------------------------------------------------------------------
-- 5. TABLA: funcionario
-- Personal oficial de la autoridad aduanera (inspectores, aforadores, custodios)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS funcionario;
CREATE TABLE funcionario (
  id_funcionario INTEGER PRIMARY KEY AUTOINCREMENT,
  identificacion TEXT NOT NULL,
  nombre_completo TEXT NOT NULL,
  cargo TEXT NOT NULL,
  departamento TEXT NOT NULL,
  email TEXT NOT NULL,
  supervisor_id INTEGER NULL,
  activo INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1)),
  CONSTRAINT uk_funcionario_identificacion UNIQUE (identificacion),
  CONSTRAINT uk_funcionario_email UNIQUE (email),
  CONSTRAINT fk_funcionario_supervisor FOREIGN KEY (supervisor_id)
    REFERENCES funcionario(id_funcionario)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT chk_funcionario_supervisor_anticiclo CHECK (supervisor_id IS NULL OR supervisor_id <> id_funcionario)
);

-- ---------------------------------------------------------------------
-- 6. TABLA: bodega
-- Almacenes y depositos fiscales bajo control primario aduanero
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS bodega;
CREATE TABLE bodega (
  id_bodega INTEGER PRIMARY KEY AUTOINCREMENT,
  codigo_bodega TEXT NOT NULL,
  nombre TEXT NOT NULL,
  tipo_bodega TEXT NOT NULL DEFAULT 'FISCAL' CHECK (tipo_bodega IN ('GENERAL', 'FISCAL', 'REFRIGERADA', 'VALORES', 'CUARENTENA')),
  ubicacion TEXT NOT NULL,
  capacidad_m3 NUMERIC(10,2) NULL,
  funcionario_responsable_id INTEGER NOT NULL,
  activo INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1)),
  CONSTRAINT uk_bodega_codigo UNIQUE (codigo_bodega),
  CONSTRAINT fk_bodega_funcionario FOREIGN KEY (funcionario_responsable_id)
    REFERENCES funcionario(id_funcionario)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_bodega_capacidad CHECK (capacidad_m3 IS NULL OR capacidad_m3 > 0)
);

-- ---------------------------------------------------------------------
-- 7. TABLA: contenedor
-- Unidades intermodales de transporte maritimo y terrestre (ISO 6346)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS contenedor;
CREATE TABLE contenedor (
  id_contenedor INTEGER PRIMARY KEY AUTOINCREMENT,
  numero_contenedor TEXT NOT NULL,
  tipo_contenedor TEXT NOT NULL DEFAULT '40_DRY' CHECK (tipo_contenedor IN ('20_DRY', '40_DRY', '40_HIGH_CUBE', 'REEFER', 'OPEN_TOP')),
  tara_kg NUMERIC(8,2) NOT NULL,
  peso_maximo_kg NUMERIC(8,2) NOT NULL,
  pais_origen_id INTEGER NOT NULL,
  linea_naviera TEXT NOT NULL,
  estado TEXT NOT NULL DEFAULT 'RECIBIDO_EN_PUERTO' CHECK (estado IN ('EN_TRANSITO', 'RECIBIDO_EN_PUERTO', 'EN_INSPECCION', 'DESCONSOLIDADO', 'DESPACHADO', 'RETENIDO')),
  CONSTRAINT uk_contenedor_numero UNIQUE (numero_contenedor),
  CONSTRAINT fk_contenedor_pais FOREIGN KEY (pais_origen_id)
    REFERENCES pais(id_pais)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_contenedor_tara CHECK (tara_kg > 0),
  CONSTRAINT chk_contenedor_peso_max CHECK (peso_maximo_kg > 0),
  CONSTRAINT chk_contenedor_peso_rel CHECK (peso_maximo_kg > tara_kg)
);
CREATE INDEX idx_contenedor_estado_pais ON contenedor (estado, pais_origen_id);

-- ---------------------------------------------------------------------
-- 8. TABLA: producto
-- Catalogo maestro de mercancias sujetas a aforo y almacenamiento
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS producto;
CREATE TABLE producto (
  id_producto INTEGER PRIMARY KEY AUTOINCREMENT,
  codigo_sku TEXT NOT NULL,
  nombre TEXT NOT NULL,
  descripcion TEXT NULL,
  categoria_arancelaria_id INTEGER NOT NULL,
  unidad_medida TEXT NOT NULL,
  pais_origen_id INTEGER NOT NULL,
  precio_referencia NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  CONSTRAINT uk_producto_sku UNIQUE (codigo_sku),
  CONSTRAINT fk_producto_categoria FOREIGN KEY (categoria_arancelaria_id)
    REFERENCES categoria_arancelaria(id_categoria)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_producto_pais FOREIGN KEY (pais_origen_id)
    REFERENCES pais(id_pais)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_producto_precio_ref CHECK (precio_referencia >= 0)
);
CREATE INDEX idx_producto_pais ON producto (pais_origen_id);

-- ---------------------------------------------------------------------
-- 9. TABLA: declaracion_aduanera
-- Expediente central de importacion, exportacion o transito (DUA/Pedimento)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS declaracion_aduanera;
CREATE TABLE declaracion_aduanera (
  id_declaracion INTEGER PRIMARY KEY AUTOINCREMENT,
  numero_declaracion TEXT NOT NULL,
  tipo_declaracion TEXT NOT NULL DEFAULT 'IMPORTACION' CHECK (tipo_declaracion IN ('IMPORTACION', 'EXPORTACION', 'TRANSITO')),
  regimen_aduanero TEXT NOT NULL,
  fecha_registro TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
  fecha_liquidacion TEXT NULL,
  operador_comercial_id INTEGER NOT NULL,
  agente_aduanero_id INTEGER NOT NULL,
  pais_procedencia_id INTEGER NOT NULL,
  pais_destino_id INTEGER NOT NULL,
  contenedor_id INTEGER NULL,
  canal_aforo TEXT NOT NULL DEFAULT 'VERDE' CHECK (canal_aforo IN ('VERDE', 'AMARILLO', 'ROJO')),
  estado TEXT NOT NULL DEFAULT 'REGISTRADA' CHECK (estado IN ('REGISTRADA', 'EN_TRAMITE', 'EN_INSPECCION', 'AUTORIZADA', 'RETENIDA', 'CANCELADA')),
  valor_total_cif NUMERIC(14,2) NOT NULL DEFAULT 0.00,
  total_tributos NUMERIC(14,2) NOT NULL DEFAULT 0.00,
  CONSTRAINT uk_declaracion_numero UNIQUE (numero_declaracion),
  CONSTRAINT fk_declaracion_operador FOREIGN KEY (operador_comercial_id)
    REFERENCES operador_comercial(id_operador)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_declaracion_agente FOREIGN KEY (agente_aduanero_id)
    REFERENCES agente_aduanero(id_agente)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_declaracion_pais_proc FOREIGN KEY (pais_procedencia_id)
    REFERENCES pais(id_pais)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_declaracion_pais_dest FOREIGN KEY (pais_destino_id)
    REFERENCES pais(id_pais)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_declaracion_contenedor FOREIGN KEY (contenedor_id)
    REFERENCES contenedor(id_contenedor)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT chk_declaracion_valor_cif CHECK (valor_total_cif >= 0),
  CONSTRAINT chk_declaracion_total_tributos CHECK (total_tributos >= 0),
  CONSTRAINT chk_declaracion_fechas CHECK (fecha_liquidacion IS NULL OR fecha_liquidacion >= fecha_registro)
);
CREATE INDEX idx_declaracion_tipo_fecha ON declaracion_aduanera (tipo_declaracion, fecha_registro);
CREATE INDEX idx_declaracion_operador_valor ON declaracion_aduanera (operador_comercial_id, valor_total_cif);

-- ---------------------------------------------------------------------
-- 10. TABLA: detalle_declaracion
-- Partidas arancelarias individuales por declaracion (Resolucion N:M)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS detalle_declaracion;
CREATE TABLE detalle_declaracion (
  id_detalle INTEGER PRIMARY KEY AUTOINCREMENT,
  declaracion_id INTEGER NOT NULL,
  producto_id INTEGER NOT NULL,
  numero_linea INTEGER NOT NULL,
  cantidad_declarada NUMERIC(12,2) NOT NULL,
  unidad_medida TEXT NOT NULL,
  precio_unitario_fob NUMERIC(12,2) NOT NULL,
  valor_total_fob NUMERIC(14,2) NOT NULL,
  tasa_arancelaria NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  monto_arancel NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  CONSTRAINT uk_declaracion_linea UNIQUE (declaracion_id, numero_linea),
  CONSTRAINT fk_detalle_declaracion FOREIGN KEY (declaracion_id)
    REFERENCES declaracion_aduanera(id_declaracion)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_detalle_producto FOREIGN KEY (producto_id)
    REFERENCES producto(id_producto)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_detalle_linea CHECK (numero_linea > 0),
  CONSTRAINT chk_detalle_cantidad CHECK (cantidad_declarada > 0),
  CONSTRAINT chk_detalle_precio_fob CHECK (precio_unitario_fob >= 0),
  CONSTRAINT chk_detalle_valor_fob CHECK (valor_total_fob >= 0),
  CONSTRAINT chk_detalle_tasa_arancel CHECK (tasa_arancelaria >= 0 AND tasa_arancelaria <= 100),
  CONSTRAINT chk_detalle_monto_arancel CHECK (monto_arancel >= 0)
);

-- ---------------------------------------------------------------------
-- 11. TABLA: inventario
-- Saldo fisico actual custodiado en bodega (Disponible vs Retenido)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS inventario;
CREATE TABLE inventario (
  id_inventario INTEGER PRIMARY KEY AUTOINCREMENT,
  bodega_id INTEGER NOT NULL,
  producto_id INTEGER NOT NULL,
  cantidad_disponible NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  cantidad_retenida NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  cantidad_total NUMERIC(12,2) GENERATED ALWAYS AS (cantidad_disponible + cantidad_retenida) STORED,
  estado_inventario TEXT NOT NULL DEFAULT 'DISPONIBLE' CHECK (estado_inventario IN ('DISPONIBLE', 'RETENIDO_TOTAL', 'RETENIDO_PARCIAL', 'DECOMISADO', 'EN_CUARENTENA')),
  fecha_ultima_actualizacion TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
  CONSTRAINT uk_bodega_producto UNIQUE (bodega_id, producto_id),
  CONSTRAINT fk_inventario_bodega FOREIGN KEY (bodega_id)
    REFERENCES bodega(id_bodega)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_inventario_producto FOREIGN KEY (producto_id)
    REFERENCES producto(id_producto)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_inventario_cant_disp CHECK (cantidad_disponible >= 0),
  CONSTRAINT chk_inventario_cant_ret CHECK (cantidad_retenida >= 0)
);
CREATE INDEX idx_inventario_producto ON inventario (producto_id);
CREATE INDEX idx_inventario_bodega_retenido ON inventario (bodega_id, cantidad_retenida);

-- Trigger para mantener actualizada fecha_ultima_actualizacion al modificar inventario
CREATE TRIGGER trg_inventario_actualizacion
AFTER UPDATE ON inventario
FOR EACH ROW
BEGIN
  UPDATE inventario
  SET fecha_ultima_actualizacion = datetime('now', 'localtime')
  WHERE id_inventario = OLD.id_inventario;
END;

-- ---------------------------------------------------------------------
-- 12. TABLA: inspeccion_aduanera
-- Actas de aforo fisico intrusivo o revision documental
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS inspeccion_aduanera;
CREATE TABLE inspeccion_aduanera (
  id_inspeccion INTEGER PRIMARY KEY AUTOINCREMENT,
  numero_acta TEXT NOT NULL,
  declaracion_id INTEGER NOT NULL,
  funcionario_id INTEGER NOT NULL,
  fecha_inspeccion TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
  tipo_inspeccion TEXT NOT NULL CHECK (tipo_inspeccion IN ('FISICA_INTRUSIVA', 'DOCUMENTAL', 'SCANNER_NO_INTRUSIVO', 'ALEATORIA')),
  resultado TEXT NOT NULL CHECK (resultado IN ('CONFORME_SIN_OBSERVACIONES', 'OBSERVACIONES_LEVES', 'RETENCION_PREVENTIVA', 'DECOMISO_MERCANCIA', 'RECHAZADO')),
  tuvo_observaciones INTEGER NOT NULL DEFAULT 0 CHECK (tuvo_observaciones IN (0, 1)),
  observaciones TEXT NULL,
  acciones_tomadas TEXT NULL,
  CONSTRAINT uk_inspeccion_acta UNIQUE (numero_acta),
  CONSTRAINT fk_inspeccion_declaracion FOREIGN KEY (declaracion_id)
    REFERENCES declaracion_aduanera(id_declaracion)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_inspeccion_funcionario FOREIGN KEY (funcionario_id)
    REFERENCES funcionario(id_funcionario)
    ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE INDEX idx_inspeccion_observaciones_func ON inspeccion_aduanera (tuvo_observaciones, funcionario_id);

-- ---------------------------------------------------------------------
-- 13. TABLA: movimiento_inventario
-- Registro historico de auditoria fisica de operaciones de almacen
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS movimiento_inventario;
CREATE TABLE movimiento_inventario (
  id_movimiento INTEGER PRIMARY KEY AUTOINCREMENT,
  tipo_movimiento TEXT NOT NULL CHECK (tipo_movimiento IN ('INGRESO_IMPORTACION', 'SALIDA_DESPACHO', 'TRASLADO_ENTRE_BODEGAS', 'BLOQUEO_RETENCION', 'LIBERACION_RETENCION', 'AJUSTE_MERMA', 'DECOMISO')),
  producto_id INTEGER NOT NULL,
  bodega_origen_id INTEGER NULL,
  bodega_destino_id INTEGER NULL,
  cantidad NUMERIC(12,2) NOT NULL,
  fecha_movimiento TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
  declaracion_id INTEGER NULL,
  inspeccion_id INTEGER NULL,
  funcionario_id INTEGER NOT NULL,
  motivo TEXT NOT NULL,
  CONSTRAINT fk_movimiento_producto FOREIGN KEY (producto_id)
    REFERENCES producto(id_producto)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_movimiento_bodega_origen FOREIGN KEY (bodega_origen_id)
    REFERENCES bodega(id_bodega)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_movimiento_bodega_destino FOREIGN KEY (bodega_destino_id)
    REFERENCES bodega(id_bodega)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_movimiento_declaracion FOREIGN KEY (declaracion_id)
    REFERENCES declaracion_aduanera(id_declaracion)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_movimiento_inspeccion FOREIGN KEY (inspeccion_id)
    REFERENCES inspeccion_aduanera(id_inspeccion)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_movimiento_funcionario FOREIGN KEY (funcionario_id)
    REFERENCES funcionario(id_funcionario)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_movimiento_cantidad CHECK (cantidad > 0),
  CONSTRAINT chk_movimiento_traslado CHECK (tipo_movimiento <> 'TRASLADO_ENTRE_BODEGAS' OR (bodega_origen_id IS NOT NULL AND bodega_destino_id IS NOT NULL AND bodega_origen_id <> bodega_destino_id)),
  CONSTRAINT chk_movimiento_ingreso CHECK (tipo_movimiento <> 'INGRESO_IMPORTACION' OR (bodega_origen_id IS NULL AND bodega_destino_id IS NOT NULL)),
  CONSTRAINT chk_movimiento_salida CHECK (tipo_movimiento <> 'SALIDA_DESPACHO' OR (bodega_origen_id IS NOT NULL AND bodega_destino_id IS NULL)),
  CONSTRAINT chk_movimiento_operacion_interna CHECK (tipo_movimiento NOT IN ('BLOQUEO_RETENCION', 'LIBERACION_RETENCION', 'AJUSTE_MERMA', 'DECOMISO') OR (bodega_origen_id IS NOT NULL AND bodega_destino_id IS NULL))
);
CREATE INDEX idx_movimiento_fecha_tipo ON movimiento_inventario (fecha_movimiento, tipo_movimiento);
CREATE INDEX idx_movimiento_producto ON movimiento_inventario (producto_id);
