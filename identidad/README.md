> **SIMULACIÓN ACADÉMICA · Taller 3.** Esta carpeta contiene la estructura propuesta y la descripción de su contenido. No contiene código funcional: el sistema no ha sido desarrollado. Ver `Documentación/` y el registro de decisiones DEC-01.

# identidad — Keycloak (C04)

Exportación de la configuración del dominio (realm) **sin secretos**.

- Roles: Solicitante externo, Revisor técnico, Inspector de campo, Coordinador funcional, Administrador tecnológico,
  Auditoría / control interno (inactivo, DE-08) — Tabla 55.
- Federación del directorio institucional (OIDC, SAML 2.0 o LDAPS; IF-01) y cuentas locales de solicitantes.
- Políticas: bloqueo 15 min tras 5 intentos; sesión 30 min de inactividad; segundo factor obligatorio para el
  administrador tecnológico (RNF-10); contraseñas de 12 caracteres o más (§7.2).
- Base de datos propia en C09 (AP-01) y correo de verificación por IF-02 (AP-02).
