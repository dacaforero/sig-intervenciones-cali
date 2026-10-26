> **SIMULACIÓN ACADÉMICA · Taller 3.** Esta carpeta contiene la estructura propuesta y la descripción de su contenido. No contiene código funcional: el sistema no ha sido desarrollado. Ver `Documentación/` y el registro de decisiones DEC-01.

# monitoreo — Prometheus, Grafana y Loki (C12)

Reglas de alerta propuestas (Taller 2, Tabla 66), con aviso al administrador en 5 minutos o menos:

| Qué se mide | Umbral |
|---|---|
| Disponibilidad mensual | < 99,5 % |
| Consulta simple del mapa | percentil 95 > 3 s |
| Interfaces de integración | una interfaz con error o sin respuesta |
| CPU y memoria de los nodos | > 80 % sostenido 10 min |
| Peticiones HTTP | > 35 por segundo sostenidas (umbral de escalamiento) |
| Almacenamiento | > 75 % de la capacidad |
| Cola de tareas | tareas con más de 3 reintentos fallidos |
| Respaldos | un respaldo diario no completado |
| Seguridad | ráfagas de intentos fallidos o errores 5xx anómalos |
