-- MAN-03 · Anexo C · Consultas de verificación para el mantenimiento
-- Probadas en el entorno académico local (PostgreSQL 16 + PostGIS 3.4) sobre la base creada con los scripts 01 a 03.

-- Q1. Triggers de reglas y auditoría habilitados (todos deben estar en 'O' = habilitado)
SELECT c.relnamespace::regnamespace AS esquema, c.relname AS tabla, t.tgname AS trigger, t.tgenabled AS estado
  FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
 WHERE NOT t.tgisinternal AND c.relnamespace::regnamespace::text IN ('catalogo','nucleo','referencia','auditoria')
   AND t.tgenabled <> 'O';

-- Q2. Geometrías no válidas (debe devolver 0: lo impide la restricción ck_geom_valida)
SELECT count(*) AS geometrias_invalidas FROM nucleo.geometria_intervencion WHERE NOT ST_IsValid(geom);

-- Q3. Vigencia de la copia de IDESC (alerta si alguna capa tiene más de 8 días)
SELECT 'comuna' AS capa, max(fecha_sincronizacion) AS ultima, now() - max(fecha_sincronizacion) > interval '8 days' AS vencida FROM referencia.comuna
UNION ALL SELECT 'espacio_publico', max(fecha_sincronizacion), now() - max(fecha_sincronizacion) > interval '8 days' FROM referencia.espacio_publico
UNION ALL SELECT 'infraestructura_vial', max(fecha_sincronizacion), now() - max(fecha_sincronizacion) > interval '8 days' FROM referencia.infraestructura_vial
UNION ALL SELECT 'zona_restriccion', max(fecha_sincronizacion), now() - max(fecha_sincronizacion) > interval '8 days' FROM referencia.zona_restriccion;

-- Q4. Antigüedad de las vistas materializadas del panel (deben tener menos de 15 minutos, HU-18)
SELECT 'mv_solicitudes_por_estado' AS vista, max(actualizado) AS actualizado, now() - max(actualizado) AS antiguedad FROM indicadores.mv_solicitudes_por_estado
UNION ALL SELECT 'mv_intervenciones_por_comuna', max(actualizado), now() - max(actualizado) FROM indicadores.mv_intervenciones_por_comuna;

-- Q5. Integraciones con error o pendientes en las últimas 24 horas (Tabla 68)
SELECT interfaz, resultado, count(*) AS total
  FROM auditoria.log_integracion
 WHERE fecha_hora > now() - interval '24 hours' AND resultado <> 'Exitoso'
 GROUP BY interfaz, resultado ORDER BY total DESC;

-- Q6. Notificaciones pendientes o fallidas
SELECT estado_envio, count(*) FROM nucleo.notificacion WHERE estado_envio <> 'Enviada' GROUP BY estado_envio;

-- Q7. Tamaño de la base de datos y de las tablas más grandes (seguimiento de capacidad, R-12)
SELECT pg_size_pretty(pg_database_size(current_database())) AS tamano_bd;
SELECT n.nspname AS esquema, c.relname AS tabla, pg_size_pretty(pg_total_relation_size(c.oid)) AS tamano
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE c.relkind = 'r' AND n.nspname IN ('catalogo','nucleo','referencia','auditoria')
 ORDER BY pg_total_relation_size(c.oid) DESC LIMIT 10;

-- Q8. Tablas con más filas muertas (candidatas a VACUUM)
SELECT schemaname AS esquema, relname AS tabla, n_live_tup AS vivas, n_dead_tup AS muertas, last_autovacuum, last_autoanalyze
  FROM pg_stat_user_tables
 WHERE schemaname IN ('catalogo','nucleo','referencia','auditoria')
 ORDER BY n_dead_tup DESC LIMIT 10;

-- Q9. Retraso de la réplica (ejecutar en el principal; sin filas si no hay réplica conectada)
SELECT client_addr, state, write_lag, flush_lag, replay_lag FROM pg_stat_replication;

-- Q10. Coherencia del historial: toda solicitud tiene al menos un registro de historial
SELECT count(*) AS solicitudes_sin_historial
  FROM nucleo.solicitud s
 WHERE NOT EXISTS (SELECT 1 FROM nucleo.historial_estado h WHERE h.id_solicitud = s.id_solicitud);

-- Q11. Estado de la extensión PostGIS (versión instalada frente a la disponible)
SELECT name, default_version, installed_version FROM pg_available_extensions WHERE name = 'postgis';
