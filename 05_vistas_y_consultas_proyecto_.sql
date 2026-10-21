SHOW TABLES;
DESCRIBE reservas;

SELECT calcular_total_reserva(100000, 3);   -- 357000.00

SELECT verificar_disponibilidad(1, '2026-10-25 16:00', '2026-10-25 20:00');  -- 0 (se cruza)
SELECT verificar_disponibilidad(1, '2026-10-25 18:00', '2026-10-25 22:00');  -- 1 (justo después)
SELECT verificar_disponibilidad(1, '2026-10-26 10:00', '2026-10-26 12:00');  -- 1 (otro día)
SELECT verificar_disponibilidad(3, '2026-10-26 10:00', '2026-10-26 12:00');  -- 0 (mantenimiento)

#necesité revisar si los triggers estaban bien creados así que hice esta consulta;
USE eventos_premier;
SHOW TRIGGERS;
SHOW CREATE TRIGGER liberar_salon_trigger;

#creación de vista /////////////////////////////////////////////////

CREATE OR REPLACE VIEW vista_resumen_reservas AS
SELECT
  r.id_reserva,
  c.nombre_completo AS cliente,
  s.nombre          AS salon,
  r.fecha_inicio,
  r.fecha_fin,
  r.valor_total     AS total,
  r.estado
FROM reservas r
JOIN clientes c ON c.id_cliente = r.id_cliente
JOIN salones  s ON s.id_salon   = r.id_salon;

SELECT * FROM vista_resumen_reservas;

#Consulta 1: reservas en un rango de fechas (BETWEEN)////////////////////////

SELECT *
FROM vista_resumen_reservas
WHERE fecha_inicio BETWEEN '2026-10-01 00:00:00' AND '2026-10-31 23:59:59';

#////////////////////////////////////////////

#Consulta 2: salones con capacidad mayor a X y disponibles ////////////////
SELECT nombre, capacidad, precio_hora
FROM salones
WHERE capacidad > 40
  AND estado = 'Disponible';

#Consulta 3: clientes corporativos con más de 3 reservas////////////////////////

SELECT c.id_cliente, c.nombre_completo, COUNT(r.id_reserva) AS total_reservas
FROM clientes c
JOIN reservas r ON r.id_cliente = c.id_cliente
WHERE c.tipo_cliente = 'Corporativo'
GROUP BY c.id_cliente, c.nombre_completo
HAVING COUNT(r.id_reserva) > 3;

#////////////////////////////////////////////

