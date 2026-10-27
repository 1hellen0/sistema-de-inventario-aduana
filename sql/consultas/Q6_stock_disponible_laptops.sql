-- =====================================================================
-- SISTEMA DE INVENTARIO ADUANERO — CONSULTAS SQL ANALÍTICAS
-- Consulta: Q6_stock_disponible_laptops.sql
-- Motor objetivo: MySQL 8.0.16+
-- =====================================================================
-- Propósito:
-- Calcular el stock físico total disponible de computadoras portátiles
-- (laptops) sumando exclusivamente los saldos de inventario.cantidad_disponible
-- a través de todas las bodegas de la aduana.
--
-- Principio de arquitectura de datos:
-- El stock disponible actual se extrae directamente del Libro Mayor ('inventario')
-- mediante agregación SUM(cantidad_disponible). Bajo ninguna circunstancia
-- se debe sumar o reconstruir el saldo desde 'movimiento_inventario' (Libro Diario),
-- ya que la tabla 'inventario' mantiene el balance consolidado en tiempo constante
-- y previene lecturas inconsistentes o multiplicaciones por traslados internos.
--
-- Columnas proyectadas:
-- - sku: Código SKU único del producto.
-- - producto: Denominación comercial/técnica de la mercancía.
-- - stock_total: Suma de unidades físicas libres para despacho.
-- - unidad_medida: Unidad de conteo aduanero (UNIDADES).
-- =====================================================================

SELECT 
    p.codigo_sku AS sku,
    p.nombre AS producto,
    COALESCE(SUM(i.cantidad_disponible), 0.00) AS stock_total,
    p.unidad_medida
FROM producto p
LEFT JOIN inventario i 
    ON p.id_producto = i.producto_id
WHERE p.codigo_sku = 'SKU-LAP-001'
GROUP BY p.id_producto, p.codigo_sku, p.nombre, p.unidad_medida;
