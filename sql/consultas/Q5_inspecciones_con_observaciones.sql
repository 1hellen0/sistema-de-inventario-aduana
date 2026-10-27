-- =====================================================================
-- SISTEMA DE INVENTARIO ADUANERO — CONSULTAS SQL ANALÍTICAS
-- Consulta: Q5_inspecciones_con_observaciones.sql
-- Motor objetivo: MySQL 8.0.16+
-- =====================================================================
-- Propósito:
-- Mostrar las inspecciones aduaneras en las que se detectaron inconsistencias,
-- presuntas irregularidades o faltantes documentales (tuvo_observaciones = TRUE),
-- detallando el funcionario fiscalizador responsable y la declaración afectada.
--
-- Columnas proyectadas:
-- - numero_acta: Folio único del acta oficial de reconocimiento/aforo.
-- - fecha: Fecha y hora en que se practicó la inspección.
-- - tipo_inspeccion: Modalidad (FISICA_INTRUSIVA, DOCUMENTAL, SCANNER).
-- - resultado: Calificación del dictamen fiscal.
-- - funcionario_responsable: Nombre del inspector aduanero actuante.
-- - cargo: Puesto oficial del funcionario.
-- - numero_declaracion: DUA sometido a fiscalización.
-- - observaciones: Glosa descriptiva detallada con las irregularidades.
-- =====================================================================

SELECT 
    ia.numero_acta,
    ia.fecha_inspeccion AS fecha,
    ia.tipo_inspeccion,
    ia.resultado,
    f.nombre_completo AS funcionario_responsable,
    f.cargo,
    da.numero_declaracion,
    ia.observaciones
FROM inspeccion_aduanera ia
INNER JOIN funcionario f 
    ON ia.funcionario_id = f.id_funcionario
INNER JOIN declaracion_aduanera da 
    ON ia.declaracion_id = da.id_declaracion
WHERE ia.tuvo_observaciones = TRUE
ORDER BY ia.fecha_inspeccion ASC;
