-- =====================================================================
-- Sistema SIG para la Gestión de Intervenciones en el Espacio Público de Cali
-- Script 04 · Verificación del modelo (consultas y pruebas negativas)
-- ---------------------------------------------------------------------
-- Uso: después de 01, 02 y 03, sobre una base de PRUEBA (nunca producción).
-- Cada prueba negativa intenta violar una regla y debe ser RECHAZADA.
-- =====================================================================

\set ON_ERROR_STOP on
\pset footer off

\echo '== V-01 Inventario de objetos por esquema'
SELECT table_schema AS esquema, count(*) FILTER (WHERE table_type='BASE TABLE') AS tablas,
       count(*) FILTER (WHERE table_type='VIEW') AS vistas
  FROM information_schema.tables
 WHERE table_schema IN ('catalogo','nucleo','referencia','auditoria','publicacion','indicadores')
 GROUP BY 1 ORDER BY 1;

\echo '== V-02 Columnas geométricas y SRID'
SELECT f_table_schema AS esquema, f_table_name AS tabla, f_geometry_column AS columna, type AS tipo, srid
  FROM geometry_columns
 WHERE f_table_schema IN ('nucleo','referencia') ORDER BY 1,2;

\echo '== V-03 Relaciones espaciales calculadas por el trigger (comuna, vía, espacio público)'
SELECT r.numero_radicado, g.tipo_geometria, c.nombre AS comuna, v.nombre AS via, e.nombre AS espacio_publico
  FROM nucleo.geometria_intervencion g
  JOIN nucleo.radicacion r USING (id_solicitud)
  JOIN referencia.comuna c USING (id_comuna)
  LEFT JOIN referencia.infraestructura_vial v USING (id_infraestructura)
  LEFT JOIN referencia.espacio_publico e USING (id_espacio)
 ORDER BY 1;

\echo '== V-04 Detección de conflictos para 2027-0002 (HU-08)'
SELECT r2.numero_radicado AS coincide_con, c.tipo, c.nivel, c.distancia_m
  FROM nucleo.radicacion r, LATERAL nucleo.fn_detectar_conflictos(r.id_solicitud) c
  JOIN nucleo.radicacion r2 ON r2.id_solicitud = c.id_solicitud_relacionada
 WHERE r.numero_radicado = '2027-0002';

\echo '== V-05 Historial de estados de 2027-0001 (HU-12)'
SELECT h.fecha_hora::timestamp(0) AS fecha, e.nombre AS estado_nuevo, u.nombre_razon_social AS responsable, h.observacion
  FROM nucleo.historial_estado h
  JOIN catalogo.estado_tramite e ON e.id_estado = h.id_estado_nuevo
  JOIN nucleo.usuario u ON u.id_usuario = h.id_usuario
  JOIN nucleo.radicacion r ON r.id_solicitud = h.id_solicitud
 WHERE r.numero_radicado = '2027-0001' ORDER BY h.id_historial;

\echo '== V-06 Bitácora: eventos por entidad y acción'
SELECT entidad, accion, count(*) FROM auditoria.bitacora_auditoria GROUP BY 1,2 ORDER BY 1,2;

\echo '== V-07 Vista de publicación sin datos personales (SP-01)'
SELECT numero_radicado, tipo_intervencion, estado, comuna, ST_SRID(geom) AS srid FROM publicacion.v_intervenciones ORDER BY 1;

\echo '== V-08 Indicadores del panel (HU-18)'
SELECT estado, total FROM indicadores.mv_solicitudes_por_estado WHERE total > 0 ORDER BY estado;
SELECT comuna, total FROM indicadores.mv_intervenciones_por_comuna ORDER BY comuna;

\echo '== V-09 Pruebas negativas (cada una debe imprimir RECHAZADA)'
DO $$
DECLARE
    v_sol integer := (SELECT id_solicitud FROM nucleo.radicacion WHERE numero_radicado='2027-0001');
    v_sol3 integer := (SELECT id_solicitud FROM nucleo.radicacion WHERE numero_radicado='2027-0003');
    v_insp integer := (SELECT id_usuario FROM nucleo.usuario WHERE id_externo_idp='sim-idp-0201');
    v_coord text := (SELECT id_usuario FROM nucleo.usuario WHERE id_externo_idp='sim-idp-0301')::text;
