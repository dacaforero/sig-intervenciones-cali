# Registro de cambios

Formato basado en *Keep a Changelog*; versiones según *Semantic Versioning* (ver REP-01).

## [Sin publicar] — Taller 3
### Agregado
- Estructura del repositorio según la guía de despliegue de DATIC (4.2) — REP-01.
- `base-datos/`: scripts 01 a 04 verificados en entorno académico local (2026-10-23).
- `Documentación/Modelo de Datos/`: MD-01, MD-02 y MD-03 (diccionario v2).
- `Documentación/Arquitectura/`: ARQ-01 v1.1 (capa lógica y capa física en DATIC) y diagramas D1 a D5.
### Cambiado
- Se adopta el despliegue en el datacenter de DATIC (DEC-01, DE-13).
### Agregado (manuales)
- `Documentación/Manuales/`: MAN-03 Manual de mantenimiento v1.0 y MAN-04 Manual de copias de seguridad y restauración v1.0 (con prueba técnica local de pgBackRest y restic); `base-datos/mantenimiento/` con consultas de verificación.
- `Documentación/Manuales/`: MAN-01 Manual de instalación v1.0 (prueba local de la base de datos y de la sintaxis del proxy).
- `despliegue/`: esqueleto de manifiestos de ejemplo (ConfigMap, API, Beat) y configuración de ejemplo del perímetro.
- README v0.3 con el resumen de instalación.
- `Documentación/Manuales/`: MAN-02 Manual de operación v1.0; `base-datos/mantenimiento/consultas_operacion.sql` (O1 a O10, probadas localmente).
### Corregido
- MAN-01 v1.1: IDESC es IF-05; federación del directorio según el Taller 2 (OIDC o SAML 2.0; LDAPS como alternativa).
- MAN-01 v1.2: la entrega de credenciales con sudo al CTO es de la guía 4.1 (pruebas); en producción es propuesta temporal (TRA-01).
- MAN-01 v1.3 y MAN-02 v1.1: códigos de componentes alineados con ARQ-01 (monitoreo C12; respaldos C13 y C14; PWA C00 servida por C02).
- README de `backend/`: se agrega la variable de sesión `app.observacion`.
- `Documentación/Arquitectura/ARQUITECTURA.md` pasa a `LEAME.md` (convención de nombres, detectado por el verificador de LIS-01).
### Agregado (pruebas)
- `Documentación/Pruebas/`: PRU-00 a PRU-07 del paquete de pruebas (Karol Andrea Hoyos Echandia): plan, 44 casos funcionales, rendimiento, seguridad, habeas data, estrés, restauración y acta consolidada. Versiones finales, con las correcciones de la revisión cruzada aplicadas en PRU-01, PRU-02, PRU-05 y PRU-07 (las versiones conservan su número; ver PTP-01).
- README v0.4.
### Pendiente
- Cierre de las tres condiciones de salida de PRU-07 (fuera del alcance académico).
- Migración con catalogo.parametro, catalogo.dia_festivo, catalogo.plantilla_notificacion y el rol sigep_consulta (DEC-01, DE-18 y DE-19).
