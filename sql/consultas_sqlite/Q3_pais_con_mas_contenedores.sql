-- =====================================================================
-- SISTEMA DE INVENTARIO ADUANERO — CONSULTAS SQL ANALÍTICAS (SQLITE)
-- Consulta: Q3_pais_con_mas_contenedores.sql
-- Motor objetivo: SQLite 3.31.0+
-- =====================================================================
-- Propósito:
-- Identificar el país de origen con la mayor cantidad de unidades de
-- transporte intermodal (contenedores) en estado 'RECIBIDO_EN_PUERTO'.
--
-- Resolución de empates:
-- Utiliza Common Table Expression (CTE) con DENSE_RANK() OVER (ORDER BY COUNT(...) DESC)
-- para retornar todos los países empatados en el primer lugar (ranking_posicion = 1).
--
-- Columnas proyectadas:
-- - pais: Nombre del país de origen.
-- - total_contenedores: Conteo total de contenedores recibidos en puerto.
-- =====================================================================

WITH ranking_contenedores_pais AS (
    SELECT 
        p.id_pais,
        p.nombre AS pais,
        COUNT(c.id_contenedor) AS total_contenedores,
        DENSE_RANK() OVER (
            ORDER BY COUNT(c.id_contenedor) DESC
        ) AS ranking_posicion
    FROM contenedor c
    INNER JOIN pais p 
        ON c.pais_origen_id = p.id_pais
    WHERE c.estado = 'RECIBIDO_EN_PUERTO'
    GROUP BY p.id_pais, p.nombre
)
SELECT 
    pais,
    total_contenedores
FROM ranking_contenedores_pais
WHERE ranking_posicion = 1;
