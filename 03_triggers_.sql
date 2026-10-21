
#este trigger fue creado para actualizar el estado del salón
DELIMITER $$

CREATE TRIGGER actualizar_estado_salon_trigger
AFTER INSERT ON reservas
FOR EACH ROW
BEGIN
  UPDATE salones SET estado = 'Ocupado' WHERE id_salon = NEW.id_salon;
END$$

DELIMITER ;

#Este fue creado para liberar el salón
DELIMITER $$

CREATE TRIGGER liberar_salon_trigger
AFTER DELETE ON reservas
FOR EACH ROW
BEGIN
  UPDATE salones SET estado = 'Disponible' WHERE id_salon = OLD.id_salon;
END$$

DELIMITER ;

# Este es para la auditoría de precios
DELIMITER $$

CREATE TRIGGER auditoria_precios_trigger
AFTER UPDATE ON salones
FOR EACH ROW
BEGIN
  IF OLD.precio_hora <> NEW.precio_hora THEN
    INSERT INTO auditoria_precios (id_salon, usuario, precio_anterior, precio_nuevo)
    VALUES (NEW.id_salon, CURRENT_USER(), OLD.precio_hora, NEW.precio_hora);
  END IF;
END$$

DELIMITER ;

# cálculo automático + estado ocupado
DELIMITER $$

CREATE TRIGGER calcular_valores_reserva_trigger
BEFORE INSERT ON reservas
FOR EACH ROW
BEGIN
  DECLARE v_precio DECIMAL(10,2);

  IF verificar_disponibilidad(NEW.id_salon, NEW.fecha_inicio, NEW.fecha_fin) = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'El salón no está disponible en el rango solicitado';
  END IF;

  SELECT precio_hora INTO v_precio FROM salones WHERE id_salon = NEW.id_salon;

  SET NEW.total_horas = TIMESTAMPDIFF(MINUTE, NEW.fecha_inicio, NEW.fecha_fin) / 60;
  SET NEW.valor_total = calcular_total_reserva(v_precio, NEW.total_horas);
END$$

DELIMITER ;