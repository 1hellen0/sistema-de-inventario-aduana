-- =====================================================================
-- SISTEMA DE INVENTARIO ADUANERO — CONSULTAS SQL ANALÍTICAS
-- Consulta: Q3_pais_con_mas_contenedores.sql
-- Motor objetivo: MySQL 8.0.16+
-- =====================================================================
-- Propósito:
-- Identificar el país de origen con la mayor cantidad de unidades de
-- transporte intermodal (contenedores) en estado 'RECIBIDO_EN_PUERTO'.
--
-- Resolución de empates:
-- En caso de que dos o más países compartan el número máximo de contenedores,
-- una cláusula simple 'LIMIT 1' descartaría arbitrariamente a los demás.
-- Para resolverlo rigurosamente conforme a las mejores prácticas de MySQL 8,
-- se emplea una Common Table Expression (CTE) combinada con la función de
-- ventana DENSE_RANK(). Esta estrategia retorna a todos los países que ocupen
-- la primera posición (ranking = 1) sin omitir a ninguno.
--
-- Columnas proyectadas:
-- - pais: Nombre oficial del país de origen de las unidades recibidas.
-- - total_contenedores: Conteo total de contenedores en puerto.
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
