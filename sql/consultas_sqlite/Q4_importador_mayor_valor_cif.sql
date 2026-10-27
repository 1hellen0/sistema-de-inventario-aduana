-- =====================================================================
-- SISTEMA DE INVENTARIO ADUANERO — CONSULTAS SQL ANALÍTICAS (SQLITE)
-- Consulta: Q4_importador_mayor_valor_cif.sql
-- Motor objetivo: SQLite 3.31.0+
-- =====================================================================
-- Propósito:
-- Determinar el importador con el mayor monto acumulado de valor CIF
-- en declaraciones aduaneras de tipo 'IMPORTACION'.
--
-- Prevención de duplicación:
-- Se agrega directamente desde 'declaracion_aduanera' sin hacer JOIN
-- con 'detalle_declaracion', evitando la duplicación del total_cif por cada línea.
--
-- Resolución de empates:
-- Utiliza DENSE_RANK() OVER (ORDER BY COALESCE(SUM(da.valor_total_cif), 0.00) DESC)
-- retornando a todos los líderes empatados en ranking_cif = 1.
--
-- Columnas proyectadas:
-- - numero_identificacion: Cédula jurídica o tributaria del importador.
-- - importador: Razón social del operador comercial.
-- - total_cif_acumulado: Sumatoria del valor CIF de importaciones.
-- =====================================================================

WITH ranking_importadores AS (
    SELECT 
        op.id_operador,
        op.numero_identificacion,
        op.razon_social AS importador,
        COALESCE(SUM(da.valor_total_cif), 0.00) AS total_cif_acumulado,
        DENSE_RANK() OVER (
            ORDER BY COALESCE(SUM(da.valor_total_cif), 0.00) DESC
        ) AS ranking_cif
    FROM operador_comercial op
    INNER JOIN declaracion_aduanera da 
        ON op.id_operador = da.operador_comercial_id
    WHERE da.tipo_declaracion = 'IMPORTACION'
    GROUP BY op.id_operador, op.numero_identificacion, op.razon_social
)
SELECT 
    numero_identificacion,
    importador,
    total_cif_acumulado
FROM ranking_importadores
WHERE ranking_cif = 1;
