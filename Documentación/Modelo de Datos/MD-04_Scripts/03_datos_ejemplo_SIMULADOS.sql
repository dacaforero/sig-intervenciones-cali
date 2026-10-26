-- =====================================================================
-- Sistema SIG para la Gestión de Intervenciones en el Espacio Público de Cali
-- Script 03 · Datos de ejemplo — SIMULACIÓN ACADÉMICA
-- ---------------------------------------------------------------------
-- ATENCIÓN: TODOS los datos de este script son FICTICIOS y existen solo
-- para demostrar el funcionamiento del modelo en el Taller 3.
--  · Las capas de referencia NO son las de IDESC: son polígonos y líneas
--    simplificados dibujados cerca del centro de Cali, con prefijo «SIM».
--  · Personas, empresas, documentos y correos son inventados; los correos
--    usan el dominio reservado example.org (RFC 2606).
--  · Ningún dato debe cargarse en producción (Ley 1581 de 2012; Tabla 42
--    del Taller 2: ambientes no productivos solo con datos sintéticos).
-- Calendario simulado: semana 1 del proyecto = 2026-11-02; los datos
-- corresponden a la fase F3 (semanas 31-38: 2027-05-31 a 2027-07-23).
-- Requisito: 01 y 02 ejecutados.
-- =====================================================================

\set ON_ERROR_STOP on
\o /dev/null
BEGIN;
SET LOCAL app.origen = 'Servicio de integración';

-- ---------------------------------------------------------------------
-- 1. Capas de referencia simuladas (en WGS 84 y transformadas a EPSG:9377)
-- ---------------------------------------------------------------------
INSERT INTO referencia.comuna (codigo, nombre, geom, id_origen_idesc) VALUES
 ('SIM-01', 'Comuna simulada 01',
  ST_Multi(ST_Transform(ST_GeomFromText('POLYGON((-76.545 3.440,-76.530 3.440,-76.530 3.455,-76.545 3.455,-76.545 3.440))',4326),9377)), 'SIM-C01'),
 ('SIM-02', 'Comuna simulada 02',
  ST_Multi(ST_Transform(ST_GeomFromText('POLYGON((-76.530 3.440,-76.515 3.440,-76.515 3.455,-76.530 3.455,-76.530 3.440))',4326),9377)), 'SIM-C02');

INSERT INTO referencia.infraestructura_vial (tipo_elemento, nombre, jerarquia, geom, id_origen_idesc) VALUES
 ('Corredor', 'Corredor simulado SIM-V1', 'Arteria principal',
  ST_Multi(ST_Transform(ST_GeomFromText('LINESTRING(-76.544 3.4475,-76.516 3.4475)',4326),9377)), 'SIM-V1'),
 ('Tramo', 'Tramo simulado SIM-V2', 'Colectora',
  ST_Multi(ST_Transform(ST_GeomFromText('LINESTRING(-76.522 3.441,-76.522 3.454)',4326),9377)), 'SIM-V2');

INSERT INTO referencia.espacio_publico (tipo, nombre, geom, id_origen_idesc) VALUES
 ('Parque', 'Parque simulado SIM-P1',
  ST_Multi(ST_Transform(ST_GeomFromText('POLYGON((-76.520 3.450,-76.517 3.450,-76.517 3.453,-76.520 3.453,-76.520 3.450))',4326),9377)), 'SIM-P1'),
 ('Andén', 'Andén simulado SIM-A1',
  ST_Multi(ST_Transform(ST_GeomFromText('POLYGON((-76.5235 3.4430,-76.5225 3.4430,-76.5225 3.4460,-76.5235 3.4460,-76.5235 3.4430))',4326),9377)), 'SIM-A1');

INSERT INTO referencia.zona_restriccion (tipo, nombre, geom, id_origen_idesc) VALUES
 ('Zona patrimonial', 'Zona de restricción simulada SIM-Z1',
  ST_Multi(ST_Transform(ST_GeomFromText('POLYGON((-76.540 3.451,-76.535 3.451,-76.535 3.454,-76.540 3.454,-76.540 3.451))',4326),9377)), 'SIM-Z1');

