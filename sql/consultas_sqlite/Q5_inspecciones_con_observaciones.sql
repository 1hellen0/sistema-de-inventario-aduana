-- =====================================================================
-- SISTEMA DE INVENTARIO ADUANERO — CONSULTAS SQL ANALÍTICAS (SQLITE)
-- Consulta: Q5_inspecciones_con_observaciones.sql
-- Motor objetivo: SQLite 3.31.0+
-- =====================================================================
-- Propósito:
-- Obtener las actas de inspección aduanera que registraron observaciones
-- o incidencias (tuvo_observaciones = 1 / TRUE), detallando los funcionarios
-- responsables y las declaraciones vinculadas.
--
-- Columnas proyectadas:
-- - numero_acta: Identificador oficial del acta de aforo.
-- - fecha_inspeccion: Marca temporal de la inspección.
-- - numero_declaracion: DUA/pedimento objeto de inspección.
-- - tipo_inspeccion: Modalidad de inspección aduanera.
-- - resultado: Calificación del resultado aduanero.
-- - funcionario_inspector: Nombre del funcionario actuante.
-- - id_funcionario: Código de empleado del funcionario.
-- - observaciones: Hallazgos o inconsistencias registradas.
-- - acciones_tomadas: Medidas cautelares o resoluciones.
-- =====================================================================

SELECT 
    ia.numero_acta,
    ia.fecha_inspeccion,
    da.numero_declaracion,
    ia.tipo_inspeccion,
    ia.resultado,
    f.nombre_completo AS funcionario_inspector,
    f.identificacion AS id_funcionario,
    ia.observaciones,
    ia.acciones_tomadas
FROM inspeccion_aduanera ia
INNER JOIN funcionario f 
    ON ia.funcionario_id = f.id_funcionario
INNER JOIN declaracion_aduanera da 
    ON ia.declaracion_id = da.id_declaracion
WHERE ia.tuvo_observaciones = 1
ORDER BY ia.fecha_inspeccion DESC;
