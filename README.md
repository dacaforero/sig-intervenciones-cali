# Sistema SIG para la Gestión de Intervenciones en el Espacio Público de Santiago de Cali

> **Propuesta académica · Taller 3 (Despliegue) · Gestión de Proyectos de Información Geoespacial · Universidad del Valle.**
> Este repositorio es un **ejercicio académico simulado**: organiza los artefactos que exige la *Guía de despliegue de
> sistemas de información* de DATIC (MAGT04.04.01.P004.G001, apartado 4.2). El sistema **no ha sido desarrollado,
> instalado ni aprobado**. Los datos de ejemplo, direcciones IP, dominios y radicados son ficticios y se identifican con el
> prefijo `SIM-` o con rangos reservados para documentación.

**Estado del README:** v0.4. **Infraestructura:** datacenter de DATIC (decisión DE-13). Instalación descrita en el
manual MAN-01 (el sistema no se ha instalado en ningún ambiente institucional).

## Descripción

Sistema de información geográfica institucional para centralizar la radicación, revisión, georreferenciación, seguimiento
y análisis de las intervenciones en el espacio público y la infraestructura vial (obras de redes, reparaciones, cierres,
ocupaciones de andén, excavaciones, mantenimientos y emergencias).

**Objetivo general (Taller 2, §2.3.1):** implementar un sistema de información geográfica institucional que unifique en una
sola base geográfica, y con trazabilidad completa, el 100 % de las solicitudes nuevas de intervención en el espacio público
de Santiago de Cali.

## Arquitectura en una línea

PWA (React + TypeScript + OpenLayers) → proxy inverso y WAF (Nginx) → API REST (Python + FastAPI, monolito modular) y
tareas asíncronas (Celery + Redis) → PostgreSQL + PostGIS (EPSG:9377) y almacenamiento de objetos S3; GeoServer publica
las capas por WMS, WFS y OGC API – Features; Keycloak gestiona la identidad. Detalle: `Documentación/Arquitectura/`.

## Estructura

| Carpeta | Contenido |
|---|---|
| `frontend/` | Cliente web PWA (portal, bandeja, panel, mapa y módulo móvil de visitas) |
| `backend/` | API REST y tareas asíncronas |
| `base-datos/` | Scripts de creación, catálogos, datos simulados y verificación |
| `servicios-geograficos/` | Configuración de GeoServer y sincronización con IDESC |
| `identidad/` | Configuración de Keycloak (roles, clientes; sin secretos) |
| `despliegue/` | Manifiestos de K3s y configuración por ambiente en los servidores de DATIC |
| `monitoreo/` | Alertas y tableros (Prometheus, Grafana, Loki) |
| `Documentación/` | Manuales, modelo de datos, pruebas y arquitectura (exigido por la guía 4.2) |

## Tecnologías (Taller 2, Tabla 27)

React · TypeScript · OpenLayers · Python · FastAPI · GDAL/OGR · Shapely · pyproj · Celery · Redis · PostgreSQL · PostGIS ·
GeoServer · GeoWebCache · Keycloak · ClamAV · Nginx · Docker · Kubernetes (K3s o gestionado) · Prometheus · Grafana · Loki.

## Base de datos

```bash
# Ejemplo verificado solo en un entorno académico local (PostgreSQL 16 + PostGIS 3.4), nunca en producción:
psql -v ON_ERROR_STOP=1 -d <base_de_prueba> -f base-datos/01_creacion_esquema.sql
psql -v ON_ERROR_STOP=1 -d <base_de_prueba> -f base-datos/02_carga_catalogos.sql
psql -v ON_ERROR_STOP=1 -d <base_de_prueba> -f base-datos/03_datos_ejemplo_SIMULADOS.sql   # solo pruebas
psql -v ON_ERROR_STOP=1 -d <base_de_prueba> -f base-datos/04_verificacion.sql
```

## Instalación y ejecución

Despliegue en el datacenter de DATIC: 14 máquinas virtuales en producción con Ubuntu Server 24.04 LTS (Taller 2, Tabla 31,
más almacenamiento y respaldos propuestos) y clúster K3s de 3 nodos. El procedimiento completo está en
`Documentación/Manuales/MAN-01_Manual-Instalacion_v1.3.pdf`. Resumen del orden (MAN-01 §4.1):

1. DATIC entrega los servidores, las reglas de red R1 a R13, el subdominio y el certificado (guía 4.1 y 4.2).
2. Preparación del sistema operativo (hora, SSH con llave, cortafuegos local, agentes de monitoreo).
3. PostgreSQL 16 + PostGIS 3.4 en sigep-db01 con réplica en db02; scripts `01` y `02` (el `03` **nunca** en producción).
4. Almacenamiento S3, clúster K3s con secretos cifrados, Redis y ClamAV.
5. Keycloak, API, Celery y Beat (una sola réplica), GeoServer y frontend.
6. Proxy Nginx + ModSecurity en sigep-lb01/02; monitoreo y respaldos (MAN-04).
7. Verificaciones V-01 a V-13, pruebas básicas PB-01 a PB-13 y lista de comprobación.

Los manifiestos de ejemplo están en `despliegue/`. Todos los comandos del manual son **ejemplos** que deben validarse
con el código real.

## Configuración

Las variables de configuración están descritas en `.env.example` con **valores ficticios**. Las credenciales reales nunca se
guardan en el repositorio: se gestionan en el gestor de secretos (Taller 2, §8.5).

## Documentación

| Documento | Ubicación |
|---|---|
| Modelo de datos y modelo relacional (MD-01), diagrama (MD-02), diccionario (MD-03) | `Documentación/Modelo de Datos/` |
| Arquitectura de producción (ARQ-01 v1.1: lógica y física en DATIC) y diagramas | `Documentación/Arquitectura/` |
| Manuales de instalación (MAN-01), operación (MAN-02), mantenimiento (MAN-03) y copias de seguridad (MAN-04) | `Documentación/Manuales/` |
| Plan, casos, informes y actas de pruebas PRU-00 a PRU-07 (paquete de pruebas) | `Documentación/Pruebas/` |

## Limitaciones conocidas

- No hay código funcional; las carpetas de código contienen la estructura propuesta.
- Recursos, capacidades y metas son estimaciones del Taller 2, no mediciones.
- Las integraciones institucionales no se han probado contra servicios reales.
- Los resultados de pruebas (PRU-01 a PRU-06) son simulados. El acta PRU-07 emite una recomendación condicionada: no pasar a
  producción hasta confirmar la copia externa de respaldo, verificar la seguridad real y hacer la UAT sobre una versión ejecutable.

## Contacto institucional

Responsable funcional, CTO del organismo y contacto técnico: **dato pendiente de definición** (no se inventan nombres ni correos).

## Créditos académicos

Equipo del Taller 2: Hillary Barrios Ordoñez, Danna Camila Forero Borda, Karol Andrea Hoyos Echandia, Mariana Durán Hoyos.
Paquete técnico de producción (Taller 3): Danna Camila Forero Borda. Paquete de pruebas (Taller 3): Karol Andrea Hoyos Echandia.