BEGIN
    PERFORM set_config('app.id_usuario', v_coord, true);

    -- N-01 Modificar el historial
    BEGIN
        UPDATE nucleo.historial_estado SET observacion = 'alterada' WHERE id_solicitud = v_sol;
        RAISE NOTICE 'N-01 historial editable ............ ACEPTADA (ERROR DEL MODELO)';
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'N-01 editar historial ............. RECHAZADA: %', SQLERRM; END;

    -- N-02 Borrar la bitácora
    BEGIN
        DELETE FROM auditoria.bitacora_auditoria;
        RAISE NOTICE 'N-02 bitácora borrable ............. ACEPTADA (ERROR DEL MODELO)';
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'N-02 borrar bitácora .............. RECHAZADA: %', SQLERRM; END;

    -- N-03 Transición inválida Radicada → Finalizada
    BEGIN
        UPDATE nucleo.solicitud SET id_estado = (SELECT id_estado FROM catalogo.estado_tramite WHERE nombre='Finalizada')
         WHERE id_solicitud = v_sol3;
        RAISE NOTICE 'N-03 transición inválida ........... ACEPTADA (ERROR DEL MODELO)';
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'N-03 Radicada → Finalizada ........ RECHAZADA: %', SQLERRM; END;

    -- N-04 Cuarta visita técnica
    BEGIN
        INSERT INTO nucleo.visita_tecnica (id_solicitud, id_inspector, fecha_programada, motivo)
        SELECT v_sol, v_insp, DATE '2026-11-01', 'prueba ' || n FROM generate_series(1,3) n;
        RAISE NOTICE 'N-04 cuarta visita ................. ACEPTADA (ERROR DEL MODELO)';
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'N-04 cuarta visita ................ RECHAZADA: %', SQLERRM; END;

    -- N-05 Geometría fuera del perímetro (Bogotá)
    BEGIN
        INSERT INTO nucleo.geometria_intervencion (id_solicitud, tipo_geometria, geom, fuente_origen)
        VALUES (v_sol3, 'Punto', ST_Transform(ST_SetSRID(ST_MakePoint(-74.07, 4.71),4326),9377), 'Coordenadas');
        RAISE NOTICE 'N-05 fuera del perímetro ........... ACEPTADA (ERROR DEL MODELO)';
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'N-05 geometría fuera de Cali ...... RECHAZADA: %', SQLERRM; END;

    -- N-06 Detalle que no corresponde al tipo (cierre sobre una excavación)
    BEGIN
        INSERT INTO nucleo.cierre (id_solicitud, modalidad) VALUES (v_sol, 'Total');
        RAISE NOTICE 'N-06 detalle de otro tipo .......... ACEPTADA (ERROR DEL MODELO)';
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'N-06 detalle de otro tipo ......... RECHAZADA: %', SQLERRM; END;

    -- N-07 Rechazo sin observación
    BEGIN
        INSERT INTO nucleo.revision_tecnica (id_solicitud, id_revisor, decision)
        VALUES (v_sol3, (SELECT id_usuario FROM nucleo.usuario WHERE id_externo_idp='sim-idp-0101'), 'Rechazada');
        RAISE NOTICE 'N-07 rechazo sin observación ....... ACEPTADA (ERROR DEL MODELO)';
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'N-07 rechazo sin observación ...... RECHAZADA: %', SQLERRM; END;

    -- N-08 Geometría que no coincide con su tipo declarado
    BEGIN
        INSERT INTO nucleo.geometria_intervencion (id_solicitud, tipo_geometria, geom, fuente_origen)
        VALUES (v_sol3, 'Polígono', ST_Transform(ST_SetSRID(ST_MakePoint(-76.523, 3.444),4326),9377), 'Coordenadas');
        RAISE NOTICE 'N-08 tipo de geometría incoherente . ACEPTADA (ERROR DEL MODELO)';
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'N-08 tipo de geometría incoherente  RECHAZADA: %', SQLERRM; END;

    -- N-09 Fotografía de más de 2,5 MB
    BEGIN
        INSERT INTO nucleo.evidencia (id_visita, tipo, ruta_objeto, tamano_mb, fecha_captura)
        SELECT id_visita, 'Fotografía', 'sim/x.jpg', 4.0, now() FROM nucleo.visita_tecnica WHERE id_solicitud = v_sol LIMIT 1;
        RAISE NOTICE 'N-09 foto > 2,5 MB ................. ACEPTADA (ERROR DEL MODELO)';
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'N-09 foto > 2,5 MB ................ RECHAZADA: %', SQLERRM; END;

    -- N-10 Fecha de fin anterior a la de inicio
    BEGIN
        UPDATE nucleo.solicitud SET fecha_fin = fecha_inicio - 1 WHERE id_solicitud = v_sol3;
        RAISE NOTICE 'N-10 fechas invertidas ............. ACEPTADA (ERROR DEL MODELO)';
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'N-10 fechas invertidas ............ RECHAZADA: %', SQLERRM; END;
END $$;

\echo '== V-10 Uso del índice espacial en la consulta de proximidad (RNF-03)'
SET enable_seqscan = off;   -- con 3 filas el planificador prefiere recorrido secuencial; se fuerza para mostrar que el índice es utilizable
EXPLAIN (COSTS OFF)
SELECT g2.id_solicitud
  FROM nucleo.geometria_intervencion g1
  JOIN nucleo.geometria_intervencion g2 ON ST_DWithin(g1.geom, g2.geom, 50) AND g2.id_solicitud <> g1.id_solicitud
 WHERE g1.id_solicitud = 2;
RESET enable_seqscan;

\echo '== V-11 Totales'
SELECT (SELECT count(*) FROM information_schema.tables WHERE table_type='BASE TABLE'
          AND table_schema IN ('catalogo','nucleo','referencia','auditoria')) AS tablas_fisicas,
       (SELECT count(*) FROM pg_matviews WHERE schemaname='indicadores') AS vistas_materializadas,
       (SELECT count(*) FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace
          WHERE NOT t.tgisinternal AND n.nspname IN ('catalogo','nucleo','referencia','auditoria')) AS triggers,
       (SELECT postgis_lib_version()) AS postgis, current_setting('server_version') AS postgresql;