-- ---------------------------------------------------------------------
-- 2. Usuarios simulados
-- ---------------------------------------------------------------------
INSERT INTO nucleo.usuario (id_rol, id_externo_idp, tipo_identificacion, identificacion, nombre_razon_social, correo, correo_verificado, acepta_politica_datos)
SELECT r.id_rol, u.idp, u.tipo, u.ident, u.nombre, u.correo, true, true
  FROM (VALUES
   ('Solicitante externo',       'sim-idp-0001', 'NIT', 'SIM-900000001', 'Empresa de Redes Simulada S.A.S.',  'radicacion@redes-sim.example.org'),
   ('Solicitante externo',       'sim-idp-0002', 'NIT', 'SIM-900000002', 'Constructora Ficticia Ltda.',       'tramites@constructora-sim.example.org'),
   ('Revisor técnico',           'sim-idp-0101', 'CC',  'SIM-1000000101','Revisor Simulado Uno',              'revisor1@sig-sim.example.org'),
   ('Inspector de campo',        'sim-idp-0201', 'CC',  'SIM-1000000201','Inspector Simulado Uno',            'inspector1@sig-sim.example.org'),
   ('Coordinador funcional',     'sim-idp-0301', 'CC',  'SIM-1000000301','Coordinadora Simulada Uno',         'coordinacion@sig-sim.example.org'),
   ('Administrador tecnológico', 'sim-idp-0401', 'CC',  'SIM-1000000401','Administrador Simulado Uno',        'admin1@sig-sim.example.org')
  ) AS u(rol, idp, tipo, ident, nombre, correo)
  JOIN catalogo.rol r ON r.nombre = u.rol;

-- ---------------------------------------------------------------------
-- 3. Solicitudes simuladas
--    S1 excavación y S2 cierre se superponen en el corredor SIM-V1 y en
--    fechas → debe aparecer un conflicto. S3 está en otra comuna y fecha.
-- ---------------------------------------------------------------------
-- El usuario de sesión para el historial es el propio solicitante al radicar
SELECT set_config('app.id_usuario', (SELECT id_usuario FROM nucleo.usuario WHERE id_externo_idp='sim-idp-0001')::text, true);
SELECT set_config('app.origen', 'Portal web', true);

WITH s AS (
  INSERT INTO nucleo.solicitud (id_solicitante, id_tipo, id_estado, descripcion, entidad_responsable, contacto, fecha_inicio, fecha_fin)
  SELECT u.id_usuario, t.id_tipo, e.id_estado,
         'SIMULADO. Excavación para reposición de tubería sobre el corredor SIM-V1.',
         'Empresa de Redes Simulada S.A.S.', 'Contacto simulado · radicacion@redes-sim.example.org',
         DATE '2027-07-12', DATE '2027-07-30'
    FROM nucleo.usuario u, catalogo.tipo_intervencion t, catalogo.estado_tramite e
   WHERE u.id_externo_idp='sim-idp-0001' AND t.nombre='Excavación' AND e.nombre='Radicada'
  RETURNING id_solicitud)
INSERT INTO nucleo.geometria_intervencion (id_solicitud, tipo_geometria, geom, fuente_origen)
SELECT id_solicitud, 'Línea',
       ST_Transform(ST_GeomFromText('LINESTRING(-76.535 3.4475,-76.528 3.4475)',4326),9377), 'KML/KMZ'
  FROM s;

INSERT INTO nucleo.radicacion (id_solicitud, numero_radicado, canal, fecha_hora, comprobante)
SELECT max(id_solicitud), '2027-0001', 'Portal web', TIMESTAMPTZ '2027-07-01 10:05-05', 'sim/comprobantes/2027-0001.pdf' FROM nucleo.solicitud;
INSERT INTO nucleo.excavacion (id_solicitud, profundidad_m, longitud_m, tipo_relleno)
SELECT max(id_solicitud), 1.50, 770, 'Material granular compactado (simulado)' FROM nucleo.solicitud;

