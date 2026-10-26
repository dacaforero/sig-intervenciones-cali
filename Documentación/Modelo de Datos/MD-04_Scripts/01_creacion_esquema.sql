-- =====================================================================
-- Sistema SIG para la Gestión de Intervenciones en el Espacio Público
-- de Santiago de Cali
-- Script 01 · Creación del esquema de base de datos
-- ---------------------------------------------------------------------
-- Estado      : PROPUESTA ACADÉMICA PRELIMINAR (Taller 3, despliegue)
-- Fuente      : Taller 2 §4.4 y §9, Anexo E (MER), Anexo F (clases),
--               Anexo R (diccionario de datos)
-- Motor       : PostgreSQL 16 + PostGIS 3.4 (versiones de referencia,
--               por validar con el administrador institucional)
-- SRID        : EPSG:9377 (MAGNA-SIRGAS 2018 / Origen-Nacional)
--               Decisión de equipo DE-01 (ver registro de decisiones)
-- Codificación: UTF-8
-- Ejecución   : psql -v ON_ERROR_STOP=1 -d <base> -f 01_creacion_esquema.sql
--               Requiere un rol con privilegio para crear extensiones.
-- Nota        : No contiene credenciales. Los roles de base de datos
--               se crean sin LOGIN; las cuentas de conexión las crea el
--               administrador con secretos del gestor de secretos.
-- =====================================================================

\set ON_ERROR_STOP on
SET client_min_messages = warning;

BEGIN;

-- ---------------------------------------------------------------------
-- 0. Extensiones y sistemas de referencia
-- ---------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS postgis;

-- Algunas versiones de PostGIS no traen EPSG:9377 ni EPSG:6249 en
-- spatial_ref_sys. Se registran solo si faltan (definición tomada de
-- la base de datos de PROJ 9.4, comando projinfo).
INSERT INTO spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext)
SELECT 9377, 'EPSG', 9377,
 '+proj=tmerc +lat_0=4 +lon_0=-73 +k=0.9992 +x_0=5000000 +y_0=2000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs',
 'PROJCS["MAGNA-SIRGAS 2018 / Origen-Nacional",GEOGCS["MAGNA-SIRGAS 2018",DATUM["Marco_Geocentrico_Nacional_de_Referencia_2018",SPHEROID["GRS 1980",6378137,298.257222101,AUTHORITY["EPSG","7019"]],AUTHORITY["EPSG","1329"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","20046"]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",4],PARAMETER["central_meridian",-73],PARAMETER["scale_factor",0.9992],PARAMETER["false_easting",5000000],PARAMETER["false_northing",2000000],UNIT["metre",1,AUTHORITY["EPSG","9001"]],AUTHORITY["EPSG","9377"]]'
WHERE NOT EXISTS (SELECT 1 FROM spatial_ref_sys WHERE srid = 9377);

INSERT INTO spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext)
SELECT 6249, 'EPSG', 6249,
 '+proj=col_urban +lat_0=3.44188333333333 +lon_0=-76.5205625 +x_0=1061900.18 +y_0=872364.63 +h_0=1000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs',
 'PROJCS["MAGNA-SIRGAS / Cali urban grid",AUTHORITY["EPSG","6249"]]'
WHERE NOT EXISTS (SELECT 1 FROM spatial_ref_sys WHERE srid = 6249);

-- ---------------------------------------------------------------------
-- 1. Esquemas
-- ---------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS catalogo;     -- catálogos administrables (HU-19)
CREATE SCHEMA IF NOT EXISTS nucleo;       -- trámite, campo y documentos
CREATE SCHEMA IF NOT EXISTS referencia;   -- copia de solo lectura de IDESC (DE-02)
CREATE SCHEMA IF NOT EXISTS auditoria;    -- bitácora y registro de integraciones
CREATE SCHEMA IF NOT EXISTS publicacion;  -- vistas sin datos personales para GeoServer (SP-01)
CREATE SCHEMA IF NOT EXISTS indicadores;  -- vistas materializadas del panel (HU-18)

COMMENT ON SCHEMA referencia IS 'Copia de solo lectura de capas de IDESC. IDESC es la fuente autoritativa; aquí no se editan ni se republican como propias (DE-02).';

-- ---------------------------------------------------------------------
-- 2. Catálogos
-- ---------------------------------------------------------------------
CREATE TABLE catalogo.rol (
    id_rol      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      varchar(50)  NOT NULL UNIQUE
                CHECK (nombre IN ('Solicitante externo','Revisor técnico','Inspector de campo',
                                  'Coordinador funcional','Administrador tecnológico',
                                  'Auditoría / control interno')),
    activo      boolean      NOT NULL DEFAULT true
);
COMMENT ON TABLE catalogo.rol IS 'OBJ-01. Roles funcionales (Tabla 55 del Taller 2).';

CREATE TABLE catalogo.tipo_intervencion (
    id_tipo         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          varchar(80) NOT NULL UNIQUE,
    requiere_visita boolean     NOT NULL DEFAULT false,
    activo          boolean     NOT NULL DEFAULT true
);
COMMENT ON TABLE catalogo.tipo_intervencion IS 'OBJ-09. Tipos de intervención; cada uno tiene una tabla de detalle.';

CREATE TABLE catalogo.estado_tramite (
    id_estado   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      varchar(40) NOT NULL UNIQUE,
    orden       smallint    NOT NULL,
    activo      boolean     NOT NULL DEFAULT true
);
COMMENT ON TABLE catalogo.estado_tramite IS 'OBJ-10. Los 9 estados de la sección 4.1 del Taller 2.';

-- Extensión justificada (Tabla 64: «los 9 estados y sus transiciones válidas»;
-- §9.2: «solo se aceptan las transiciones del proceso»).
CREATE TABLE catalogo.transicion_estado (
    id_estado_origen  integer NOT NULL REFERENCES catalogo.estado_tramite(id_estado),
    id_estado_destino integer NOT NULL REFERENCES catalogo.estado_tramite(id_estado),
    activo            boolean NOT NULL DEFAULT true,
    PRIMARY KEY (id_estado_origen, id_estado_destino),
    CHECK (id_estado_origen <> id_estado_destino)
);
COMMENT ON TABLE catalogo.transicion_estado IS 'Complementaria (despliegue). Transiciones válidas entre estados; administrable por el coordinador con aprobación del Product Owner.';

