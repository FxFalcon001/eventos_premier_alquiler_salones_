-- 1) Cálculo automático + estado "Ocupado"
INSERT INTO reservas (id_cliente, id_salon, fecha_inicio, fecha_fin)
VALUES (2, 2, '2026-10-28 09:00:00', '2026-10-28 13:00:00');

SELECT total_horas, valor_total FROM reservas ORDER BY id_reserva DESC LIMIT 1;  -- 4.00 y 952000.00
SELECT id_salon, estado FROM salones WHERE id_salon = 2;                         -- Ocupado

-- 2) Cruce rechazado (debe dar error 1644)
INSERT INTO reservas (id_cliente, id_salon, fecha_inicio, fecha_fin)
VALUES (1, 2, '2026-10-28 11:00:00', '2026-10-28 15:00:00');

-- 3) Auditoría
UPDATE salones SET precio_hora = 220000 WHERE id_salon = 2;
SELECT * FROM auditoria_precios;
UPDATE salones SET precio_hora = 200000 WHERE id_salon = 2;  -- lo devolvemos (genera otra fila de auditoría, es normal)

-- 4) Liberar salón
DELETE FROM reservas WHERE id_salon = 2 AND fecha_inicio = '2026-10-28 09:00:00';
SELECT id_salon, estado FROM salones WHERE id_salon = 2;     -- Disponible