SELECT set_config('app.id_usuario', (SELECT id_usuario FROM nucleo.usuario WHERE id_externo_idp='sim-idp-0002')::text, true);
WITH s AS (
  INSERT INTO nucleo.solicitud (id_solicitante, id_tipo, id_estado, descripcion, entidad_responsable, contacto, fecha_inicio, fecha_fin)
  SELECT u.id_usuario, t.id_tipo, e.id_estado,
         'SIMULADO. Cierre parcial de un carril para izaje de materiales.',
         'Constructora Ficticia Ltda.', 'Contacto simulado · tramites@constructora-sim.example.org',
         DATE '2027-07-19', DATE '2027-07-21'
    FROM nucleo.usuario u, catalogo.tipo_intervencion t, catalogo.estado_tramite e
   WHERE u.id_externo_idp='sim-idp-0002' AND t.nombre='Cierre' AND e.nombre='Radicada'
  RETURNING id_solicitud)
INSERT INTO nucleo.geometria_intervencion (id_solicitud, tipo_geometria, geom, fuente_origen)
SELECT id_solicitud, 'Polígono',
       ST_Transform(ST_GeomFromText('POLYGON((-76.5305 3.4472,-76.5295 3.4472,-76.5295 3.4478,-76.5305 3.4478,-76.5305 3.4472))',4326),9377),
       'Dibujo en mapa'
  FROM s;
INSERT INTO nucleo.radicacion (id_solicitud, numero_radicado, canal, fecha_hora, comprobante)
SELECT max(id_solicitud), '2027-0002', 'Portal web', TIMESTAMPTZ '2027-07-02 08:30-05', 'sim/comprobantes/2027-0002.pdf' FROM nucleo.solicitud;
INSERT INTO nucleo.cierre (id_solicitud, modalidad, carriles_afectados, horario)
SELECT max(id_solicitud), 'Parcial', 1, '22:00 a 05:00 (simulado)' FROM nucleo.solicitud;

WITH s AS (
  INSERT INTO nucleo.solicitud (id_solicitante, id_tipo, id_estado, descripcion, entidad_responsable, contacto, fecha_inicio, fecha_fin)
  SELECT u.id_usuario, t.id_tipo, e.id_estado,
         'SIMULADO. Ocupación temporal de andén para acopio de materiales.',
         'Constructora Ficticia Ltda.', 'Contacto simulado · tramites@constructora-sim.example.org',
         DATE '2027-08-02', DATE '2027-08-13'
    FROM nucleo.usuario u, catalogo.tipo_intervencion t, catalogo.estado_tramite e
   WHERE u.id_externo_idp='sim-idp-0002' AND t.nombre='Ocupación de andén' AND e.nombre='Radicada'
  RETURNING id_solicitud)
INSERT INTO nucleo.geometria_intervencion (id_solicitud, tipo_geometria, geom, fuente_origen)
SELECT id_solicitud, 'Polígono',
       ST_Transform(ST_GeomFromText('POLYGON((-76.5233 3.4440,-76.5227 3.4440,-76.5227 3.4446,-76.5233 3.4446,-76.5233 3.4440))',4326),9377),
       'Dibujo en mapa'
  FROM s;
INSERT INTO nucleo.radicacion (id_solicitud, numero_radicado, canal, fecha_hora, comprobante)
SELECT max(id_solicitud), '2027-0003', 'Módulo móvil', TIMESTAMPTZ '2027-07-05 16:20-05', 'sim/comprobantes/2027-0003.pdf' FROM nucleo.solicitud;
INSERT INTO nucleo.ocupacion_anden (id_solicitud, motivo, area_m2, ancho_libre_m)
SELECT max(id_solicitud), 'Acopio de materiales (simulado)', 36, 1.50 FROM nucleo.solicitud;

