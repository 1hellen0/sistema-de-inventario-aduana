-- =====================================================================
-- SISTEMA DE INVENTARIO ADUANERO — CONSULTAS SQL ANALÍTICAS
-- Consulta: Q1_mercancia_retenida_china.sql
-- Motor objetivo: MySQL 8.0.16+
-- =====================================================================
-- Propósito:
-- Mostrar la mercancía originaria de China que tiene cantidades
-- retenidas en la Bodega 2 (Bodega de Decomisos y Retenciones).
--
-- Columnas proyectadas:
-- - producto: Nombre descriptivo de la mercancía.
-- - sku: Código SKU único de referencia.
-- - bodega: Nombre de la bodega donde se custodia la mercancía.
-- - pais_origen: País de procedencia/fabricación del producto.
-- - cantidad_retenida: Saldo físico bajo medida cautelar o aforo.
-- - estado_inventario: Condición jurídica y física del saldo.
-- =====================================================================

SELECT 
    p.nombre AS producto,
    p.codigo_sku AS sku,
    b.nombre AS bodega,
    pa.nombre AS pais_origen,
    i.cantidad_retenida,
    i.estado_inventario
FROM inventario i
INNER JOIN producto p 
    ON i.producto_id = p.id_producto
INNER JOIN pais pa 
    ON p.pais_origen_id = pa.id_pais
INNER JOIN bodega b 
    ON i.bodega_id = b.id_bodega
WHERE b.codigo_bodega = 'BOD-02'
  AND pa.codigo_alfa2 = 'CN'
  AND i.cantidad_retenida > 0
ORDER BY i.cantidad_retenida DESC;