CREATE TABLE catalogo.tipo_documento (
    id_tipo_doc       integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre            varchar(100) NOT NULL,
    formato_permitido varchar(100) NOT NULL,
    activo            boolean      NOT NULL DEFAULT true
);
COMMENT ON TABLE catalogo.tipo_documento IS 'OBJ-11. Tipos de documento adjuntable.';

CREATE TABLE catalogo.documento_requerido (
    id_tipo     integer NOT NULL REFERENCES catalogo.tipo_intervencion(id_tipo),
    id_tipo_doc integer NOT NULL REFERENCES catalogo.tipo_documento(id_tipo_doc),
    obligatorio boolean NOT NULL DEFAULT true,
    PRIMARY KEY (id_tipo, id_tipo_doc)
);
COMMENT ON TABLE catalogo.documento_requerido IS 'OBJ-12. Documentos exigidos por tipo de intervención (HU-03).';

-- ---------------------------------------------------------------------
-- 3. Usuarios
-- ---------------------------------------------------------------------
CREATE TABLE nucleo.usuario (
    id_usuario            integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_rol                integer      NOT NULL REFERENCES catalogo.rol(id_rol),
    id_externo_idp        varchar(64)  UNIQUE,  -- complementario: «sub» del proveedor de identidad (§9.1)
    tipo_identificacion   varchar(10)  NOT NULL CHECK (tipo_identificacion IN ('CC','CE','NIT','Otro')),
    identificacion        varchar(30)  NOT NULL UNIQUE,
    nombre_razon_social   varchar(200) NOT NULL,
    correo                varchar(150) NOT NULL UNIQUE,
    correo_verificado     boolean      NOT NULL DEFAULT false,
    acepta_politica_datos boolean      NOT NULL CHECK (acepta_politica_datos),
    activo                boolean      NOT NULL DEFAULT true,
    fecha_registro        timestamptz  NOT NULL DEFAULT now()
);
COMMENT ON TABLE  nucleo.usuario IS 'OBJ-02. No almacena contraseñas: la autenticación la gestiona el proveedor de identidad (AD-07, §7.2).';
COMMENT ON COLUMN nucleo.usuario.identificacion IS 'Dato personal (Ley 1581 de 2012): visible solo para roles autorizados.';
COMMENT ON COLUMN nucleo.usuario.id_externo_idp IS 'Complementario: identificador del usuario en el proveedor de identidad.';

-- ---------------------------------------------------------------------
-- 4. Capas de referencia (copia de solo lectura de IDESC) — DE-02
-- ---------------------------------------------------------------------
CREATE TABLE referencia.comuna (
    id_comuna            integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo               varchar(10)  NOT NULL UNIQUE,
    nombre               varchar(100) NOT NULL,
    geom                 geometry(MultiPolygon, 9377) NOT NULL CHECK (ST_IsValid(geom)),
    id_origen_idesc      varchar(50),   -- complementario: identificador en la capa de IDESC
    fecha_sincronizacion timestamptz NOT NULL DEFAULT now()  -- complementario (IF-05, calidad del dato)
);

