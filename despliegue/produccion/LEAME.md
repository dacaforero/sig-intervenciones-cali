# produccion — esqueleto (simulado)

| Archivo | Qué es | Sección de MAN-01 |
|---|---|---|
| `configmap-sigep.yaml` | Variables no sensibles | §11 |
| `api.yaml` | Despliegue y servicio de la API (6 réplicas) | §6, anexo C |
| `beat.yaml` | Celery Beat con una sola réplica | §3.1, §6 |
| `perimetro/nginx.conf.ejemplo` | Proxy de sigep-lb01/02 (sin ModSecurity); su sintaxis pasó `nginx -t` con Nginx 1.24 en el entorno académico local | §12, anexo A |

Pendientes con el código real (D9): frontend, Celery, Keycloak, GeoServer, Redis, ClamAV e ingress.
El Secret `sigep-secretos` **no** se versiona: se crea a mano en la instalación (MAN-01 §11).
