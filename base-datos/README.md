# base-datos — Scripts de PostgreSQL + PostGIS (C09)

Scripts **reales** del Taller 3, verificados en un **entorno académico local** (PostgreSQL 16.15, PostGIS 3.4.2) el 2026-10-23.
No se han ejecutado en un ambiente institucional.

| Script | Contenido | ¿Producción? |
|---|---|---|
| `01_creacion_esquema.sql` | Esquemas, 34 tablas, restricciones, índices, triggers, vistas y roles | Sí |
| `02_carga_catalogos.sql` | Roles, tipos, estados, transiciones y documentos (valores propuestos) | Sí, tras validar catálogos (D-06) |
| `03_datos_ejemplo_SIMULADOS.sql` | Datos ficticios para pruebas | **Nunca** |
| `04_verificacion.sql` | Consultas y 10 pruebas negativas | Solo en pruebas |

`migraciones/`: cambios posteriores numerados AAAAMMDD_NN_descripcion.sql (MAN-03 §8). `mantenimiento/`: consultas de verificación y plantilla de migración de ejemplo (no aplicar). Documentación: `Documentación/Modelo de Datos/`.
