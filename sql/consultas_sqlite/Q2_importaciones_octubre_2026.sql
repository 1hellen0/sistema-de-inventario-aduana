-- =====================================================================
-- SISTEMA DE INVENTARIO ADUANERO — CONSULTAS SQL ANALÍTICAS (SQLITE)
-- Consulta: Q2_importaciones_octubre_2026.sql
-- Motor objetivo: SQLite 3.31.0+
-- =====================================================================
-- Propósito:
-- Listar las declaraciones aduaneras de importación registradas en
-- octubre de 2026, ordenadas cronológicamente.
--
-- Criterio de rango temporal:
-- Se utiliza comparación semi-abierta [2026-10-01 00:00:00, 2026-11-01 00:00:00)
-- garantizando la cobertura de todos los microsegundos del mes.
--
-- Columnas proyectadas:
-- - numero_declaracion: Identificador oficial del DUA/pedimento.
-- - fecha_registro: Marca temporal de registro aduanero.
-- - importador: Razón social del importador.
-- - canal_aforo: Canal asignado ('VERDE', 'AMARILLO', 'ROJO').
-- - valor_total_cif: Valor CIF total liquidado en la declaración.
-- =====================================================================

SELECT 
    da.numero_declaracion,
    da.fecha_registro,
    op.razon_social AS importador,
    da.canal_aforo,
    da.valor_total_cif
FROM declaracion_aduanera da
INNER JOIN operador_comercial op 
    ON da.operador_comercial_id = op.id_operador
WHERE da.tipo_declaracion = 'IMPORTACION'
  AND da.fecha_registro >= '2026-10-01 00:00:00'
  AND da.fecha_registro <  '2026-11-01 00:00:00'
ORDER BY da.fecha_registro ASC;
