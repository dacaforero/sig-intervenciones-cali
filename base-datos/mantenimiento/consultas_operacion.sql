-- =====================================================================
-- MAN-02 · Consultas de operación diaria (anexo B del manual de operación)
-- Sistema SIG de Intervenciones en el Espacio Público de Cali · Taller 3
-- Solo lectura. Se ejecutan con una cuenta de consulta (por ejemplo, la del
-- rol sigep_auditor o una cuenta de lectura que defina el ANS), nunca con
-- el superusuario. Probadas en ENTORNO ACADÉMICO LOCAL con los datos
-- simulados del script 03; los umbrales son los del Taller 2.
-- =====================================================================

-- O1. Bandeja por estado: cuántas solicitudes hay en cada estado y cuánto
--     llevan en él (desde su último cambio de estado).
WITH ultimo AS (
  SELECT DISTINCT ON (id_solicitud) id_solicitud, fecha_hora
    FROM nucleo.historial_estado ORDER BY id_solicitud, fecha_hora DESC, id_historial DESC)
SELECT e.orden, e.nombre AS estado, count(s.id_solicitud) AS solicitudes,
       max(now() - u.fecha_hora) AS mayor_permanencia
  FROM catalogo.estado_tramite e
  LEFT JOIN nucleo.solicitud s ON s.id_estado = e.id_estado
  LEFT JOIN ultimo u ON u.id_solicitud = s.id_solicitud
 GROUP BY e.orden, e.nombre ORDER BY e.orden;

-- O2. Solicitudes radicadas o en revisión sin revisor asignado.
SELECT r.numero_radicado, e.nombre AS estado, r.fecha_hora AS radicada
  FROM nucleo.solicitud s
  JOIN nucleo.radicacion r USING (id_solicitud)
  JOIN catalogo.estado_tramite e ON e.id_estado = s.id_estado
 WHERE s.id_revisor IS NULL AND e.nombre IN ('Radicada', 'En revisión')
 ORDER BY r.fecha_hora;

-- O3. Subsanaciones con plazo vencido (5 días hábiles, Taller 2 Tabla 64).
--     Aproximación: cuenta lunes a viernes. El calendario de festivos es un
--     catálogo previsto en el Taller 2 que el modelo v1 aún no tiene (pendiente).
WITH ultimo AS (
  SELECT DISTINCT ON (id_solicitud) id_solicitud, fecha_hora
    FROM nucleo.historial_estado ORDER BY id_solicitud, fecha_hora DESC, id_historial DESC)
SELECT r.numero_radicado, u.fecha_hora AS desde,
       (SELECT count(*) FROM generate_series(u.fecha_hora::date + 1, current_date, '1 day') d
         WHERE extract(isodow FROM d) < 6) AS dias_habiles
  FROM nucleo.solicitud s
  JOIN catalogo.estado_tramite e ON e.id_estado = s.id_estado AND e.nombre = 'Subsanación requerida'
  JOIN ultimo u USING (id_solicitud)
  JOIN nucleo.radicacion r USING (id_solicitud)
 WHERE (SELECT count(*) FROM generate_series(u.fecha_hora::date + 1, current_date, '1 day') d
         WHERE extract(isodow FROM d) < 6) > 5;

-- O4. Alertas de duplicidad o conflicto de las últimas 24 horas, por nivel.
SELECT a.tipo, a.nivel, count(*) AS alertas, min(a.distancia_m) AS menor_distancia_m
  FROM nucleo.alerta_conflicto a
 WHERE a.fecha_deteccion > now() - interval '24 hours'
 GROUP BY a.tipo, a.nivel ORDER BY a.nivel;

-- O5. Visitas programadas para fechas pasadas que siguen sin iniciar.
SELECT r.numero_radicado, v.fecha_programada, v.id_inspector, v.estado_implementacion
  FROM nucleo.visita_tecnica v
  JOIN nucleo.radicacion r USING (id_solicitud)
 WHERE v.fecha_programada < current_date
   AND coalesce(v.estado_implementacion, 'No iniciada') = 'No iniciada'
 ORDER BY v.fecha_programada;

-- O6. Visitas registradas con precisión GPS peor que la de advertencia (10 m, RNF-18).
SELECT r.numero_radicado, v.fecha_registro, v.precision_gps_m
  FROM nucleo.visita_tecnica v
  JOIN nucleo.radicacion r USING (id_solicitud)
 WHERE v.precision_gps_m > 10
 ORDER BY v.fecha_registro DESC;

-- O7. Elementos de integración con error, candidatos a reenvío manual (HU-21).
--     Tabla 68: tras los reintentos se reprocesan cada 30 min hasta 24 h;
--     lo que siga en error después de 24 h requiere acción del administrador.
SELECT l.interfaz, l.id_correlacion, l.id_solicitud, l.reintentos, l.fecha_hora,
       now() - l.fecha_hora > interval '24 hours' AS requiere_accion_manual
  FROM auditoria.log_integracion l
 WHERE l.resultado = 'Error'
   AND NOT EXISTS (SELECT 1 FROM auditoria.log_integracion x
                    WHERE x.id_correlacion = l.id_correlacion AND x.resultado = 'Exitoso'
                      AND x.fecha_hora > l.fecha_hora)
 ORDER BY l.fecha_hora;

-- O8. Usuarios activos por rol (insumo de la revisión semestral de accesos, Taller 2 §10.3).
SELECT ro.nombre AS rol, ro.activo AS rol_activo, count(u.id_usuario) FILTER (WHERE u.activo) AS usuarios_activos
  FROM catalogo.rol ro LEFT JOIN nucleo.usuario u ON u.id_rol = ro.id_rol
 GROUP BY ro.id_rol, ro.nombre, ro.activo ORDER BY ro.id_rol;

-- O9. Solicitantes que no verificaron el correo en 24 horas (HU-01).
SELECT count(*) AS cuentas_sin_verificar
  FROM nucleo.usuario u JOIN catalogo.rol ro ON ro.id_rol = u.id_rol
 WHERE ro.nombre = 'Solicitante externo' AND NOT u.correo_verificado
   AND u.fecha_registro < now() - interval '24 hours';

-- O10. Radicaciones del día por canal (seguimiento de la operación).
SELECT canal, count(*) AS radicaciones
  FROM nucleo.radicacion WHERE fecha_hora >= current_date AND fecha_hora < current_date + 1
 GROUP BY canal ORDER BY radicaciones DESC;
