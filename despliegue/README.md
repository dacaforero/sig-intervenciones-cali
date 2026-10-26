> **SIMULACIÓN ACADÉMICA · Taller 3.** Esta carpeta contiene la estructura propuesta y la descripción de su contenido. No contiene código funcional: el sistema no ha sido desarrollado. Ver `Documentación/` y el registro de decisiones DEC-01.

# despliegue — Datacenter de DATIC (DE-13)

Manifiestos de K3s sobre las máquinas virtuales de DATIC y configuración de Nginx con ModSecurity (DE-15, DE-16).

| Subcarpeta | Ambiente | Servidores (simulados) |
|---|---|---|
| `pruebas/` | Pruebas y aceptación (paquete de Karol) | sigep-qas-app01 192.0.2.21 · sigep-qas-db01 192.0.2.22 |
| `produccion/` | Producción | 14 máquinas virtuales: ver ARQ-01 §14 e INV-01, hoja Servidores |

Contenido: esqueleto de ejemplo alineado con el manual de instalación (MAN-01). Nada se ha aplicado en un clúster real.
Direcciones IP simuladas (RFC 5737). Los secretos nunca se versionan.
