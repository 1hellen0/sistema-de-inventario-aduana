-- =====================================================================
-- SISTEMA DE INVENTARIO ADUANERO — LABORATORIO #3
-- SCRIPT DML: POBLADO DE DATOS DE PRUEBA COHERENTES (data.sql)
-- Motor objetivo provisional: MySQL 8.0.16+ / InnoDB
-- Collation: utf8mb4_unicode_ci
-- =====================================================================

USE aduana_db;

-- Desactivar temporalmente revisiones foraneas durante la carga de datos
SET @OLD_FOREIGN_KEY_CHECKS = @@FOREIGN_KEY_CHECKS;
SET FOREIGN_KEY_CHECKS = 0;

-- Iniciar transaccion atomica para garantizar comportamiento All-or-Nothing
START TRANSACTION;

-- ---------------------------------------------------------------------
-- 1. POBLADO: pais (10 registros)
-- ---------------------------------------------------------------------
INSERT INTO pais (id_pais, codigo_alfa2, codigo_alfa3, nombre, region) VALUES
(1, 'CN', 'CHN', 'China', 'Asia'),
(2, 'US', 'USA', 'Estados Unidos', 'América del Norte'),
(3, 'CR', 'CRI', 'Costa Rica', 'América Central'),
(4, 'MX', 'MEX', 'México', 'América del Norte'),
(5, 'DE', 'DEU', 'Alemania', 'Europa'),
(6, 'JP', 'JPN', 'Japón', 'Asia'),
(7, 'BR', 'BRA', 'Brasil', 'América del Sur'),
(8, 'PA', 'PAN', 'Panamá', 'América Central'),
(9, 'ES', 'ESP', 'España', 'Europa'),
(10, 'KR', 'KOR', 'Corea del Sur', 'Asia');

-- ---------------------------------------------------------------------
-- 2. POBLADO: categoria_arancelaria (10 registros con jerarquia SAC/HS)
-- ---------------------------------------------------------------------
INSERT INTO categoria_arancelaria (id_categoria, codigo_arancelario, descripcion, porcentaje_arancel, categoria_padre_id) VALUES
(1, '8471.00.00', 'Máquinas automáticas para tratamiento o procesamiento de datos (computación)', 0.00, NULL),
(2, '8471.30.00', 'Computadoras portátiles de peso inferior o igual a 10 kg (laptops/notebooks)', 5.00, 1),
(3, '8517.00.00', 'Aparatos de telefonía, incluidos los teléfonos inteligentes y redes inalámbricas', 0.00, NULL),
(4, '8517.13.00', 'Teléfonos inteligentes (Smartphones) de tecnología celular avanzada', 10.00, 3),
(5, '8703.00.00', 'Automóviles de turismo y demás vehículos para transporte de personas', 0.00, NULL),
(6, '8703.23.00', 'Vehículos automóviles de cilindrada superior a 1500 cm3 pero inferior o igual a 3000 cm3', 25.00, 5),
(7, '0901.00.00', 'Café, incluso tostado o descafeinado; cáscara y cascarilla de café', 0.00, NULL),
(8, '0901.11.00', 'Café en grano sin tostar, sin descafeinar (café verde de exportación)', 1.00, 7),
(9, '3004.00.00', 'Medicamentos dosificados o acondicionados para la venta al por menor', 0.00, NULL),
(10, '3004.90.00', 'Demás medicamentos para usos terapéuticos dosificados', 2.00, 9);

