-- =====================================================================
-- SISTEMA DE INVENTARIO ADUANERO — CONSULTAS SQL ANALÍTICAS
-- Consulta: Q2_importaciones_octubre_2026.sql
-- Motor objetivo: MySQL 8.0.16+
-- =====================================================================
-- Propósito:
-- Mostrar las declaraciones de importación registradas entre el 1 y el 31
-- de octubre de 2026, abarcando la totalidad del mes sin depender de la
-- hora del registro.
--
-- Técnica de filtrado temporal:
-- Se utiliza un intervalo semiabierto [2026-10-01 00:00:00, 2026-11-01 00:00:00),
-- que captura de forma exacta hasta el último microsegundo de octubre de 2026
-- permitiendo que MySQL aproveche el índice compuesto (tipo_declaracion, fecha_registro)
-- sin la penalización de funciones como YEAR() o MONTH() sobre la columna.
--
-- Columnas proyectadas:
-- - numero_declaracion: Identificador documental oficial del DUA.
-- - fecha: Timestamp de radicación ante el sistema aduanero.
-- - importador: Nombre comercial del consignatario/operador.
-- - agente_aduanero: Nombre completo del agente aduanal refrendante.
-- - canal_aforo: Semáforo fiscal asignado (VERDE, AMARILLO, ROJO).
-- - estado: Estado del trámite aduanero.
-- - valor_total_cif: Monto total imponible en aduana (USD).
-- =====================================================================

SELECT 
    da.numero_declaracion,
    da.fecha_registro AS fecha,
    oc.nombre_comercial AS importador,
    aa.nombre_completo AS agente_aduanero,
    da.canal_aforo,
    da.estado,
    da.valor_total_cif
FROM declaracion_aduanera da
INNER JOIN operador_comercial oc 
    ON da.operador_comercial_id = oc.id_operador
INNER JOIN agente_aduanero aa 
    ON da.agente_aduanero_id = aa.id_agente
WHERE da.tipo_declaracion = 'IMPORTACION'
  AND da.fecha_registro >= '2026-10-01 00:00:00'
  AND da.fecha_registro < '2026-11-01 00:00:00'
ORDER BY da.fecha_registro ASC;
