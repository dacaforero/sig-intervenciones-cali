> **SIMULACIÓN ACADÉMICA · Taller 3.** Esta carpeta contiene la estructura propuesta y la descripción de su contenido. No contiene código funcional: el sistema no ha sido desarrollado. Ver `Documentación/` y el registro de decisiones DEC-01.

# backend — API REST (C03) y tareas asíncronas (C06, C07)

Python + FastAPI como monolito modular (AD-01); Celery y Celery Beat para tareas en segundo plano.

| Carpeta propuesta | Módulo (Taller 2, §4.4.4) |
|---|---|
| `app/modulos/radicacion/` | Formulario, archivos y número de radicado |
| `app/modulos/flujo_estados/` | Asignación, decisión e historial |
| `app/modulos/validacion_espacial/` | Reglas espaciales (mínimo cinco) |
| `app/modulos/duplicidades/` | Detección de duplicidades y conflictos |
| `app/modulos/notificaciones/` | Correos por cambio de estado |
| `app/modulos/indicadores/` | Panel de seguimiento |
| `app/modulos/auditoria/` | Bitácora y consulta de trazabilidad |
| `app/geometrias/` | Procesamiento con GDAL/OGR, Shapely y pyproj |
| `app/integraciones/` | Adaptadores: mensajería, gestión documental, IDESC |
| `tareas/` | Tareas Celery y programación periódica (Celery Beat) |
| `pruebas/` | Pruebas automáticas (cobertura ≥ 70 %, RNF-17) |

La API publica su documentación OpenAPI (RNF-17) y fija el contexto de sesión en la base de datos
(`app.id_usuario`, `app.origen`, `app.observacion`) en cada transacción (MD-01 §11); sin ellas, la bitácora registra el cambio sin usuario.