-- ---------------------------------------------------------------------
-- 3. POBLADO: operador_comercial (6 registros)
-- ---------------------------------------------------------------------
INSERT INTO operador_comercial (id_operador, numero_identificacion, razon_social, nombre_comercial, tipo_operador, direccion, telefono, email, pais_id, estado) VALUES
(1, 'CJ-3101-789012', 'Importaciones Tecnológicas Globales S.A.', 'TechGlobal', 'IMPORTADOR', 'Parque Industrial Zeta, Calle 4, Edificio A', '+506-2200-1100', 'contacto@techglobal.cr', 3, 'ACTIVO'),
(2, 'CJ-3101-456123', 'Distribuidora Automotriz del Pacífico S.A.', 'AutoPacífico', 'IMPORTADOR', 'Autopista General Cañas, km 12', '+506-2430-8800', 'aduanas@autopacifico.cr', 3, 'ACTIVO'),
(3, 'CJ-3101-998877', 'Consorcio Agroindustrial Exportador S.A.', 'AgroExport', 'EXPORTADOR', 'Zona Franca El Coyol, Nave 18', '+506-2435-5000', 'logistica@agroexport.com', 3, 'ACTIVO'),
(4, 'CJ-3101-332211', 'Comercializadora Médica y Farmacéutica del Valle S.A.', 'FarmaValle', 'AMBOS', 'Bulevar Rohrmoser, Edificio Prisma, Piso 3', '+506-2290-7070', 'comercio@farmavalle.com', 3, 'ACTIVO'),
(5, 'US-EIN-1234567', 'Pacific Trading Logistics Inc.', 'PacificTrade US', 'EXPORTADOR', '100 Portway Blvd, Long Beach, CA', '+1-310-555-0199', 'ops@pacifictrade.us', 2, 'ACTIVO'),
(6, 'CN-USCI-9876543', 'Shenzhen Global Electronics Co. Ltd.', 'Shenzhen Tech', 'EXPORTADOR', 'High-Tech Industrial Park, Nanshan, Shenzhen', '+86-755-8888-0000', 'export@shenzhentech.cn', 1, 'ACTIVO');

-- ---------------------------------------------------------------------
-- 4. POBLADO: agente_aduanero (4 registros)
-- ---------------------------------------------------------------------
INSERT INTO agente_aduanero (id_agente, numero_licencia, nombre_completo, agencia, telefono, email, estado) VALUES
(1, 'LIC-ADU-2015-045', 'Lic. Roberto Morales Castro', 'Agencia de Aduanas Morales & Asociados S.A.', '+506-2222-3344', 'rmorales@aduanasmorales.cr', 'HABILITADO'),
(2, 'LIC-ADU-2018-092', 'Licda. Marcela Vargas Solano', 'Despachos Aduaneros del Pacífico S.A.', '+506-2661-5566', 'mvargas@despachospacifico.cr', 'HABILITADO'),
(3, 'LIC-ADU-2020-114', 'Lic. Carlos Chen Wu', 'Agencia Aduanal Chen & Logistics S.A.', '+506-2248-7788', 'cchen@chenlogistics.cr', 'HABILITADO'),
(4, 'LIC-ADU-2022-178', 'Licda. Sofía Jiménez Ruiz', 'Servicios Aduaneros Intermodales S.A.', '+506-2440-9900', 'sjimenez@aduanasintermodal.cr', 'HABILITADO');

-- ---------------------------------------------------------------------
-- 5. POBLADO: funcionario (6 registros con jerarquia recursiva)
-- ---------------------------------------------------------------------
INSERT INTO funcionario (id_funcionario, identificacion, nombre_completo, cargo, departamento, email, supervisor_id, activo) VALUES
(1, 'EMP-ADU-001', 'Lic. Fernando Gutiérrez Peña', 'Director de Fiscalización Aduanera', 'Fiscalización', 'fgutierrez@aduana.gob.cr', NULL, TRUE),
(2, 'EMP-ADU-012', 'Ing. Patricia Navarro Méndez', 'Jefe de Operaciones de Depósito Fiscal', 'Operaciones Portuarias', 'pnavarro@aduana.gob.cr', 1, TRUE),
(3, 'EMP-ADU-045', 'Lic. Andrés Monge Quirós', 'Inspector Superior de Aforo Físico', 'Aforo e Inspección', 'amonge@aduana.gob.cr', 1, TRUE),
(4, 'EMP-ADU-068', 'Licda. Elena Rojas Campos', 'Inspectora de Aforo y Reconocimiento', 'Aforo e Inspección', 'erojas@aduana.gob.cr', 3, TRUE),
(5, 'EMP-ADU-089', 'Téc. Jorge Valerio Brenes', 'Custodio y Encargado de Bodega Fiscal 1', 'Control de Recintos', 'jvalerio@aduana.gob.cr', 2, TRUE),
(6, 'EMP-ADU-090', 'Téc. David Salazar Umaña', 'Custodio y Encargado de Bodega Fiscal 2', 'Control de Recintos', 'dsalazar@aduana.gob.cr', 2, TRUE);

