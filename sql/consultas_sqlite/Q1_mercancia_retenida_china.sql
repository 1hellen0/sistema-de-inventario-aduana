-- =====================================================================
-- SISTEMA DE INVENTARIO ADUANERO — CONSULTAS SQL ANALÍTICAS (SQLITE)
-- Consulta: Q1_mercancia_retenida_china.sql
-- Motor objetivo: SQLite 3.31.0+
-- =====================================================================
-- Propósito:
-- Mostrar la mercancía retenida originaria de China en la Bodega 2
-- (Bodega de Decomisos y Retenciones 2, código 'BOD-02').
--
-- Columnas proyectadas:
-- - codigo_sku: Identificador comercial del producto.
-- - descripcion_mercancia: Nombre y especificación del producto.
-- - nombre_bodega: Denominación oficial de la bodega de almacenamiento.
-- - codigo_bodega: Identificador de negocio de la bodega ('BOD-02').
-- - cantidad_retenida: Saldo físico en condición de retención legal.
-- - unidad_medida: Unidad de medida arancelaria/física.
-- - pais_origen: Nombre del país de origen ('China').
-- =====================================================================

SELECT 
    p.codigo_sku,
    p.nombre AS descripcion_mercancia,
    b.nombre AS nombre_bodega,
    b.codigo_bodega,
    i.cantidad_retenida,
    p.unidad_medida,
    pa.nombre AS pais_origen
FROM inventario i
INNER JOIN bodega b 
    ON i.bodega_id = b.id_bodega
INNER JOIN producto p 
    ON i.producto_id = p.id_producto
INNER JOIN pais pa 
    ON p.pais_origen_id = pa.id_pais
WHERE b.codigo_bodega = 'BOD-02'
  AND pa.codigo_alfa2 = 'CN'
  AND i.cantidad_retenida > 0;
