CREATE DATABASE IF NOT EXISTS eventos_premier;
USE eventos_premier;

CREATE TABLE encargados (
  id_encargado INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL
);

CREATE TABLE salones (
  id_salon INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  capacidad INT NOT NULL CHECK (capacidad > 0),
  precio_hora DECIMAL(10,2) NOT NULL CHECK (precio_hora > 0),
  estado ENUM('Disponible','Ocupado','En mantenimiento') NOT NULL DEFAULT 'Disponible',
  id_encargado INT NOT NULL,
  FOREIGN KEY (id_encargado) REFERENCES encargados(id_encargado)
);

CREATE TABLE clientes (
  id_cliente INT AUTO_INCREMENT PRIMARY KEY,
  nombre_completo VARCHAR(150) NOT NULL,
  identificacion VARCHAR(20) NOT NULL UNIQUE,
  telefono VARCHAR(20) NOT NULL,
  correo VARCHAR(100) NOT NULL UNIQUE,
  tipo_cliente ENUM('Individual','Corporativo') NOT NULL
);

CREATE TABLE reservas (
  id_reserva INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente INT NOT NULL,
  id_salon INT NOT NULL,
  fecha_inicio DATETIME NOT NULL,
  fecha_fin DATETIME NOT NULL,
  total_horas DECIMAL(5,2),
  valor_total DECIMAL(12,2),
  estado ENUM('Confirmada','Cancelada','Finalizada') NOT NULL DEFAULT 'Confirmada',
  FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
  FOREIGN KEY (id_salon) REFERENCES salones(id_salon),
  CHECK (fecha_fin > fecha_inicio)
);

CREATE TABLE pagos (
  id_pago INT AUTO_INCREMENT PRIMARY KEY,
  id_reserva INT NOT NULL,
  fecha_pago DATE NOT NULL,
  monto DECIMAL(12,2) NOT NULL CHECK (monto > 0),
  metodo_pago ENUM('Efectivo','Tarjeta','Transferencia') NOT NULL,
  FOREIGN KEY (id_reserva) REFERENCES reservas(id_reserva)
);

CREATE TABLE auditoria_precios (
  id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
  id_salon INT NOT NULL,
  usuario VARCHAR(100) NOT NULL,
  fecha_cambio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  precio_anterior DECIMAL(10,2) NOT NULL,
  precio_nuevo DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (id_salon) REFERENCES salones(id_salon)
);