-- ---------------------------------------------------------------------
-- 6. POBLADO: bodega (4 registros)
-- ---------------------------------------------------------------------
INSERT INTO bodega (id_bodega, codigo_bodega, nombre, tipo_bodega, ubicacion, capacidad_m3, funcionario_responsable_id, activo) VALUES
(1, 'BOD-01', 'Bodega Central de Depósito Fiscal 1', 'FISCAL', 'Muelle Fiscal de Caldera, Sector Norte, Andén A', 5000.00, 5, TRUE),
(2, 'BOD-02', 'Bodega de Decomisos y Retenciones 2', 'FISCAL', 'Recinto Fiscal Portuario, Sector Este, Nave C', 3500.00, 6, TRUE),
(3, 'BOD-03', 'Depósito Refrigerado de Perecederos', 'REFRIGERADA', 'Terminal de Contenedores de Moín, Zona Fría', 2000.00, 5, TRUE),
(4, 'BOD-04', 'Almacén de Aforo Especial y Cuarentena', 'CUARENTENA', 'Terminal Intermodal Central, Módulo 4', 1500.00, 6, TRUE);

-- ---------------------------------------------------------------------
-- 7. POBLADO: contenedor (8 registros - China lider en contenedores recibidos)
-- ---------------------------------------------------------------------
INSERT INTO contenedor (id_contenedor, numero_contenedor, tipo_contenedor, tara_kg, peso_maximo_kg, pais_origen_id, linea_naviera, estado) VALUES
(1, 'CSNU7845120', '40_HIGH_CUBE', 3900.00, 30480.00, 1, 'Cosco Shipping Lines', 'RECIBIDO_EN_PUERTO'),
(2, 'MSCU8921345', '40_DRY', 3750.00, 30480.00, 1, 'Mediterranean Shipping Company', 'RECIBIDO_EN_PUERTO'),
(3, 'COSU6123987', '40_HIGH_CUBE', 3920.00, 30480.00, 1, 'Cosco Shipping Lines', 'RECIBIDO_EN_PUERTO'),
(4, 'CMAU5498123', '20_DRY', 2280.00, 24000.00, 1, 'CMA CGM', 'RECIBIDO_EN_PUERTO'),
(5, 'MAEU3104568', '40_DRY', 3780.00, 30480.00, 2, 'Maersk Line', 'RECIBIDO_EN_PUERTO'),
(6, 'APLU4509124', '40_DRY', 3800.00, 30480.00, 2, 'American President Lines', 'DESPACHADO'),
(7, 'HLXU9812340', '40_HIGH_CUBE', 3950.00, 30480.00, 5, 'Hapag-Lloyd', 'RECIBIDO_EN_PUERTO'),
(8, 'TGHU2345678', '20_DRY', 2250.00, 24000.00, 4, 'Hamburg Süd', 'RECIBIDO_EN_PUERTO');

-- ---------------------------------------------------------------------
-- 8. POBLADO: producto (8 registros)
-- ---------------------------------------------------------------------
INSERT INTO producto (id_producto, codigo_sku, nombre, descripcion, categoria_arancelaria_id, unidad_medida, pais_origen_id, precio_referencia) VALUES
(1, 'SKU-LAP-001', 'Laptop Lenovo ThinkPad T14 Gen 4', 'Intel Core i7, 16GB RAM, 512GB SSD', 2, 'UNIDADES', 1, 850.00),
(2, 'SKU-PHO-002', 'Smartphone Xiaomi Redmi Note 13 Pro', 'Pantalla AMOLED 6.67", 256GB ROM, 5G', 4, 'UNIDADES', 1, 220.00),
(3, 'SKU-AUT-003', 'Vehículo SUV Toyota RAV4 Híbrido 2.5L', 'Tracción AWD, Transmisión Automática CVT', 6, 'UNIDADES', 6, 28500.00),
(4, 'SKU-MED-004', 'Amoxicilina + Ácido Clavulánico 875/125mg', 'Caja por 14 tabletas recubiertas de uso oral', 10, 'BULTOS', 5, 15.50),
(5, 'SKU-CAF-005', 'Café Arábica Especialidad Tarrazú', 'Saco de café verde de exportación grano selecto', 8, 'BULTOS', 3, 180.00),
(6, 'SKU-TAB-006', 'Tablet Huawei MatePad 11.5S', 'Pantalla PaperMatte 144Hz, 8GB RAM, WiFi', 2, 'UNIDADES', 1, 310.00),
(7, 'SKU-SER-007', 'Servidor Rack Dell PowerEdge R750', 'Dual Intel Xeon Gold, 64GB ECC RAM, 2x960GB SSD', 2, 'UNIDADES', 2, 4200.00),
(8, 'SKU-PAN-008', 'Paneles Solares Monocristalinos 550W Jinko', 'Módulos fotovoltaicos de alta eficiencia Tier 1', 2, 'UNIDADES', 1, 95.00);