-- Archivos simulados (checksums ficticios en formato SHA-256)
INSERT INTO nucleo.archivo (id_solicitud, id_tipo_doc, nombre_original, formato, ruta_objeto, tamano_mb, checksum)
SELECT r.id_solicitud, td.id_tipo_doc, a.nombre, a.formato, 'sim/solicitudes/' || r.numero_radicado || '/' || a.nombre, a.mb,
       encode(sha256(convert_to(r.numero_radicado || a.nombre, 'UTF8')), 'hex')
  FROM (VALUES
   ('2027-0001','Carta o formulario de solicitud firmado','carta_solicitud.pdf','pdf',1.2),
   ('2027-0001','Plano de localización de la intervención','plano_localizacion.pdf','pdf',8.4),
   ('2027-0001','Archivo geográfico de localización','trazado.kmz','kmz',0.3),
   ('2027-0001','Cronograma de ejecución','cronograma.xlsx','xlsx',0.2),
   ('2027-0001','Póliza o garantía de la obra','poliza.pdf','pdf',2.1),
   ('2027-0002','Carta o formulario de solicitud firmado','carta_solicitud.pdf','pdf',0.9),
   ('2027-0002','Plan de manejo de tránsito','pmt.pdf','pdf',6.5),
   ('2027-0002','Cronograma de ejecución','cronograma.pdf','pdf',0.4)
  ) AS a(radicado, tipo_doc, nombre, formato, mb)
  JOIN nucleo.radicacion r ON r.numero_radicado = a.radicado
  JOIN catalogo.tipo_documento td ON td.nombre = a.tipo_doc;

-- Validaciones espaciales simuladas de S1 (cinco reglas, HU-07)
INSERT INTO nucleo.validacion_espacial (id_solicitud, regla, resultado, detalle)
SELECT r.id_solicitud, v.regla, v.resultado, v.detalle
  FROM nucleo.radicacion r,
       (VALUES ('Geometría válida y sin autointersecciones','Cumple',NULL),
               ('Dentro del perímetro de Cali','Cumple',NULL),
               ('Tipo de geometría permitido','Cumple',NULL),
               ('Longitud o área dentro de umbrales','Cumple','Longitud ≈ 777 m (simulado)'),
               ('Relación con zonas de restricción y corredores viales','Advertencia','Intersecta el corredor SIM-V1')
       ) AS v(regla, resultado, detalle)
 WHERE r.numero_radicado = '2027-0001';

-- Alertas: se calculan con la función de detección y se guardan
INSERT INTO nucleo.alerta_conflicto (id_solicitud_origen, id_solicitud_relacionada, tipo, nivel, distancia_m)
SELECT r.id_solicitud, c.id_solicitud_relacionada, c.tipo, c.nivel, c.distancia_m
  FROM nucleo.radicacion r, LATERAL nucleo.fn_detectar_conflictos(r.id_solicitud) c
 WHERE r.numero_radicado = '2027-0002';

-- ---------------------------------------------------------------------
-- 4. Flujo simulado sobre S1: asignación, visita y aprobación
-- ---------------------------------------------------------------------
SELECT set_config('app.id_usuario', (SELECT id_usuario FROM nucleo.usuario WHERE id_externo_idp='sim-idp-0301')::text, true);
UPDATE nucleo.solicitud s
   SET id_revisor = (SELECT id_usuario FROM nucleo.usuario WHERE id_externo_idp='sim-idp-0101'),
       id_estado  = (SELECT id_estado FROM catalogo.estado_tramite WHERE nombre='En revisión')
 WHERE s.id_solicitud IN (SELECT id_solicitud FROM nucleo.radicacion WHERE numero_radicado IN ('2027-0001','2027-0002'));

UPDATE nucleo.solicitud SET id_estado = (SELECT id_estado FROM catalogo.estado_tramite WHERE nombre='Visita programada')
 WHERE id_solicitud = (SELECT id_solicitud FROM nucleo.radicacion WHERE numero_radicado='2027-0001');
INSERT INTO nucleo.visita_tecnica (id_solicitud, id_inspector, fecha_programada, motivo)
SELECT r.id_solicitud, u.id_usuario, DATE '2027-07-06', 'Verificar trazado y conflicto con el cierre 2027-0002 (simulado)'
  FROM nucleo.radicacion r, nucleo.usuario u WHERE r.numero_radicado='2027-0001' AND u.id_externo_idp='sim-idp-0201';