CREATE TABLE referencia.espacio_publico (
    id_espacio           integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo                 varchar(40)  NOT NULL,
    nombre               varchar(150),
    geom                 geometry(MultiPolygon, 9377) NOT NULL CHECK (ST_IsValid(geom)),
    id_origen_idesc      varchar(50),
    fecha_sincronizacion timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE referencia.infraestructura_vial (
    id_infraestructura   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo_elemento        varchar(40)  NOT NULL,
    nombre               varchar(150),
    jerarquia            varchar(30),
    geom                 geometry(MultiLineString, 9377) NOT NULL CHECK (ST_IsValid(geom)),
    id_origen_idesc      varchar(50),
    fecha_sincronizacion timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE referencia.zona_restriccion (
    id_zona              integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo                 varchar(60)  NOT NULL,
    nombre               varchar(150),
    geom                 geometry(MultiPolygon, 9377) NOT NULL CHECK (ST_IsValid(geom)),
    id_origen_idesc      varchar(50),
    fecha_sincronizacion timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE referencia.comuna               IS 'OBJ-24. Copia de solo lectura de IDESC.';
COMMENT ON TABLE referencia.espacio_publico      IS 'OBJ-22. Copia de solo lectura de IDESC.';
COMMENT ON TABLE referencia.infraestructura_vial IS 'OBJ-23. Copia de solo lectura de IDESC.';
COMMENT ON TABLE referencia.zona_restriccion     IS 'OBJ-25. Copia de solo lectura de IDESC.';

-- ---------------------------------------------------------------------
-- 5. Núcleo del trámite
-- ---------------------------------------------------------------------
CREATE TABLE nucleo.solicitud (
    id_solicitud        integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitante      integer      NOT NULL REFERENCES nucleo.usuario(id_usuario),
    id_revisor          integer      REFERENCES nucleo.usuario(id_usuario),
    id_tipo             integer      NOT NULL REFERENCES catalogo.tipo_intervencion(id_tipo),
    id_estado           integer      NOT NULL REFERENCES catalogo.estado_tramite(id_estado),
    descripcion         text         NOT NULL,
    entidad_responsable varchar(200) NOT NULL,
    contacto            varchar(200) NOT NULL,
    fecha_inicio        date         NOT NULL,
    fecha_fin           date         NOT NULL,
    CONSTRAINT ck_solicitud_fechas CHECK (fecha_fin >= fecha_inicio)
);
COMMENT ON TABLE  nucleo.solicitud IS 'OBJ-04. Agregado raíz. Se crea al radicar; los borradores viven en el dispositivo (DE-07).';
COMMENT ON COLUMN nucleo.solicitud.contacto IS 'Dato personal (Ley 1581 de 2012).';

CREATE TABLE nucleo.radicacion (
    id_radicacion   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud    integer     NOT NULL UNIQUE REFERENCES nucleo.solicitud(id_solicitud),
    numero_radicado varchar(9)  NOT NULL UNIQUE CHECK (numero_radicado ~ '^[0-9]{4}-[0-9]{4}$'),
    canal           varchar(30) NOT NULL CHECK (canal IN ('Portal web','Módulo móvil','Correo electrónico','Otro')),
    fecha_hora      timestamptz NOT NULL DEFAULT now(),
    comprobante     varchar(500) NOT NULL
);
COMMENT ON TABLE nucleo.radicacion IS 'OBJ-05. Número AAAA-NNNN, consecutivo por año e inmodificable (§9.1).';

CREATE TABLE nucleo.reporte (
    id_reporte     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_reportante  integer     NOT NULL REFERENCES nucleo.usuario(id_usuario),
    id_solicitud   integer     UNIQUE REFERENCES nucleo.solicitud(id_solicitud),
    canal_origen   varchar(30) NOT NULL CHECK (canal_origen IN ('Portal web','Módulo móvil','Correo electrónico','Otro')),
    descripcion    text        NOT NULL,
    geom           geometry(Geometry, 9377) NOT NULL CHECK (ST_IsValid(geom)),
    fecha_hora     timestamptz NOT NULL DEFAULT now(),
    estado_reporte varchar(30) NOT NULL DEFAULT 'Recibido'
                   CHECK (estado_reporte IN ('Recibido','En evaluación','Convertido en solicitud','Descartado'))
);
COMMENT ON TABLE nucleo.reporte IS 'OBJ-03. Aviso previo que puede formalizarse como solicitud. Pendiente: historia de usuario asociada en el Taller 2.';

-- Detalles por tipo (especialización de DetalleIntervencion, OBJ-14 a OBJ-20)
CREATE TABLE nucleo.obra_red_servicio (
    id_obra           integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud      integer NOT NULL UNIQUE REFERENCES nucleo.solicitud(id_solicitud),
    tipo_red          varchar(40)  NOT NULL,
    empresa_operadora varchar(150) NOT NULL,
    longitud_m        numeric(10,2) CHECK (longitud_m >= 0)
);
CREATE TABLE nucleo.reparacion (
    id_reparacion integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud  integer NOT NULL UNIQUE REFERENCES nucleo.solicitud(id_solicitud),
    tipo_dano     varchar(60) NOT NULL,
    material      varchar(60),
    area_m2       numeric(10,2) CHECK (area_m2 >= 0)
);
CREATE TABLE nucleo.cierre (
    id_cierre          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud       integer NOT NULL UNIQUE REFERENCES nucleo.solicitud(id_solicitud),
    modalidad          varchar(20) NOT NULL CHECK (modalidad IN ('Parcial','Total')),
    carriles_afectados smallint CHECK (carriles_afectados >= 0),
    horario            varchar(100)
);
CREATE TABLE nucleo.ocupacion_anden (
    id_ocupacion  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud  integer NOT NULL UNIQUE REFERENCES nucleo.solicitud(id_solicitud),
    motivo        varchar(150) NOT NULL,
    area_m2       numeric(10,2) NOT NULL CHECK (area_m2 > 0),
    ancho_libre_m numeric(5,2)  CHECK (ancho_libre_m >= 0)
);
CREATE TABLE nucleo.excavacion (
    id_excavacion integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud  integer NOT NULL UNIQUE REFERENCES nucleo.solicitud(id_solicitud),
    profundidad_m numeric(6,2)  NOT NULL CHECK (profundidad_m > 0),
    longitud_m    numeric(10,2) CHECK (longitud_m >= 0),
    tipo_relleno  varchar(60)
);
CREATE TABLE nucleo.mantenimiento (
    id_mantenimiento integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud     integer NOT NULL UNIQUE REFERENCES nucleo.solicitud(id_solicitud),
    tipo             varchar(40) NOT NULL CHECK (tipo IN ('Preventivo','Correctivo')),
    periodicidad     varchar(40)
);
CREATE TABLE nucleo.emergencia (
    id_emergencia      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud       integer NOT NULL UNIQUE REFERENCES nucleo.solicitud(id_solicitud),
    tipo_evento        varchar(60) NOT NULL,
    nivel_prioridad    varchar(20) NOT NULL CHECK (nivel_prioridad IN ('Alta','Media','Baja')),
    atencion_inmediata boolean     NOT NULL DEFAULT false
);

CREATE TABLE nucleo.geometria_intervencion (
    id_geometria       integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud       integer     NOT NULL REFERENCES nucleo.solicitud(id_solicitud),
    id_espacio         integer     REFERENCES referencia.espacio_publico(id_espacio),
    id_infraestructura integer     REFERENCES referencia.infraestructura_vial(id_infraestructura),
    id_comuna          integer     NOT NULL REFERENCES referencia.comuna(id_comuna),
    tipo_geometria     varchar(20) NOT NULL CHECK (tipo_geometria IN ('Punto','Línea','Polígono')),
    geom               geometry(Geometry, 9377) NOT NULL,
    fuente_origen      varchar(30) NOT NULL
                       CHECK (fuente_origen IN ('Dibujo en mapa','KML/KMZ','GeoJSON','Coordenadas','Dirección','Plano')),
    CONSTRAINT ck_geom_valida CHECK (ST_IsValid(geom)),
    CONSTRAINT ck_geom_tipo CHECK (          -- 0 = punto, 1 = línea, 2 = polígono
        (tipo_geometria = 'Punto'    AND ST_Dimension(geom) = 0) OR
        (tipo_geometria = 'Línea'    AND ST_Dimension(geom) = 1) OR
        (tipo_geometria = 'Polígono' AND ST_Dimension(geom) = 2))
);
COMMENT ON TABLE nucleo.geometria_intervencion IS 'OBJ-21. id_comuna, id_espacio e id_infraestructura se calculan por intersección al insertar (trigger).';

CREATE TABLE nucleo.validacion_espacial (
    id_validacion integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud  integer     NOT NULL REFERENCES nucleo.solicitud(id_solicitud),
    id_zona       integer     REFERENCES referencia.zona_restriccion(id_zona),
    regla         varchar(80) NOT NULL CHECK (regla IN (
                    'Geometría válida y sin autointersecciones','Dentro del perímetro de Cali',
                    'Tipo de geometría permitido','Longitud o área dentro de umbrales',
                    'Relación con zonas de restricción y corredores viales')),
    resultado     varchar(20) NOT NULL CHECK (resultado IN ('Cumple','Advertencia','Error')),
    detalle       text,
    fecha         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE nucleo.alerta_conflicto (
    id_alerta                integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud_origen      integer       NOT NULL REFERENCES nucleo.solicitud(id_solicitud),
    id_solicitud_relacionada integer       NOT NULL REFERENCES nucleo.solicitud(id_solicitud),
    tipo                     varchar(20)   NOT NULL CHECK (tipo IN ('Duplicidad','Conflicto')),
    nivel                    varchar(20)   NOT NULL CHECK (nivel IN ('Crítico','Alto','Medio','Bajo')),
    distancia_m              numeric(10,2) NOT NULL CHECK (distancia_m >= 0),
    fecha_deteccion          timestamptz   NOT NULL DEFAULT now(),
    CONSTRAINT ck_alerta_distintas CHECK (id_solicitud_origen <> id_solicitud_relacionada)
);

CREATE TABLE nucleo.revision_tecnica (
    id_revision     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud    integer     NOT NULL REFERENCES nucleo.solicitud(id_solicitud),
    id_revisor      integer     NOT NULL REFERENCES nucleo.usuario(id_usuario),
    decision        varchar(30) NOT NULL CHECK (decision IN ('Aprobada','Rechazada','Subsanación requerida')),
    observacion     text,
    requiere_visita boolean     NOT NULL DEFAULT false,
    fecha_hora      timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_revision_observacion CHECK (
        decision = 'Aprobada' OR (observacion IS NOT NULL AND length(trim(observacion)) > 0))
);

CREATE TABLE nucleo.historial_estado (
    id_historial    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud    integer     NOT NULL REFERENCES nucleo.solicitud(id_solicitud),
    id_estado_nuevo integer     NOT NULL REFERENCES catalogo.estado_tramite(id_estado),
    id_usuario      integer     NOT NULL REFERENCES nucleo.usuario(id_usuario),
    fecha_hora      timestamptz NOT NULL DEFAULT now(),
    observacion     text
);
COMMENT ON TABLE nucleo.historial_estado IS 'OBJ-07. Solo inserción; se alimenta por trigger desde nucleo.solicitud (RNF-11).';

CREATE TABLE nucleo.visita_tecnica (
    id_visita             integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud          integer      NOT NULL REFERENCES nucleo.solicitud(id_solicitud),
    id_inspector          integer      NOT NULL REFERENCES nucleo.usuario(id_usuario),
    fecha_programada      date         NOT NULL,
    motivo                varchar(200) NOT NULL,
    estado_implementacion varchar(30)  CHECK (estado_implementacion IN ('No iniciada','En ejecución','Finalizada','No conforme')),
    observaciones         text,
    ubicacion_gps         geometry(Point, 9377) CHECK (ubicacion_gps IS NULL OR ST_IsValid(ubicacion_gps)),
    precision_gps_m       numeric(6,2) CHECK (precision_gps_m >= 0),
    sincronizada          boolean      NOT NULL DEFAULT false,
    fecha_registro        timestamptz
);
COMMENT ON COLUMN nucleo.visita_tecnica.precision_gps_m IS 'La aplicación advierte si supera 10 m (RNF-18).';

CREATE TABLE nucleo.seguimiento (
    id_seguimiento   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud     integer      NOT NULL REFERENCES nucleo.solicitud(id_solicitud),
    id_usuario       integer      NOT NULL REFERENCES nucleo.usuario(id_usuario),
    id_visita        integer      REFERENCES nucleo.visita_tecnica(id_visita),
    estado_ejecucion varchar(30)  NOT NULL CHECK (estado_ejecucion IN ('No iniciada','En ejecución','Finalizada','No conforme')),
    avance_pct       numeric(5,2) NOT NULL CHECK (avance_pct BETWEEN 0 AND 100),
    observacion      text,
    fecha_hora       timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE nucleo.archivo (
    id_archivo      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud    integer      NOT NULL REFERENCES nucleo.solicitud(id_solicitud),
    id_tipo_doc     integer      NOT NULL REFERENCES catalogo.tipo_documento(id_tipo_doc),
    nombre_original varchar(255) NOT NULL,
    formato         varchar(10)  NOT NULL CHECK (lower(formato) IN ('pdf','xlsx','xls','csv','ods','jpg','jpeg','png','kml','kmz','geojson','dwg','dxf')),
    ruta_objeto     varchar(500) NOT NULL,
    tamano_mb       numeric(8,2) NOT NULL CHECK (tamano_mb > 0 AND tamano_mb <= 50),
    checksum        char(64)     NOT NULL CHECK (checksum ~ '^[0-9a-f]{64}$'),
    version         integer      NOT NULL DEFAULT 1 CHECK (version >= 1),
    fecha_carga     timestamptz  NOT NULL DEFAULT now()
);
COMMENT ON COLUMN nucleo.archivo.formato IS 'Lista de extensiones propuesta a partir de HU-03 («PDF, hoja de cálculo, imagen, KML/KMZ, GeoJSON o plano»); por validar.';

CREATE TABLE nucleo.evidencia (
    id_evidencia   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_visita      integer      REFERENCES nucleo.visita_tecnica(id_visita),
    id_reporte     integer      REFERENCES nucleo.reporte(id_reporte),
    id_seguimiento integer      REFERENCES nucleo.seguimiento(id_seguimiento),
    tipo           varchar(30)  NOT NULL CHECK (tipo IN ('Fotografía','Geometría de campo')),
    ruta_objeto    varchar(500) NOT NULL,
    geom           geometry(Geometry, 9377) CHECK (geom IS NULL OR ST_IsValid(geom)),
    tamano_mb      numeric(6,2) NOT NULL CHECK (tamano_mb > 0),
    fecha_captura  timestamptz  NOT NULL,
    CONSTRAINT ck_evidencia_origen CHECK (num_nonnulls(id_visita, id_reporte, id_seguimiento) >= 1),
    CONSTRAINT ck_evidencia_foto   CHECK (tipo <> 'Fotografía' OR tamano_mb <= 2.5)
);

CREATE TABLE nucleo.expediente_documental (
    id_expediente   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud    integer      NOT NULL UNIQUE REFERENCES nucleo.solicitud(id_solicitud),
    id_documento_gd varchar(100) NOT NULL,
    fecha_archivo   timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE nucleo.notificacion (
    id_notificacion integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud    integer      NOT NULL REFERENCES nucleo.solicitud(id_solicitud),
    id_usuario      integer      NOT NULL REFERENCES nucleo.usuario(id_usuario),
    asunto          varchar(200) NOT NULL,
    estado_envio    varchar(20)  NOT NULL DEFAULT 'Pendiente' CHECK (estado_envio IN ('Pendiente','Enviada','Fallida')),
    fecha_envio     timestamptz
);

-- ---------------------------------------------------------------------
-- 6. Auditoría
-- ---------------------------------------------------------------------
CREATE TABLE auditoria.bitacora_auditoria (
    id_bitacora    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario     integer     REFERENCES nucleo.usuario(id_usuario),
    entidad        varchar(60) NOT NULL,
    id_registro    integer     NOT NULL,
    accion         varchar(20) NOT NULL CHECK (accion IN ('Crear','Modificar','Eliminar lógico','Consultar','Autenticar')),
    valor_anterior text,
    valor_nuevo    text,
    origen         varchar(30) NOT NULL CHECK (origen IN ('Portal web','Módulo móvil','Servicio de integración')),
    fecha_hora     timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE auditoria.bitacora_auditoria IS 'OBJ-33. Solo inserción; se conserva 5 años o más (RNF-11). id_bitacora como bigint por volumen esperado.';

CREATE TABLE auditoria.log_integracion (
    id_log         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_solicitud   integer     REFERENCES nucleo.solicitud(id_solicitud),
    interfaz       varchar(40) NOT NULL CHECK (interfaz IN ('Directorio de usuarios','Mensajería','Gestión documental',
                                                            'Almacenamiento de archivos','Servicios geográficos (IDESC)')),
    resultado      varchar(20) NOT NULL CHECK (resultado IN ('Exitoso','Reintentando','Error')),
    reintentos     smallint    NOT NULL DEFAULT 0 CHECK (reintentos BETWEEN 0 AND 3),
    id_correlacion varchar(36) NOT NULL,
    detalle_error  text,
    fecha_hora     timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE auditoria.log_integracion IS 'OBJ-34. Sin datos personales (§11.1).';

-- ---------------------------------------------------------------------
-- 7. Índices
-- ---------------------------------------------------------------------
-- Espaciales (RNF-03: detección en ≤ 5 s sobre 20.000 intervenciones)
CREATE INDEX ix_geom_intervencion_geom ON nucleo.geometria_intervencion USING gist (geom);
CREATE INDEX ix_reporte_geom           ON nucleo.reporte USING gist (geom);
CREATE INDEX ix_visita_gps             ON nucleo.visita_tecnica USING gist (ubicacion_gps);
CREATE INDEX ix_evidencia_geom         ON nucleo.evidencia USING gist (geom);
CREATE INDEX ix_comuna_geom            ON referencia.comuna USING gist (geom);
CREATE INDEX ix_espacio_geom           ON referencia.espacio_publico USING gist (geom);
CREATE INDEX ix_vial_geom              ON referencia.infraestructura_vial USING gist (geom);
CREATE INDEX ix_zona_geom              ON referencia.zona_restriccion USING gist (geom);
-- Temporal (superposición de fechas, HU-08)
CREATE INDEX ix_solicitud_rango ON nucleo.solicitud USING gist (daterange(fecha_inicio, fecha_fin, '[]'));
-- Claves foráneas y filtros frecuentes (HU-10, HU-16)
CREATE INDEX ix_solicitud_estado      ON nucleo.solicitud (id_estado);
CREATE INDEX ix_solicitud_revisor     ON nucleo.solicitud (id_revisor);
CREATE INDEX ix_solicitud_solicitante ON nucleo.solicitud (id_solicitante);
CREATE INDEX ix_solicitud_tipo        ON nucleo.solicitud (id_tipo);
CREATE INDEX ix_geom_solicitud        ON nucleo.geometria_intervencion (id_solicitud);
CREATE INDEX ix_geom_comuna           ON nucleo.geometria_intervencion (id_comuna);
CREATE INDEX ix_archivo_solicitud     ON nucleo.archivo (id_solicitud);
CREATE INDEX ix_historial_solicitud   ON nucleo.historial_estado (id_solicitud, fecha_hora);
CREATE INDEX ix_visita_solicitud      ON nucleo.visita_tecnica (id_solicitud);
CREATE INDEX ix_visita_inspector      ON nucleo.visita_tecnica (id_inspector, fecha_programada);
CREATE INDEX ix_alerta_origen         ON nucleo.alerta_conflicto (id_solicitud_origen);
CREATE INDEX ix_validacion_solicitud  ON nucleo.validacion_espacial (id_solicitud);
CREATE INDEX ix_notificacion_estado   ON nucleo.notificacion (estado_envio) WHERE estado_envio <> 'Enviada';
CREATE INDEX ix_bitacora_entidad      ON auditoria.bitacora_auditoria (entidad, id_registro);
CREATE INDEX ix_bitacora_fecha        ON auditoria.bitacora_auditoria (fecha_hora);
CREATE INDEX ix_log_correlacion       ON auditoria.log_integracion (id_correlacion);

-- ---------------------------------------------------------------------
-- 8. Reglas de negocio implementadas en la base de datos
--    (la API las valida primero; la base de datos es la última barrera)
-- ---------------------------------------------------------------------

-- 8.1 Contexto de sesión: la API fija el usuario y el origen en cada
--     transacción con SET LOCAL app.id_usuario / app.origen.
CREATE OR REPLACE FUNCTION auditoria.fn_usuario_sesion() RETURNS integer
LANGUAGE sql STABLE AS $$
    SELECT NULLIF(current_setting('app.id_usuario', true), '')::integer
$$;
CREATE OR REPLACE FUNCTION auditoria.fn_origen_sesion() RETURNS varchar
LANGUAGE sql STABLE AS $$
    SELECT COALESCE(NULLIF(current_setting('app.origen', true), ''), 'Servicio de integración')
$$;

-- 8.2 Tablas de solo inserción (historial, bitácora, registro de integraciones)
CREATE OR REPLACE FUNCTION auditoria.fn_solo_insercion() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'La tabla %.% es de solo inserción (RNF-11): % no permitido',
        TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP USING ERRCODE = 'insufficient_privilege';
END $$;

CREATE TRIGGER tg_historial_solo_insercion BEFORE UPDATE OR DELETE ON nucleo.historial_estado
    FOR EACH ROW EXECUTE FUNCTION auditoria.fn_solo_insercion();
CREATE TRIGGER tg_bitacora_solo_insercion BEFORE UPDATE OR DELETE ON auditoria.bitacora_auditoria
    FOR EACH ROW EXECUTE FUNCTION auditoria.fn_solo_insercion();
CREATE TRIGGER tg_log_solo_insercion BEFORE UPDATE OR DELETE ON auditoria.log_integracion
    FOR EACH ROW EXECUTE FUNCTION auditoria.fn_solo_insercion();
CREATE TRIGGER tg_historial_sin_truncate BEFORE TRUNCATE ON nucleo.historial_estado
    FOR EACH STATEMENT EXECUTE FUNCTION auditoria.fn_solo_insercion();
CREATE TRIGGER tg_bitacora_sin_truncate BEFORE TRUNCATE ON auditoria.bitacora_auditoria
    FOR EACH STATEMENT EXECUTE FUNCTION auditoria.fn_solo_insercion();

-- 8.3 Bitácora genérica (TG_ARGV[0] = nombre de la columna PK)
CREATE OR REPLACE FUNCTION auditoria.fn_bitacora() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    v_id integer;
    v_accion varchar(20);
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_id := (to_jsonb(NEW) ->> TG_ARGV[0])::integer; v_accion := 'Crear';
    ELSIF TG_OP = 'UPDATE' THEN
        v_id := (to_jsonb(NEW) ->> TG_ARGV[0])::integer;
        v_accion := CASE WHEN (to_jsonb(OLD)->>'activo')::boolean IS TRUE
                              AND (to_jsonb(NEW)->>'activo')::boolean IS FALSE
                         THEN 'Eliminar lógico' ELSE 'Modificar' END;
    ELSE
        v_id := (to_jsonb(OLD) ->> TG_ARGV[0])::integer; v_accion := 'Eliminar lógico';
    END IF;
    INSERT INTO auditoria.bitacora_auditoria
        (id_usuario, entidad, id_registro, accion, valor_anterior, valor_nuevo, origen)
    VALUES (auditoria.fn_usuario_sesion(), TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME, v_id, v_accion,
            CASE WHEN TG_OP <> 'INSERT' THEN (to_jsonb(OLD) - 'geom' - 'ubicacion_gps')::text END,
            CASE WHEN TG_OP <> 'DELETE' THEN (to_jsonb(NEW) - 'geom' - 'ubicacion_gps')::text END,
            auditoria.fn_origen_sesion());
    RETURN COALESCE(NEW, OLD);
END $$;
COMMENT ON FUNCTION auditoria.fn_bitacora() IS 'Las geometrías se excluyen del texto para no inflar la bitácora; su historial queda en la propia tabla (§9.3, evento «Geometría»).';

DO $$
DECLARE r record;
BEGIN
    FOR r IN SELECT * FROM (VALUES
        ('catalogo','rol','id_rol'), ('catalogo','tipo_intervencion','id_tipo'),
        ('catalogo','estado_tramite','id_estado'), ('catalogo','tipo_documento','id_tipo_doc'),
        ('nucleo','usuario','id_usuario'), ('nucleo','solicitud','id_solicitud'),
        ('nucleo','geometria_intervencion','id_geometria'), ('nucleo','archivo','id_archivo'),
        ('nucleo','revision_tecnica','id_revision'), ('nucleo','visita_tecnica','id_visita'),
        ('nucleo','seguimiento','id_seguimiento'), ('nucleo','evidencia','id_evidencia'),
        ('nucleo','reporte','id_reporte'), ('nucleo','expediente_documental','id_expediente')
    ) AS t(esquema, tabla, pk)
    LOOP
        EXECUTE format('CREATE TRIGGER tg_bitacora AFTER INSERT OR UPDATE OR DELETE ON %I.%I
                        FOR EACH ROW EXECUTE FUNCTION auditoria.fn_bitacora(%L)', r.esquema, r.tabla, r.pk);
    END LOOP;
END $$;

-- 8.4 Flujo de estados: estado inicial «Radicada», transiciones válidas
--     e historial automático (HU-11, HU-12, §9.2)
CREATE OR REPLACE FUNCTION nucleo.fn_flujo_estado() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    v_usuario integer := auditoria.fn_usuario_sesion();
BEGIN
    IF v_usuario IS NULL THEN
        RAISE EXCEPTION 'Falta el usuario de sesión (app.id_usuario) para registrar el historial';
    END IF;
    IF TG_OP = 'INSERT' THEN
        IF NEW.id_estado <> (SELECT id_estado FROM catalogo.estado_tramite WHERE nombre = 'Radicada') THEN
            RAISE EXCEPTION 'Una solicitud nueva debe iniciar en estado «Radicada»';
        END IF;
    ELSIF NEW.id_estado IS DISTINCT FROM OLD.id_estado THEN
        IF NOT EXISTS (SELECT 1 FROM catalogo.transicion_estado
                       WHERE id_estado_origen = OLD.id_estado AND id_estado_destino = NEW.id_estado AND activo) THEN
            RAISE EXCEPTION 'Transición de estado no válida: % → %',
                (SELECT nombre FROM catalogo.estado_tramite WHERE id_estado = OLD.id_estado),
                (SELECT nombre FROM catalogo.estado_tramite WHERE id_estado = NEW.id_estado);
        END IF;
    ELSE
        RETURN NEW;
    END IF;
    INSERT INTO nucleo.historial_estado (id_solicitud, id_estado_nuevo, id_usuario, observacion)
    VALUES (NEW.id_solicitud, NEW.id_estado, v_usuario, NULLIF(current_setting('app.observacion', true), ''));
    RETURN NEW;
END $$;

CREATE TRIGGER tg_solicitud_flujo AFTER INSERT OR UPDATE OF id_estado ON nucleo.solicitud
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_flujo_estado();

-- 8.5 Al menos una geometría por solicitud (verificación al confirmar la transacción)
CREATE OR REPLACE FUNCTION nucleo.fn_solicitud_con_geometria() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM nucleo.geometria_intervencion WHERE id_solicitud = NEW.id_solicitud) THEN
        RAISE EXCEPTION 'La solicitud % no tiene geometría: se exige al menos una (§4.4)', NEW.id_solicitud;
    END IF;
    RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER tg_solicitud_con_geometria AFTER INSERT ON nucleo.solicitud
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION nucleo.fn_solicitud_con_geometria();

-- 8.6 Cálculo espacial de comuna, espacio público y elemento vial
--     (relaciones «Espacial» del Anexo R). Fuera de toda comuna = fuera
--     del perímetro de Cali → error bloqueante.
CREATE OR REPLACE FUNCTION nucleo.fn_relaciones_espaciales() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    SELECT c.id_comuna INTO NEW.id_comuna
      FROM referencia.comuna c
     WHERE ST_Intersects(c.geom, NEW.geom)
     ORDER BY ST_Area(ST_Intersection(c.geom, ST_Buffer(NEW.geom, 0.5))) DESC
     LIMIT 1;
    IF NEW.id_comuna IS NULL THEN
        RAISE EXCEPTION 'La geometría está fuera del perímetro de Cali (regla «Dentro del perímetro de Cali»)';
    END IF;
    SELECT e.id_espacio INTO NEW.id_espacio
      FROM referencia.espacio_publico e WHERE ST_Intersects(e.geom, NEW.geom) LIMIT 1;
    SELECT v.id_infraestructura INTO NEW.id_infraestructura
      FROM referencia.infraestructura_vial v
     WHERE ST_DWithin(v.geom, NEW.geom, 10)       -- tolerancia de 10 m (propuesta, calibrable en A-06)
     ORDER BY ST_Distance(v.geom, NEW.geom) LIMIT 1;
    RETURN NEW;
END $$;
CREATE TRIGGER tg_geom_relaciones BEFORE INSERT OR UPDATE OF geom ON nucleo.geometria_intervencion
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_relaciones_espaciales();

-- 8.7 Máximo 12 archivos (primeras versiones) y 3 visitas por solicitud
CREATE OR REPLACE FUNCTION nucleo.fn_limite_archivos() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.version = 1 AND
       (SELECT count(*) FROM nucleo.archivo WHERE id_solicitud = NEW.id_solicitud AND version = 1) >= 12 THEN
        RAISE EXCEPTION 'Máximo 12 archivos por solicitud (HU-03, RS-10)';
    END IF;
    RETURN NEW;
END $$;
CREATE OR REPLACE FUNCTION nucleo.fn_limite_visitas() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF (SELECT count(*) FROM nucleo.visita_tecnica WHERE id_solicitud = NEW.id_solicitud) >= 3 THEN
        RAISE EXCEPTION 'Máximo 3 visitas técnicas por solicitud (HU-13, RS-10)';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER tg_archivo_limite BEFORE INSERT ON nucleo.archivo
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_limite_archivos();
CREATE TRIGGER tg_visita_limite BEFORE INSERT ON nucleo.visita_tecnica
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_limite_visitas();

-- 8.8 Un único detalle por solicitud y coherente con su tipo
--     (TG_ARGV[0] = nombre del tipo en catalogo.tipo_intervencion)
CREATE OR REPLACE FUNCTION nucleo.fn_detalle_segun_tipo() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM nucleo.solicitud s JOIN catalogo.tipo_intervencion t USING (id_tipo)
                   WHERE s.id_solicitud = NEW.id_solicitud AND t.nombre = TG_ARGV[0]) THEN
        RAISE EXCEPTION 'El detalle % no corresponde al tipo de la solicitud %', TG_TABLE_NAME, NEW.id_solicitud;
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER tg_detalle_tipo BEFORE INSERT OR UPDATE ON nucleo.obra_red_servicio FOR EACH ROW EXECUTE FUNCTION nucleo.fn_detalle_segun_tipo('Obra de red de servicios públicos');
CREATE TRIGGER tg_detalle_tipo BEFORE INSERT OR UPDATE ON nucleo.reparacion        FOR EACH ROW EXECUTE FUNCTION nucleo.fn_detalle_segun_tipo('Reparación');
CREATE TRIGGER tg_detalle_tipo BEFORE INSERT OR UPDATE ON nucleo.cierre            FOR EACH ROW EXECUTE FUNCTION nucleo.fn_detalle_segun_tipo('Cierre');
CREATE TRIGGER tg_detalle_tipo BEFORE INSERT OR UPDATE ON nucleo.ocupacion_anden   FOR EACH ROW EXECUTE FUNCTION nucleo.fn_detalle_segun_tipo('Ocupación de andén');
CREATE TRIGGER tg_detalle_tipo BEFORE INSERT OR UPDATE ON nucleo.excavacion        FOR EACH ROW EXECUTE FUNCTION nucleo.fn_detalle_segun_tipo('Excavación');
CREATE TRIGGER tg_detalle_tipo BEFORE INSERT OR UPDATE ON nucleo.mantenimiento     FOR EACH ROW EXECUTE FUNCTION nucleo.fn_detalle_segun_tipo('Mantenimiento');
CREATE TRIGGER tg_detalle_tipo BEFORE INSERT OR UPDATE ON nucleo.emergencia        FOR EACH ROW EXECUTE FUNCTION nucleo.fn_detalle_segun_tipo('Emergencia');

-- ---------------------------------------------------------------------
-- 9. Detección de duplicidades y conflictos (HU-08, RNF-03)
--    Umbral inicial 50 m (catálogo de umbrales, calibración en A-06).
--    Criterio de tipo y nivel: PROPUESTA del equipo, por calibrar.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION nucleo.fn_detectar_conflictos(p_id_solicitud integer, p_umbral_m numeric DEFAULT 50)
RETURNS TABLE (id_solicitud_relacionada integer, tipo varchar, nivel varchar, distancia_m numeric)
LANGUAGE sql STABLE AS $$
    WITH origen AS (
        SELECT s.id_solicitud, s.id_tipo, s.entidad_responsable,
               daterange(s.fecha_inicio, s.fecha_fin, '[]') AS rango, g.geom
          FROM nucleo.solicitud s JOIN nucleo.geometria_intervencion g USING (id_solicitud)
         WHERE s.id_solicitud = p_id_solicitud
    ), candidatos AS (
        SELECT s.id_solicitud, s.id_tipo, s.entidad_responsable, t.nombre AS tipo_nombre,
               min(ST_Distance(o.geom, g.geom)) AS dist,
               bool_or(o.id_tipo = s.id_tipo) AS mismo_tipo,
               bool_or(o.entidad_responsable = s.entidad_responsable) AS misma_entidad
          FROM origen o
          JOIN nucleo.geometria_intervencion g ON ST_DWithin(o.geom, g.geom, p_umbral_m)
          JOIN nucleo.solicitud s ON s.id_solicitud = g.id_solicitud
          JOIN catalogo.tipo_intervencion t ON t.id_tipo = s.id_tipo
          JOIN catalogo.estado_tramite e ON e.id_estado = s.id_estado
         WHERE s.id_solicitud <> o.id_solicitud
           AND daterange(s.fecha_inicio, s.fecha_fin, '[]') && o.rango
           AND e.nombre NOT IN ('Rechazada','Cerrada')
         GROUP BY s.id_solicitud, s.id_tipo, s.entidad_responsable, t.nombre
    )
    SELECT c.id_solicitud,
           (CASE WHEN c.mismo_tipo AND c.misma_entidad THEN 'Duplicidad' ELSE 'Conflicto' END)::varchar,
           (CASE WHEN c.dist = 0 AND (c.tipo_nombre IN ('Cierre','Excavación','Obra de red de servicios públicos')
                                      OR (SELECT t2.nombre FROM catalogo.tipo_intervencion t2
                                            JOIN nucleo.solicitud s2 ON s2.id_tipo = t2.id_tipo
                                           WHERE s2.id_solicitud = p_id_solicitud)
                                         IN ('Cierre','Excavación','Obra de red de servicios públicos'))
                      THEN 'Crítico'
                 WHEN c.dist = 0 THEN 'Alto'
                 WHEN c.dist <= p_umbral_m / 2 THEN 'Medio'
                 ELSE 'Bajo' END)::varchar,
           round(c.dist::numeric, 2)
      FROM candidatos c
     ORDER BY c.dist;
$$;

-- ---------------------------------------------------------------------
-- 10. Publicación sin datos personales para GeoServer (SP-01, RNF-19)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW publicacion.v_intervenciones AS
SELECT g.id_geometria, r.numero_radicado, t.nombre AS tipo_intervencion, e.nombre AS estado,
       s.fecha_inicio, s.fecha_fin, c.nombre AS comuna, g.tipo_geometria, g.geom
  FROM nucleo.geometria_intervencion g
  JOIN nucleo.solicitud s           ON s.id_solicitud = g.id_solicitud
  JOIN nucleo.radicacion r          ON r.id_solicitud = s.id_solicitud
  JOIN catalogo.tipo_intervencion t ON t.id_tipo = s.id_tipo
  JOIN catalogo.estado_tramite e    ON e.id_estado = s.id_estado
  JOIN referencia.comuna c          ON c.id_comuna = g.id_comuna;

CREATE OR REPLACE VIEW publicacion.v_visitas AS
SELECT v.id_visita, r.numero_radicado, v.fecha_programada, v.estado_implementacion,
       v.precision_gps_m, v.ubicacion_gps AS geom
  FROM nucleo.visita_tecnica v
  JOIN nucleo.radicacion r ON r.id_solicitud = v.id_solicitud
 WHERE v.ubicacion_gps IS NOT NULL;

-- ---------------------------------------------------------------------
-- 11. Indicadores del panel (HU-18). Refresco cada 10 min (tarea
--     programada de Celery): REFRESH MATERIALIZED VIEW CONCURRENTLY ...
-- ---------------------------------------------------------------------
CREATE MATERIALIZED VIEW indicadores.mv_solicitudes_por_estado AS
SELECT e.id_estado, e.nombre AS estado, count(s.id_solicitud) AS total, now() AS actualizado
  FROM catalogo.estado_tramite e
  LEFT JOIN nucleo.solicitud s ON s.id_estado = e.id_estado
 GROUP BY e.id_estado, e.nombre;
CREATE UNIQUE INDEX ux_mv_estado ON indicadores.mv_solicitudes_por_estado (id_estado);

CREATE MATERIALIZED VIEW indicadores.mv_intervenciones_por_comuna AS
SELECT c.id_comuna, c.nombre AS comuna, count(DISTINCT g.id_solicitud) AS total, now() AS actualizado
  FROM referencia.comuna c
  LEFT JOIN nucleo.geometria_intervencion g ON g.id_comuna = c.id_comuna
 GROUP BY c.id_comuna, c.nombre;
CREATE UNIQUE INDEX ux_mv_comuna ON indicadores.mv_intervenciones_por_comuna (id_comuna);

CREATE MATERIALIZED VIEW indicadores.mv_tiempo_revision AS
SELECT date_trunc('month', r.fecha_hora) AS mes,
       round(avg(EXTRACT(epoch FROM (rv.primera_decision - r.fecha_hora)) / 86400.0)::numeric, 2) AS dias_promedio_revision,
       count(*) AS solicitudes_decididas, now() AS actualizado
  FROM nucleo.radicacion r
  JOIN (SELECT id_solicitud, min(fecha_hora) AS primera_decision
          FROM nucleo.revision_tecnica GROUP BY id_solicitud) rv USING (id_solicitud)
 GROUP BY 1;
CREATE UNIQUE INDEX ux_mv_tiempo ON indicadores.mv_tiempo_revision (mes);

-- ---------------------------------------------------------------------
-- 12. Roles de base de datos (sin LOGIN; principio de mínimo privilegio, §8.5)
-- ---------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sigep_app')       THEN CREATE ROLE sigep_app NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sigep_geoserver') THEN CREATE ROLE sigep_geoserver NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sigep_sync')      THEN CREATE ROLE sigep_sync NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sigep_auditor')   THEN CREATE ROLE sigep_auditor NOLOGIN; END IF;
END $$;

-- API: lectura y escritura en catálogo y núcleo; en auditoría solo INSERT y SELECT
GRANT USAGE ON SCHEMA catalogo, nucleo, referencia, auditoria, indicadores, publicacion TO sigep_app;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA catalogo, nucleo TO sigep_app;
GRANT SELECT ON ALL TABLES IN SCHEMA referencia, indicadores, publicacion TO sigep_app;
GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA auditoria TO sigep_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA catalogo, nucleo, auditoria TO sigep_app;
REVOKE UPDATE, DELETE, TRUNCATE ON nucleo.historial_estado FROM sigep_app;
-- GeoServer: solo lectura de las vistas de publicación y de referencia
GRANT USAGE ON SCHEMA publicacion, referencia TO sigep_geoserver;
GRANT SELECT ON ALL TABLES IN SCHEMA publicacion, referencia TO sigep_geoserver;
-- Sincronización con IDESC: única cuenta con escritura en «referencia»
GRANT USAGE ON SCHEMA referencia TO sigep_sync;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA referencia TO sigep_sync;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA referencia TO sigep_sync;
-- Auditoría o control interno: consulta de la bitácora sin modificarla (Tabla 62)
GRANT USAGE ON SCHEMA auditoria, nucleo TO sigep_auditor;
GRANT SELECT ON auditoria.bitacora_auditoria, nucleo.historial_estado TO sigep_auditor;

COMMIT;
