# pruebas — ambiente de pruebas de DATIC (guía 4.1), simulado

Servidores: sigep-qas-app01 (192.0.2.21) y sigep-qas-db01 (192.0.2.22). K3s de un nodo, base sin réplica, un nodo S3,
Nginx sin balanceo (MAN-01 §1.2). Se reutilizan los manifiestos de `produccion/` con otra configuración (ConfigMap y
secretos distintos) y 1 réplica por despliegue. El script `03_datos_ejemplo_SIMULADOS.sql` solo se permite aquí.
Resultados de las pruebas: paquete PRU (Karol Andrea Hoyos Echandia).