-- ---------------------------------------------------------------------
-- 9. POBLADO: declaracion_aduanera (6 registros - Octubre y mayor valor)
-- ---------------------------------------------------------------------
INSERT INTO declaracion_aduanera (id_declaracion, numero_declaracion, tipo_declaracion, regimen_aduanero, fecha_registro, fecha_liquidacion, operador_comercial_id, agente_aduanero_id, pais_procedencia_id, pais_destino_id, contenedor_id, canal_aforo, estado, valor_total_cif, total_tributos) VALUES
(1, 'DEC-2026-IMP-00041', 'IMPORTACION', 'Definitivo', '2026-10-05 09:30:00', '2026-10-06 15:00:00', 1, 1, 1, 3, 1, 'VERDE', 'AUTORIZADA', 425000.00, 21250.00),
(2, 'DEC-2026-IMP-00042', 'IMPORTACION', 'Definitivo', '2026-10-12 14:15:00', NULL, 1, 3, 1, 3, 2, 'ROJO', 'RETENIDA', 220000.00, 22000.00),
(3, 'DEC-2026-IMP-00043', 'IMPORTACION', 'Definitivo', '2026-10-18 11:00:00', '2026-10-20 10:00:00', 2, 2, 6, 3, 6, 'VERDE', 'AUTORIZADA', 285000.00, 71250.00),
(4, 'DEC-2026-IMP-00044', 'IMPORTACION', 'Depósito Fiscal', '2026-10-22 16:40:00', NULL, 4, 4, 5, 3, 7, 'AMARILLO', 'EN_TRAMITE', 155000.00, 3100.00),
(5, 'DEC-2026-EXP-00015', 'EXPORTACION', 'Definitivo', '2026-09-28 10:00:00', '2026-09-29 12:00:00', 3, 1, 3, 5, NULL, 'VERDE', 'AUTORIZADA', 90000.00, 0.00),
(6, 'DEC-2026-IMP-00030', 'IMPORTACION', 'Definitivo', '2026-09-15 08:30:00', '2026-09-16 11:00:00', 1, 1, 2, 3, 5, 'VERDE', 'AUTORIZADA', 126000.00, 6300.00);

-- ---------------------------------------------------------------------
-- 10. POBLADO: detalle_declaracion (6 registros)
-- ---------------------------------------------------------------------
INSERT INTO detalle_declaracion (id_detalle, declaracion_id, producto_id, numero_linea, cantidad_declarada, unidad_medida, precio_unitario_fob, valor_total_fob, tasa_arancelaria, monto_arancel) VALUES
(1, 1, 1, 1, 500.00, 'UNIDADES', 850.00, 425000.00, 5.00, 21250.00),
(2, 2, 2, 1, 1000.00, 'UNIDADES', 220.00, 220000.00, 10.00, 22000.00),
(3, 3, 3, 1, 10.00, 'UNIDADES', 28500.00, 285000.00, 25.00, 71250.00),
(4, 4, 4, 1, 10000.00, 'BULTOS', 15.50, 155000.00, 2.00, 3100.00),
(5, 5, 5, 1, 500.00, 'BULTOS', 180.00, 90000.00, 0.00, 0.00),
(6, 6, 7, 1, 30.00, 'UNIDADES', 4200.00, 126000.00, 5.00, 6300.00);