-- Registro de la visita desde el móvil
SELECT set_config('app.id_usuario', (SELECT id_usuario FROM nucleo.usuario WHERE id_externo_idp='sim-idp-0201')::text, true);
SELECT set_config('app.origen', 'Módulo móvil', true);
UPDATE nucleo.visita_tecnica
   SET estado_implementacion='No iniciada', observaciones='Trazado coincide con lo radicado (simulado).',
       ubicacion_gps = ST_Transform(ST_SetSRID(ST_MakePoint(-76.5312, 3.4476),4326),9377),
       precision_gps_m = 4.5, sincronizada = true, fecha_registro = TIMESTAMPTZ '2027-07-06 09:40-05'
 WHERE id_solicitud = (SELECT id_solicitud FROM nucleo.radicacion WHERE numero_radicado='2027-0001');
INSERT INTO nucleo.evidencia (id_visita, tipo, ruta_objeto, geom, tamano_mb, fecha_captura)
SELECT v.id_visita, 'Fotografía', 'sim/evidencias/2027-0001/foto_0' || n || '.jpg',
       v.ubicacion_gps, 2.1, TIMESTAMPTZ '2027-07-06 09:35-05'
  FROM nucleo.visita_tecnica v, generate_series(1,6) n
 WHERE v.id_solicitud = (SELECT id_solicitud FROM nucleo.radicacion WHERE numero_radicado='2027-0001');

-- Decisión del revisor
SELECT set_config('app.id_usuario', (SELECT id_usuario FROM nucleo.usuario WHERE id_externo_idp='sim-idp-0101')::text, true);
SELECT set_config('app.origen', 'Portal web', true);
SELECT set_config('app.observacion', 'Aprobada condicionada a coordinar fechas con el cierre 2027-0002 (simulado).', true);
INSERT INTO nucleo.revision_tecnica (id_solicitud, id_revisor, decision, observacion, requiere_visita, fecha_hora)
SELECT r.id_solicitud, u.id_usuario, 'Aprobada', current_setting('app.observacion'), true, TIMESTAMPTZ '2027-07-07 15:10-05'
  FROM nucleo.radicacion r, nucleo.usuario u WHERE r.numero_radicado='2027-0001' AND u.id_externo_idp='sim-idp-0101';
UPDATE nucleo.solicitud SET id_estado = (SELECT id_estado FROM catalogo.estado_tramite WHERE nombre='Aprobada')
 WHERE id_solicitud = (SELECT id_solicitud FROM nucleo.radicacion WHERE numero_radicado='2027-0001');

-- Archivado simulado en gestión documental y registro de la integración
INSERT INTO nucleo.expediente_documental (id_solicitud, id_documento_gd)
SELECT id_solicitud, 'SIM-GD-2027-000123' FROM nucleo.radicacion WHERE numero_radicado='2027-0001';
INSERT INTO auditoria.log_integracion (id_solicitud, interfaz, resultado, reintentos, id_correlacion)
SELECT id_solicitud, 'Gestión documental', 'Exitoso', 1, 'a1b2c3d4-0000-4000-8000-000000000001'
  FROM nucleo.radicacion WHERE numero_radicado='2027-0001';
INSERT INTO nucleo.notificacion (id_solicitud, id_usuario, asunto, estado_envio, fecha_envio)
SELECT s.id_solicitud, s.id_solicitante, 'Su solicitud 2027-0001 fue aprobada (simulado)', 'Enviada', now()
  FROM nucleo.solicitud s JOIN nucleo.radicacion r USING (id_solicitud) WHERE r.numero_radicado='2027-0001';

COMMIT;
\o

REFRESH MATERIALIZED VIEW indicadores.mv_solicitudes_por_estado;
REFRESH MATERIALIZED VIEW indicadores.mv_intervenciones_por_comuna;
REFRESH MATERIALIZED VIEW indicadores.mv_tiempo_revision;
