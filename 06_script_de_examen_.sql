
# Bueno, primero que todo voy a crear otras tablas

USE eventos_premier;

CREATE TABLE IF NOT EXISTS auditoria_abonos (
  id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
  id_pago INT NOT NULL,
  tipo_movimiento ENUM('INSERT','UPDATE') NOT NULL,
  fecha_movimiento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  valor_anterior DECIMAL(12,2) NULL,
  valor_nuevo DECIMAL(12,2) NOT NULL,
  usuario VARCHAR(100) NOT NULL
);

USE eventos_premier;

CREATE TABLE IF NOT EXISTS auditoria_abonos (
  id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
  id_pago INT NOT NULL,
  tipo_movimiento ENUM('INSERT','UPDATE') NOT NULL,
  fecha_movimiento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  valor_anterior DECIMAL(12,2) NULL,
  valor_nuevo DECIMAL(12,2) NOT NULL,
  usuario VARCHAR(100) NOT NULL
);



#//////////////////////////////////////////////////////////////////
# Ahora, la creación de la función

DROP FUNCTION IF EXISTS calcular_valor_pendiente;

DELIMITER $$

CREATE FUNCTION calcular_valor_pendiente(p_total_reserva DECIMAL(12,2), p_abono DECIMAL(12,2))
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
  RETURN p_total_reserva - COALESCE(p_abono, 0);
END$$

DELIMITER ;

# ///////////////////////////////////////////////////////////////////////////
#creación de consulta


SELECT
  c.nombre_completo AS cliente,
  r.fecha_inicio    AS fecha_reserva,
  r.valor_total     AS total,
  COALESCE(SUM(p.monto), 0) AS abono,
  calcular_valor_pendiente(r.valor_total, SUM(p.monto)) AS valor_pendiente
FROM reservas r
JOIN clientes c   ON c.id_cliente = r.id_cliente
LEFT JOIN pagos p ON p.id_reserva = r.id_reserva
WHERE r.estado <> 'Cancelada'
GROUP BY r.id_reserva, c.nombre_completo, r.fecha_inicio, r.valor_total
HAVING valor_pendiente > 0;


#/////////////////////////////////////////////////////////////////////////////
#creación de la vista


CREATE OR REPLACE VIEW vista_facturacion_reservas AS
SELECT
  c.nombre_completo AS nombre_cliente,
  r.fecha_inicio    AS fecha_reserva,
  r.valor_total     AS total_reserva,
  COALESCE(SUM(p.monto), 0) AS abono,
  calcular_valor_pendiente(r.valor_total, SUM(p.monto)) AS valor_pendiente
FROM reservas r
JOIN clientes c   ON c.id_cliente = r.id_cliente
LEFT JOIN pagos p ON p.id_reserva = r.id_reserva
WHERE r.estado <> 'Cancelada'
GROUP BY r.id_reserva, c.nombre_completo, r.fecha_inicio, r.valor_total;

SELECT * FROM vista_facturacion_reservas;

#////////////////////////////////////////////////////////////////////////////////
#creación del trigger


DROP TRIGGER IF EXISTS auditar_abono_trigger;
DROP TRIGGER IF EXISTS auditar_abono_update_trigger;

DELIMITER $$

CREATE TRIGGER auditar_abono_trigger
AFTER INSERT ON pagos
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_abonos (id_pago, tipo_movimiento, valor_anterior, valor_nuevo, usuario)
  VALUES (NEW.id_pago, 'INSERT', NULL, NEW.monto, CURRENT_USER());
END$$

CREATE TRIGGER auditar_abono_update_trigger
AFTER UPDATE ON pagos
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_abonos (id_pago, tipo_movimiento, valor_anterior, valor_nuevo, usuario)
  VALUES (NEW.id_pago, 'UPDATE', OLD.monto, NEW.monto, CURRENT_USER());
END$$

DELIMITER ;

#//////////////////////////////////////////////////////////////////////////////////
# prueba (aquí estoy revisando que se haya creado bien la función y cuántas hay)


SHOW FUNCTION STATUS WHERE Db = 'eventos_premier';


SELECT calcular_valor_pendiente(476000, 200000);   -- 276000.00
SELECT calcular_valor_pendiente(476000, 476000);   -- 0.00
SELECT calcular_valor_pendiente(476000, NULL);     -- 476000.00

INSERT INTO pagos (id_reserva, fecha_pago, monto, metodo_pago)
VALUES (2, CURDATE(), 452000, 'Efectivo');

UPDATE pagos SET monto = 450000 WHERE id_pago = (SELECT MAX(id_pago) FROM (SELECT id_pago FROM pagos) t);

SELECT * FROM auditoria_abonos;

#/////////////////////////////////////////////////////////////////

SELECT
  c.nombre_completo AS cliente,
  COUNT(*) AS reservas_pagadas
FROM clientes c
JOIN (
  SELECT r.id_reserva, r.id_cliente
  FROM reservas r
  LEFT JOIN pagos p ON p.id_reserva = r.id_reserva
  WHERE r.estado <> 'Cancelada'
  GROUP BY r.id_reserva, r.id_cliente, r.valor_total
  HAVING calcular_valor_pendiente(r.valor_total, SUM(p.monto)) <= 0
) pagadas ON pagadas.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nombre_completo
ORDER BY reservas_pagadas DESC
LIMIT 3;

#///////////////////////////////////////////////////////////////////////////////