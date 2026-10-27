-- =====================================================================
-- SISTEMA DE INVENTARIO ADUANERO — LABORATORIO #3
-- SCRIPT DDL: CREACION DE BASE DE DATOS Y ESTRUCTURA DE TABLAS (schema.sql)
-- Motor objetivo provisional: MySQL 8.0.16+ / InnoDB
-- Collation: utf8mb4_unicode_ci
-- =====================================================================

-- 1. CREACION DE LA BASE DE DATOS
CREATE DATABASE IF NOT EXISTS aduana_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE aduana_db;

-- Desactivar temporalmente revisiones foraneas durante el despliegue del DDL
SET @OLD_FOREIGN_KEY_CHECKS = @@FOREIGN_KEY_CHECKS;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------
-- 1. TABLA: pais
-- Catalogo maestro de naciones soberanas para origen, procedencia y destino
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS pais;
CREATE TABLE pais (
  id_pais INT AUTO_INCREMENT PRIMARY KEY,
  codigo_alfa2 CHAR(2) NOT NULL,
  codigo_alfa3 CHAR(3) NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  region VARCHAR(60) NOT NULL,
  CONSTRAINT uk_pais_codigo_alfa2 UNIQUE (codigo_alfa2),
  CONSTRAINT uk_pais_codigo_alfa3 UNIQUE (codigo_alfa3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 2. TABLA: categoria_arancelaria
-- Estructura jerarquica arancelaria del Sistema Armonizado (SAC/HS)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS categoria_arancelaria;
CREATE TABLE categoria_arancelaria (
  id_categoria INT AUTO_INCREMENT PRIMARY KEY,
  codigo_arancelario VARCHAR(20) NOT NULL,
  descripcion TEXT NOT NULL,
  porcentaje_arancel DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  categoria_padre_id INT NULL,
  CONSTRAINT uk_categoria_codigo UNIQUE (codigo_arancelario),
  CONSTRAINT fk_categoria_padre FOREIGN KEY (categoria_padre_id)
    REFERENCES categoria_arancelaria(id_categoria)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_categoria_padre_anticiclo CHECK (categoria_padre_id IS NULL OR categoria_padre_id <> id_categoria),
  CONSTRAINT chk_porcentaje_arancel CHECK (porcentaje_arancel >= 0 AND porcentaje_arancel <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3. TABLA: operador_comercial
-- Entidades comerciales unificadas (importadores, exportadores o ambos)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS operador_comercial;
CREATE TABLE operador_comercial (
  id_operador INT AUTO_INCREMENT PRIMARY KEY,
  numero_identificacion VARCHAR(30) NOT NULL,
  razon_social VARCHAR(150) NOT NULL,
  nombre_comercial VARCHAR(150) NULL,
  tipo_operador ENUM('IMPORTADOR', 'EXPORTADOR', 'AMBOS') NOT NULL DEFAULT 'IMPORTADOR',
  direccion TEXT NOT NULL,
  telefono VARCHAR(25) NULL,
  email VARCHAR(100) NOT NULL,
  pais_id INT NOT NULL,
  estado ENUM('ACTIVO', 'INACTIVO', 'SUSPENDIDO') NOT NULL DEFAULT 'ACTIVO',
  CONSTRAINT uk_operador_identificacion UNIQUE (numero_identificacion),
  CONSTRAINT fk_operador_pais FOREIGN KEY (pais_id)
    REFERENCES pais(id_pais)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 4. TABLA: agente_aduanero
-- Agentes y agencias aduanales legalmente habilitadas
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS agente_aduanero;
CREATE TABLE agente_aduanero (
  id_agente INT AUTO_INCREMENT PRIMARY KEY,
  numero_licencia VARCHAR(30) NOT NULL,
  nombre_completo VARCHAR(150) NOT NULL,
  agencia VARCHAR(150) NOT NULL,
  telefono VARCHAR(25) NULL,
  email VARCHAR(100) NOT NULL,
  estado ENUM('HABILITADO', 'SUSPENDIDO', 'REVOCADO') NOT NULL DEFAULT 'HABILITADO',
  CONSTRAINT uk_agente_licencia UNIQUE (numero_licencia),
  CONSTRAINT uk_agente_email UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 5. TABLA: funcionario
-- Personal oficial de la autoridad aduanera (inspectores, aforadores, custodios)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS funcionario;
CREATE TABLE funcionario (
  id_funcionario INT AUTO_INCREMENT PRIMARY KEY,
  identificacion VARCHAR(30) NOT NULL,
  nombre_completo VARCHAR(150) NOT NULL,
  cargo VARCHAR(100) NOT NULL,
  departamento VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL,
  supervisor_id INT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT uk_funcionario_identificacion UNIQUE (identificacion),
  CONSTRAINT uk_funcionario_email UNIQUE (email),
  CONSTRAINT fk_funcionario_supervisor FOREIGN KEY (supervisor_id)
    REFERENCES funcionario(id_funcionario)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT chk_funcionario_supervisor_anticiclo CHECK (supervisor_id IS NULL OR supervisor_id <> id_funcionario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 6. TABLA: bodega
-- Almacenes y depositos fiscales bajo control primario aduanero
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS bodega;
CREATE TABLE bodega (
  id_bodega INT AUTO_INCREMENT PRIMARY KEY,
  codigo_bodega VARCHAR(20) NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  tipo_bodega ENUM('GENERAL', 'FISCAL', 'REFRIGERADA', 'VALORES', 'CUARENTENA') NOT NULL DEFAULT 'FISCAL',
  ubicacion VARCHAR(200) NOT NULL,
  capacidad_m3 DECIMAL(10,2) NULL,
  funcionario_responsable_id INT NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT uk_bodega_codigo UNIQUE (codigo_bodega),
  CONSTRAINT fk_bodega_funcionario FOREIGN KEY (funcionario_responsable_id)
    REFERENCES funcionario(id_funcionario)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_bodega_capacidad CHECK (capacidad_m3 IS NULL OR capacidad_m3 > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 7. TABLA: contenedor
-- Unidades intermodales de transporte maritimo y terrestre (ISO 6346)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS contenedor;
CREATE TABLE contenedor (
  id_contenedor INT AUTO_INCREMENT PRIMARY KEY,
  numero_contenedor VARCHAR(20) NOT NULL,
  tipo_contenedor ENUM('20_DRY', '40_DRY', '40_HIGH_CUBE', 'REEFER', 'OPEN_TOP') NOT NULL DEFAULT '40_DRY',
  tara_kg DECIMAL(8,2) NOT NULL,
  peso_maximo_kg DECIMAL(8,2) NOT NULL,
  pais_origen_id INT NOT NULL,
  linea_naviera VARCHAR(100) NOT NULL,
  estado ENUM('EN_TRANSITO', 'RECIBIDO_EN_PUERTO', 'EN_INSPECCION', 'DESCONSOLIDADO', 'DESPACHADO', 'RETENIDO') NOT NULL DEFAULT 'RECIBIDO_EN_PUERTO',
  CONSTRAINT uk_contenedor_numero UNIQUE (numero_contenedor),
  CONSTRAINT fk_contenedor_pais FOREIGN KEY (pais_origen_id)
    REFERENCES pais(id_pais)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_contenedor_tara CHECK (tara_kg > 0),
  CONSTRAINT chk_contenedor_peso_max CHECK (peso_maximo_kg > 0),
  CONSTRAINT chk_contenedor_peso_rel CHECK (peso_maximo_kg > tara_kg),
  INDEX idx_contenedor_estado_pais (estado, pais_origen_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 8. TABLA: producto
-- Catalogo maestro de mercancias sujetas a aforo y almacenamiento
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS producto;
CREATE TABLE producto (
  id_producto INT AUTO_INCREMENT PRIMARY KEY,
  codigo_sku VARCHAR(50) NOT NULL,
  nombre VARCHAR(150) NOT NULL,
  descripcion TEXT NULL,
  categoria_arancelaria_id INT NOT NULL,
  unidad_medida VARCHAR(20) NOT NULL,
  pais_origen_id INT NOT NULL,
  precio_referencia DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  CONSTRAINT uk_producto_sku UNIQUE (codigo_sku),
  CONSTRAINT fk_producto_categoria FOREIGN KEY (categoria_arancelaria_id)
    REFERENCES categoria_arancelaria(id_categoria)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_producto_pais FOREIGN KEY (pais_origen_id)
    REFERENCES pais(id_pais)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_producto_precio_ref CHECK (precio_referencia >= 0),
  INDEX idx_producto_pais (pais_origen_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 9. TABLA: declaracion_aduanera
-- Expediente central de importacion, exportacion o transito (DUA/Pedimento)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS declaracion_aduanera;
CREATE TABLE declaracion_aduanera (
  id_declaracion INT AUTO_INCREMENT PRIMARY KEY,
  numero_declaracion VARCHAR(35) NOT NULL,
  tipo_declaracion ENUM('IMPORTACION', 'EXPORTACION', 'TRANSITO') NOT NULL DEFAULT 'IMPORTACION',
  regimen_aduanero VARCHAR(50) NOT NULL,
  fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_liquidacion DATETIME NULL,
  operador_comercial_id INT NOT NULL,
  agente_aduanero_id INT NOT NULL,
  pais_procedencia_id INT NOT NULL,
  pais_destino_id INT NOT NULL,
  contenedor_id INT NULL,
  canal_aforo ENUM('VERDE', 'AMARILLO', 'ROJO') NOT NULL DEFAULT 'VERDE',
  estado ENUM('REGISTRADA', 'EN_TRAMITE', 'EN_INSPECCION', 'AUTORIZADA', 'RETENIDA', 'CANCELADA') NOT NULL DEFAULT 'REGISTRADA',
  valor_total_cif DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  total_tributos DECIMAL(14,2) NOT NULL DEFAULT 0.00,
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
  CONSTRAINT chk_declaracion_fechas CHECK (fecha_liquidacion IS NULL OR fecha_liquidacion >= fecha_registro),
  INDEX idx_declaracion_tipo_fecha (tipo_declaracion, fecha_registro),
  INDEX idx_declaracion_operador_valor (operador_comercial_id, valor_total_cif)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 10. TABLA: detalle_declaracion
-- Partidas arancelarias individuales por declaracion (Resolucion N:M)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS detalle_declaracion;
CREATE TABLE detalle_declaracion (
  id_detalle INT AUTO_INCREMENT PRIMARY KEY,
  declaracion_id INT NOT NULL,
  producto_id INT NOT NULL,
  numero_linea INT NOT NULL,
  cantidad_declarada DECIMAL(12,2) NOT NULL,
  unidad_medida VARCHAR(20) NOT NULL,
  precio_unitario_fob DECIMAL(12,2) NOT NULL,
  valor_total_fob DECIMAL(14,2) NOT NULL,
  tasa_arancelaria DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  monto_arancel DECIMAL(12,2) NOT NULL DEFAULT 0.00,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 11. TABLA: inventario
-- Saldo fisico actual custodiado en bodega (Disponible vs Retenido)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS inventario;
CREATE TABLE inventario (
  id_inventario INT AUTO_INCREMENT PRIMARY KEY,
  bodega_id INT NOT NULL,
  producto_id INT NOT NULL,
  cantidad_disponible DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  cantidad_retenida DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  cantidad_total DECIMAL(12,2) GENERATED ALWAYS AS (cantidad_disponible + cantidad_retenida) STORED,
  estado_inventario ENUM('DISPONIBLE', 'RETENIDO_TOTAL', 'RETENIDO_PARCIAL', 'DECOMISADO', 'EN_CUARENTENA') NOT NULL DEFAULT 'DISPONIBLE',
  fecha_ultima_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uk_bodega_producto UNIQUE (bodega_id, producto_id),
  CONSTRAINT fk_inventario_bodega FOREIGN KEY (bodega_id)
    REFERENCES bodega(id_bodega)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_inventario_producto FOREIGN KEY (producto_id)
    REFERENCES producto(id_producto)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_inventario_cant_disp CHECK (cantidad_disponible >= 0),
  CONSTRAINT chk_inventario_cant_ret CHECK (cantidad_retenida >= 0),
  INDEX idx_inventario_producto (producto_id),
  INDEX idx_inventario_bodega_retenido (bodega_id, cantidad_retenida)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 12. TABLA: inspeccion_aduanera
-- Actas de aforo fisico intrusivo o revision documental
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS inspeccion_aduanera;
CREATE TABLE inspeccion_aduanera (
  id_inspeccion INT AUTO_INCREMENT PRIMARY KEY,
  numero_acta VARCHAR(35) NOT NULL,
  declaracion_id INT NOT NULL,
  funcionario_id INT NOT NULL,
  fecha_inspeccion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  tipo_inspeccion ENUM('FISICA_INTRUSIVA', 'DOCUMENTAL', 'SCANNER_NO_INTRUSIVO', 'ALEATORIA') NOT NULL,
  resultado ENUM('CONFORME_SIN_OBSERVACIONES', 'OBSERVACIONES_LEVES', 'RETENCION_PREVENTIVA', 'DECOMISO_MERCANCIA', 'RECHAZADO') NOT NULL,
  tuvo_observaciones BOOLEAN NOT NULL DEFAULT FALSE,
  observaciones TEXT NULL,
  acciones_tomadas TEXT NULL,
  CONSTRAINT uk_inspeccion_acta UNIQUE (numero_acta),
  CONSTRAINT fk_inspeccion_declaracion FOREIGN KEY (declaracion_id)
    REFERENCES declaracion_aduanera(id_declaracion)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_inspeccion_funcionario FOREIGN KEY (funcionario_id)
    REFERENCES funcionario(id_funcionario)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_inspeccion_observaciones_func (tuvo_observaciones, funcionario_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 13. TABLA: movimiento_inventario
-- Registro historico de auditoria fisica de operaciones de almacen
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS movimiento_inventario;
CREATE TABLE movimiento_inventario (
  id_movimiento INT AUTO_INCREMENT PRIMARY KEY,
  tipo_movimiento ENUM('INGRESO_IMPORTACION', 'SALIDA_DESPACHO', 'TRASLADO_ENTRE_BODEGAS', 'BLOQUEO_RETENCION', 'LIBERACION_RETENCION', 'AJUSTE_MERMA', 'DECOMISO') NOT NULL,
  producto_id INT NOT NULL,
  bodega_origen_id INT NULL,
  bodega_destino_id INT NULL,
  cantidad DECIMAL(12,2) NOT NULL,
  fecha_movimiento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  declaracion_id INT NULL,
  inspeccion_id INT NULL,
  funcionario_id INT NOT NULL,
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
  CONSTRAINT chk_movimiento_operacion_interna CHECK (tipo_movimiento NOT IN ('BLOQUEO_RETENCION', 'LIBERACION_RETENCION', 'AJUSTE_MERMA', 'DECOMISO') OR (bodega_origen_id IS NOT NULL AND bodega_destino_id IS NULL)),
  INDEX idx_movimiento_fecha_tipo (fecha_movimiento, tipo_movimiento),
  INDEX idx_movimiento_producto (producto_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Restaurar revisiones foraneas
SET FOREIGN_KEY_CHECKS = @OLD_FOREIGN_KEY_CHECKS;
