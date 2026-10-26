> **SIMULACIÓN ACADÉMICA · Taller 3.** Esta carpeta contiene la estructura propuesta y la descripción de su contenido. No contiene código funcional: el sistema no ha sido desarrollado. Ver `Documentación/` y el registro de decisiones DEC-01.

# servicios-geograficos — GeoServer + GeoWebCache (C05) e IDESC

| Carpeta propuesta | Contenido |
|---|---|
| `geoserver/capas/` | Definición de las capas publicadas (SP-01) |
| `geoserver/estilos/` | Estilos SLD por estado del trámite (color + ícono + texto, §4.5.5) |
| `idesc/` | Parámetros de la sincronización semanal de las 4 capas de referencia (DE-02) |
| `metadatos/` | Fichas de metadatos según NTC 4611 (RNF-18) |

Capas propias: `publicacion.v_intervenciones` y `publicacion.v_visitas` (sin datos personales, RNF-19).
SRS de publicación: EPSG:9377 (almacenamiento), EPSG:6249, EPSG:4326 y EPSG:3857 (DE-01).
La interfaz de administración de GeoServer no se expone fuera de la VPN (§8.7).
