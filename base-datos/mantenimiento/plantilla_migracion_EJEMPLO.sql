-- =====================================================================
-- MIGRACIÓN DE EJEMPLO (plantilla del manual de mantenimiento MAN-03)
-- Nombre: AAAAMMDD_NN_descripcion.sql  →  20270901_01_ejemplo_agregar_plan_desvio.sql
-- Propósito ilustrativo: agregar a nucleo.cierre un indicador de plan de desvío.
-- No es un cambio aprobado del modelo: muestra la estructura que debe tener toda migración.
-- =====================================================================
-- SUBIR (aplicar)
BEGIN;
SET LOCAL lock_timeout = '5s';          -- no bloquear la operación si la tabla está ocupada
ALTER TABLE nucleo.cierre ADD COLUMN IF NOT EXISTS plan_desvio boolean NOT NULL DEFAULT false;
COMMENT ON COLUMN nucleo.cierre.plan_desvio IS 'Indica si el cierre cuenta con plan de desvío aprobado (ejemplo de migración).';
COMMIT;

-- BAJAR (revertir) — se ejecuta solo si la verificación posterior falla
-- BEGIN;
-- ALTER TABLE nucleo.cierre DROP COLUMN IF EXISTS plan_desvio;
-- COMMIT;
