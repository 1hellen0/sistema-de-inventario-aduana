-- =====================================================================
-- SISTEMA DE INVENTARIO ADUANERO — CONSULTAS SQL ANALÍTICAS
-- Consulta: Q4_importador_mayor_valor_cif.sql
-- Motor objetivo: MySQL 8.0.16+
-- =====================================================================
-- Propósito:
-- Identificar al operador comercial que acumula el mayor valor CIF total
-- en declaraciones aduaneras de importación, garantizando la exclusión
-- estricta de declaraciones de exportación.
--
-- Resolución de empates:
-- Se implementa una CTE con la función de ventana DENSE_RANK() sobre la
-- suma agregada de valor_total_cif. Si dos o más importadores estuviesen
-- empatados en el primer lugar con el mismo monto máximo, la consulta
-- retornará a ambos sin truncar arbitrariamente los resultados.
--
-- Columnas proyectadas:
-- - nombre_comercial: Nombre comercial del importador líder.
-- - valor_cif_acumulado: Sumatoria de valor en aduana CIF (USD).
-- =====================================================================

WITH ranking_cif_importadores AS (
    SELECT 
        oc.id_operador,
        oc.nombre_comercial,
        SUM(da.valor_total_cif) AS valor_cif_acumulado,
        DENSE_RANK() OVER (
            ORDER BY SUM(da.valor_total_cif) DESC
        ) AS ranking_posicion
    FROM declaracion_aduanera da
    INNER JOIN operador_comercial oc 
        ON da.operador_comercial_id = oc.id_operador
    WHERE da.tipo_declaracion = 'IMPORTACION'
    GROUP BY oc.id_operador, oc.nombre_comercial
)
SELECT 
    nombre_comercial,
    valor_cif_acumulado
FROM ranking_cif_importadores
WHERE ranking_posicion = 1;