-- ---------------------------------------------------------------------
-- 11. POBLADO: inspeccion_aduanera (4 registros)
-- ---------------------------------------------------------------------
INSERT INTO inspeccion_aduanera (id_inspeccion, numero_acta, declaracion_id, funcionario_id, fecha_inspeccion, tipo_inspeccion, resultado, tuvo_observaciones, observaciones, acciones_tomadas) VALUES
(1, 'ACTA-INSP-2026-0042', 2, 3, '2026-10-13 10:30:00', 'FISICA_INTRUSIVA', 'RETENCION_PREVENTIVA', TRUE, 'Discrepancia en números de serie y presunta subvaloración de terminales celulares', 'Orden de retención preventiva total y traslado a custodia en Bodega Fiscal 2'),
(2, 'ACTA-INSP-2026-0044', 4, 4, '2026-10-23 09:15:00', 'DOCUMENTAL', 'OBSERVACIONES_LEVES', TRUE, 'Falta el certificado de Buenas Prácticas de Manufactura (BPM) del lote 88B', 'Emplazamiento de 5 días hábiles al agente aduanero para subsanar expediente documental'),
(3, 'ACTA-INSP-2026-0041', 1, 4, '2026-10-06 14:00:00', 'SCANNER_NO_INTRUSIVO', 'CONFORME_SIN_OBSERVACIONES', FALSE, 'Imágenes de scanner conformes con packing list declarado', 'Autorización de levante inmediato'),
(4, 'ACTA-INSP-2026-0043', 3, 3, '2026-10-19 15:30:00', 'FISICA_INTRUSIVA', 'CONFORME_SIN_OBSERVACIONES', FALSE, 'Confrontación física de números de chasis (VIN) y motor sin novedades', 'Levante autorizado');

-- ---------------------------------------------------------------------
-- 12. POBLADO: inventario (8 registros conciliados)
-- cantidad_total es columna generada STORED: (cantidad_disponible + cantidad_retenida)
-- ---------------------------------------------------------------------
INSERT INTO inventario (id_inventario, bodega_id, producto_id, cantidad_disponible, cantidad_retenida, estado_inventario, fecha_ultima_actualizacion) VALUES
(1, 1, 1, 320.00, 0.00, 'DISPONIBLE', '2026-10-21 16:00:00'),
(2, 3, 1, 80.00, 0.00, 'DISPONIBLE', '2026-10-10 16:00:00'),
(3, 2, 2, 0.00, 990.00, 'RETENIDO_TOTAL', '2026-10-22 14:00:00'),
(4, 1, 3, 8.00, 0.00, 'DISPONIBLE', '2026-10-20 10:00:00'),
(5, 3, 4, 9500.00, 500.00, 'RETENIDO_PARCIAL', '2026-10-23 09:30:00'),
(6, 2, 6, 50.00, 250.00, 'RETENIDO_PARCIAL', '2026-10-20 11:30:00'),
(7, 1, 7, 25.00, 0.00, 'DISPONIBLE', '2026-09-16 11:00:00'),
(8, 1, 8, 200.00, 0.00, 'DISPONIBLE', '2026-10-01 08:00:00');

