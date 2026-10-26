-- =====================================================================
-- Sistema SIG para la Gestión de Intervenciones en el Espacio Público de Cali
-- Script 02 · Carga inicial de catálogos
-- ---------------------------------------------------------------------
-- Estado : PROPUESTA ACADÉMICA PRELIMINAR
-- Fuente : Anexo R, hoja «Dominios»; Taller 2 §4.1 (estados), Tabla 64.
--          Los valores marcados [PROPUESTO] no salen literalmente del
--          Taller 2 y deben validarse con la coordinación funcional (D-06).
-- Requisito: haber ejecutado 01_creacion_esquema.sql
-- =====================================================================

\set ON_ERROR_STOP on
BEGIN;
SET LOCAL app.origen = 'Servicio de integración';

-- Roles (Tabla 55). «Auditoría / control interno» queda inactivo hasta
-- que la entidad defina su acceso (Tabla 62) — decisión DE-08.
INSERT INTO catalogo.rol (nombre, activo) VALUES
 ('Solicitante externo', true), ('Revisor técnico', true), ('Inspector de campo', true),
 ('Coordinador funcional', true), ('Administrador tecnológico', true),
 ('Auditoría / control interno', false);

-- Tipos de intervención (enunciado). requiere_visita = [PROPUESTO]
INSERT INTO catalogo.tipo_intervencion (nombre, requiere_visita) VALUES
 ('Obra de red de servicios públicos', true), ('Reparación', false), ('Cierre', true),
 ('Ocupación de andén', true), ('Excavación', true), ('Mantenimiento', false),
 ('Emergencia', true);

-- Estados del trámite (§4.1: nueve estados)
INSERT INTO catalogo.estado_tramite (nombre, orden) VALUES
 ('Radicada', 1), ('En revisión', 2), ('Subsanación requerida', 3), ('Visita programada', 4),
 ('Aprobada', 5), ('Rechazada', 6), ('En ejecución', 7), ('Finalizada', 8), ('Cerrada', 9);

-- Transiciones válidas (derivadas de la Tabla 26 y de HU-06, HU-11, HU-13, HU-14)
INSERT INTO catalogo.transicion_estado (id_estado_origen, id_estado_destino)
SELECT o.id_estado, d.id_estado
  FROM (VALUES
        ('Radicada','En revisión'),
        ('En revisión','Subsanación requerida'), ('En revisión','Visita programada'),
        ('En revisión','Aprobada'), ('En revisión','Rechazada'),
        ('Subsanación requerida','En revisión'),   -- el solicitante responde (HU-06)
        ('Subsanación requerida','Cerrada'),       -- plazo vencido, decide el coordinador (HU-06)
        ('Visita programada','En revisión'),       -- vuelve a decisión tras la visita (P10 → P11)
        ('Visita programada','Aprobada'), ('Visita programada','Rechazada'),
        ('Visita programada','Subsanación requerida'),
        ('Aprobada','En ejecución'),               -- verificación en campo (P14)
        ('En ejecución','Finalizada'),
        ('Finalizada','Cerrada')                   -- cierre por el revisor (P15)
       ) AS t(origen, destino)
  JOIN catalogo.estado_tramite o ON o.nombre = t.origen
  JOIN catalogo.estado_tramite d ON d.nombre = t.destino;

-- Tipos de documento [PROPUESTO]: el Taller 2 fija los formatos (HU-03),
-- no la lista de documentos; la define la coordinación funcional (D-06).
INSERT INTO catalogo.tipo_documento (nombre, formato_permitido) VALUES
 ('Carta o formulario de solicitud firmado', 'PDF'),
 ('Plano de localización de la intervención', 'PDF, DWG, DXF'),
 ('Archivo geográfico de localización', 'KML, KMZ, GeoJSON'),
 ('Cronograma de ejecución', 'PDF, hoja de cálculo'),
 ('Plan de manejo de tránsito', 'PDF'),
 ('Registro fotográfico previo', 'Imagen JPEG o PNG'),
 ('Autorización de la empresa operadora de la red', 'PDF'),
 ('Póliza o garantía de la obra', 'PDF');

-- Documentos requeridos por tipo [PROPUESTO]
INSERT INTO catalogo.documento_requerido (id_tipo, id_tipo_doc, obligatorio)
SELECT ti.id_tipo, td.id_tipo_doc, x.obligatorio
  FROM (VALUES
   ('Obra de red de servicios públicos','Carta o formulario de solicitud firmado',true),
   ('Obra de red de servicios públicos','Plano de localización de la intervención',true),
   ('Obra de red de servicios públicos','Cronograma de ejecución',true),
   ('Obra de red de servicios públicos','Autorización de la empresa operadora de la red',true),
   ('Obra de red de servicios públicos','Plan de manejo de tránsito',false),
   ('Excavación','Carta o formulario de solicitud firmado',true),
   ('Excavación','Plano de localización de la intervención',true),
   ('Excavación','Cronograma de ejecución',true),
   ('Excavación','Póliza o garantía de la obra',true),
   ('Cierre','Carta o formulario de solicitud firmado',true),
   ('Cierre','Plan de manejo de tránsito',true),
   ('Cierre','Cronograma de ejecución',true),
   ('Ocupación de andén','Carta o formulario de solicitud firmado',true),
   ('Ocupación de andén','Plano de localización de la intervención',true),
   ('Reparación','Carta o formulario de solicitud firmado',true),
   ('Reparación','Registro fotográfico previo',true),
   ('Mantenimiento','Carta o formulario de solicitud firmado',true),
   ('Mantenimiento','Cronograma de ejecución',false),
   ('Emergencia','Carta o formulario de solicitud firmado',false),
   ('Emergencia','Registro fotográfico previo',false)
  ) AS x(tipo, documento, obligatorio)
  JOIN catalogo.tipo_intervencion ti ON ti.nombre = x.tipo
  JOIN catalogo.tipo_documento   td ON td.nombre = x.documento;

COMMIT;
