# Sistema de Reservas de Salones de Eventos

## Descripción
Base de datos en MySQL para Eventos Premier S.A.S., empresa de alquiler de
salones. Gestiona salones, clientes, reservas y pagos, calcula valores
automáticamente (con IVA del 19%), evita cruces de horario y audita los
cambios de precio.

## Instrucciones de ejecución
Requisitos: MySQL Server 8.0 y MySQL Workbench 8.0 CE.
Ejecutar los scripts en este orden:
1. `01_creacion_tablas_.sql`
2. `02_funciones.sql`
3. `03_triggers.sql`
4. `04_datos_de_pruebas.sql`
5. `05_vistas_y_consultas_proyecto_.sql`

## Ejemplos
**Función**
```sql
SELECT calcular_total_reserva(100000, 3);  -- 357000.00
SELECT verificar_disponibilidad(1, '2026-10-26 10:00', '2026-10-26 12:00');
```
**Trigger**:

Al registrar una reserva sin indicar horas ni valor, el trigger
`calcular_valores_reserva_trigger` calcula `total_horas` y `valor_total`
(con IVA del 19%), y `actualizar_estado_salon_trigger` cambia el estado del
salón a "Ocupado".

```sql
-- El Salón Jardín (id 4) está 'Disponible' y cuesta 150.000 por hora
INSERT INTO reservas (id_cliente, id_salon, fecha_inicio, fecha_fin)
VALUES (1, 4, '2026-12-01 10:00:00', '2026-12-01 13:00:00');

SELECT total_horas, valor_total FROM reservas ORDER BY id_reserva DESC LIMIT 1;
-- Resultado: 3.00 y 535500.00  (150000 x 3 horas x 1.19)

SELECT nombre, estado FROM salones WHERE id_salon = 4;
-- Resultado: Ocupado
```

Si se intenta reservar un salón en un horario que se cruza con otra reserva,
el trigger cancela el INSERT con el error: "El salón no está disponible en el
rango solicitado".

Al eliminar la reserva, `liberar_salon_trigger` devuelve el salón a "Disponible":

```sql
DELETE FROM reservas WHERE id_salon = 4 AND fecha_inicio = '2026-12-01 10:00:00';
SELECT nombre, estado FROM salones WHERE id_salon = 4;
-- Resultado: Disponible
```

Cuando se cambia el precio por hora de un salón, `auditoria_precios_trigger`
guarda el cambio en la tabla `auditoria_precios`:

```sql
UPDATE salones SET precio_hora = 160000 WHERE id_salon = 4;
SELECT * FROM auditoria_precios;
-- Muestra: usuario, fecha, precio anterior (150000) y precio nuevo (160000)
```
**Consulta**: #Consulta 3: clientes corporativos con más de 3 reservas////////////////////////

SELECT c.id_cliente, c.nombre_completo, COUNT(r.id_reserva) AS total_reservas
FROM clientes c
JOIN reservas r ON r.id_cliente = c.id_cliente
WHERE c.tipo_cliente = 'Corporativo'
GROUP BY c.id_cliente, c.nombre_completo
HAVING COUNT(r.id_reserva) > 3;

## Créditos y autor
- Sergio Andrés Restrepo Santos
- Manuel Esteban Gonzalez Abril
- Proyecto académico, MySQL 2.