-- ---------------------------------------------------------------------
-- 13. POBLADO: movimiento_inventario (17 registros con Opción A y trazabilidad 100%)
-- Operaciones internas usan bodega_origen_id obligatoria y bodega_destino_id NULL
-- Todos los saldos de la tabla inventario quedan conciliados matemáticamente con el libro diario
-- ---------------------------------------------------------------------
INSERT INTO movimiento_inventario (id_movimiento, tipo_movimiento, producto_id, bodega_origen_id, bodega_destino_id, cantidad, fecha_movimiento, declaracion_id, inspeccion_id, funcionario_id, motivo) VALUES
(1, 'INGRESO_IMPORTACION', 1, NULL, 1, 502.00, '2026-10-05 11:30:00', 1, NULL, 5, 'Recepción e ingreso de carga amparada en DUA DEC-2026-IMP-00041'),
(2, 'SALIDA_DESPACHO', 1, 1, NULL, 100.00, '2026-10-08 14:00:00', 1, NULL, 5, 'Despacho y retiro parcial autorizado para levante nacional'),
(3, 'TRASLADO_ENTRE_BODEGAS', 1, 1, 3, 80.00, '2026-10-10 16:00:00', 1, NULL, 5, 'Reubicación y traslado interno hacia Bodega 3 por optimización de espacio'),
(4, 'INGRESO_IMPORTACION', 2, NULL, 2, 1000.00, '2026-10-12 15:30:00', 2, NULL, 6, 'Ingreso de contenedor marítimo CSNU7845120 a depósito en Bodega 2'),
(5, 'BLOQUEO_RETENCION', 2, 2, NULL, 1000.00, '2026-10-13 11:00:00', 2, 1, 3, 'Medida cautelar de inmovilización y retención total ordenada en Acta de Aforo ACTA-INSP-2026-0042'),
(6, 'INGRESO_IMPORTACION', 6, NULL, 2, 300.00, '2026-10-14 09:00:00', NULL, NULL, 6, 'Ingreso por arribo consolidador de carga tecnológica a Bodega 2'),
(7, 'BLOQUEO_RETENCION', 6, 2, NULL, 300.00, '2026-10-15 10:00:00', NULL, NULL, 3, 'Retención cautelar preventiva de 300 unidades por falta de factura comercial homologada'),
(8, 'LIBERACION_RETENCION', 6, 2, NULL, 50.00, '2026-10-20 11:30:00', NULL, NULL, 3, 'Liberación parcial de 50 unidades tras presentación de aclaración tributaria'),
(9, 'AJUSTE_MERMA', 1, 1, NULL, 2.00, '2026-10-21 16:00:00', NULL, NULL, 5, 'Merma por daño físico irreparable en embalaje durante maniobra de estiba (descuenta de disponible)'),
(10, 'DECOMISO', 2, 2, NULL, 10.00, '2026-10-22 14:00:00', 2, 1, 1, 'Decomiso administrativo definitivo de 10 unidades por contrabando mediante Resolución Sancionatoria DGA-042-2026 (descuenta de retenida)'),
(11, 'INGRESO_IMPORTACION', 3, NULL, 1, 10.00, '2026-10-19 16:00:00', 3, 4, 5, 'Ingreso a Bodega 1 de vehículos SUV amparados en DUA DEC-2026-IMP-00043 tras aforo'),
(12, 'SALIDA_DESPACHO', 3, 1, NULL, 2.00, '2026-10-20 10:00:00', 3, NULL, 5, 'Retiro parcial de 2 vehículos SUV autorizado para AutoPacífico'),
(13, 'INGRESO_IMPORTACION', 4, NULL, 3, 10000.00, '2026-10-22 17:00:00', 4, NULL, 5, 'Ingreso a Depósito Refrigerado/Climatizado de medicamento amparado en DUA DEC-2026-IMP-00044'),
(14, 'BLOQUEO_RETENCION', 4, 3, NULL, 500.00, '2026-10-23 09:30:00', 4, 2, 4, 'Retención preventiva de 500 bultos por falta de certificado BPM según Acta ACTA-INSP-2026-0044'),
(15, 'INGRESO_IMPORTACION', 7, NULL, 1, 30.00, '2026-09-15 14:00:00', 6, NULL, 5, 'Ingreso de servidores informáticos amparados en DUA DEC-2026-IMP-00030'),
(16, 'SALIDA_DESPACHO', 7, 1, NULL, 5.00, '2026-09-16 11:00:00', 6, NULL, 5, 'Despacho y entrega parcial de 5 servidores para centro de cómputo'),
(17, 'INGRESO_IMPORTACION', 8, NULL, 1, 200.00, '2026-10-01 08:00:00', NULL, NULL, 5, 'Recepción e ingreso de lote de paneles solares fotovoltaicos a Bodega 1');

-- Confirmar transaccion atomica de carga
COMMIT;

-- Restaurar revisiones foraneas
SET FOREIGN_KEY_CHECKS = @OLD_FOREIGN_KEY_CHECKS;
