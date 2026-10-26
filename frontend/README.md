> **SIMULACIÓN ACADÉMICA · Taller 3.** Esta carpeta contiene la estructura propuesta y la descripción de su contenido. No contiene código funcional: el sistema no ha sido desarrollado. Ver `Documentación/` y el registro de decisiones DEC-01.

# frontend — Cliente web PWA (C00)

React + TypeScript + OpenLayers (Taller 2, Tabla 27; AD-05). Una sola aplicación para escritorio y móvil.

| Carpeta propuesta | Contenido |
|---|---|
| `src/vistas/acceso/` | Vista 1 · Acceso (HU-01) |
| `src/vistas/radicacion/` | Vista 2 · Formulario de radicación en 4 pasos (HU-02 a HU-04) |
| `src/vistas/mapa/` | Vista 3 · Mapa SIG institucional (HU-16, HU-17) |
| `src/vistas/panel/` | Vista 4 · Panel de seguimiento (HU-12, HU-18) |
| `src/vistas/visitas/` | Vista 5 · Registro de visita en móvil, sin conexión (HU-14, HU-15) |
| `src/cartografia/` | Configuración de OpenLayers, capas propias (GeoServer) y de IDESC (vía adaptador) |
| `src/sincronizacion/` | Service worker, borradores (DE-07) y cola local de visitas (DE-03) |
| `public/` | Manifiesto PWA e íconos |

Requisitos clave: WCAG 2.1 AA (RNF-15), 360–1920 px (RNF-16), fotografías comprimidas a ≤ 2,5 MB (HU-15).
