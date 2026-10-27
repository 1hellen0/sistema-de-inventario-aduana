-- =====================================================================
-- SISTEMA DE INVENTARIO ADUANERO — CONSULTAS SQL ANALÍTICAS (SQLITE)
-- Consulta: Q6_stock_disponible_laptops.sql
-- Motor objetivo: SQLite 3.31.0+
-- =====================================================================
-- Propósito:
-- Calcular el stock total disponible de laptops Lenovo ThinkPad T14
-- (SKU-LAP-001) custodiadas en los recintos aduaneros.
--
-- Robustez contra inventario cero / inexistente:
-- Utiliza LEFT JOIN sobre 'inventario' y filtra el SKU directamente en la
-- tabla 'producto', asegurando que si un SKU existe pero aún no tiene inventario,
-- retorne una fila con stock 0.00 gracias a COALESCE.
--
-- Integridad del Libro Mayor:
-- Consulta exclusivamente la tabla agregada 'inventario', sin escanear
-- movimientos históricos.
--
-- Columnas proyectadas:
-- - codigo_sku: Código SKU del producto.
-- - nombre_producto: Descripción oficial del producto.
-- - stock_total_disponible: Saldo disponible consolidado en bodega.
-- =====================================================================

SELECT 
    p.codigo_sku,
    p.nombre AS nombre_producto,
    COALESCE(SUM(i.cantidad_disponible), 0.00) AS stock_total_disponible
FROM producto p
LEFT JOIN inventario i 
    ON p.id_producto = i.producto_id
WHERE p.codigo_sku = 'SKU-LAP-001'
GROUP BY p.codigo_sku, p.nombre;
