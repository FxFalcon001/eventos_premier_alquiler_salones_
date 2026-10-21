
DELIMITER $$

CREATE FUNCTION calcular_total_reserva(p_precio_hora DECIMAL(10,2), p_horas DECIMAL(5,2))
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
  RETURN ROUND(p_precio_hora * p_horas * 1.19, 2);
END$$

DELIMITER ;

DELIMITER $$

CREATE FUNCTION verificar_disponibilidad(p_salon_id INT, p_fecha_inicio DATETIME, p_fecha_fin DATETIME)
RETURNS TINYINT
READS SQL DATA
BEGIN
  DECLARE v_estado VARCHAR(20);
  DECLARE v_conflictos INT;

  SELECT estado INTO v_estado FROM salones WHERE id_salon = p_salon_id;

  IF v_estado IS NULL OR v_estado = 'En mantenimiento' THEN
    RETURN 0;
  END IF;

  SELECT COUNT(*) INTO v_conflictos
  FROM reservas
  WHERE id_salon = p_salon_id
    AND estado <> 'Cancelada'
    AND fecha_inicio < p_fecha_fin
    AND fecha_fin > p_fecha_inicio;

  IF v_conflictos > 0 THEN
    RETURN 0;
  END IF;

  RETURN 1;
END$$

DELIMITER ;


