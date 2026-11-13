# CUS-09 Consultar margen de ganancia

Diagrama de secuencia exportado de EA (3.3.9 CUS-09 Consultar margen de ganancia).

## Participantes

- `Propietario` (Actor)
- `VistaMargen` (Sequence)
- `coordinador` : `ConsultarMargenCoordinator`
- `servicioAcceso` : `ServicioAcceso`
- `servicioReportes` : `ServicioReportes`
- `movimientos` : `IMovimientoInventarioRepositorio`
- `salida` : `SalidaVenta`
- `item` : `ItemInventario`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- _Nota: Control de acceso por rol detallado en CUS-05: si el usuario no es propietario, se rechaza (RNF-12)._
- 1. `Propietario` → `VistaMargen`: consultarMargen(desde, hasta)
- 2. `VistaMargen` → `coordinador`: consultarMargen(tienda, desde, hasta, usuario)
- 3. `coordinador` → `servicioAcceso`: exigirPropietario(usuario)
- 4. `servicioAcceso` → `coordinador`: retorno
- 5. `coordinador` → `servicioReportes`: calcularMargenes(tienda, desde, hasta)
- 6. `servicioReportes` → `movimientos`: listarSalidasPorTienda(tienda, desde, hasta)
- _Nota: Solo salidas VIGENTES: las de ventas anuladas no cuentan. Cada una trae su ítem, su producto y el precio y el costo con que se vendió (DA-61)._
- 7. `movimientos` → `servicioReportes`: salidas
- **[loop Margen por producto | por cada salida del periodo]**
  - 8. `servicioReportes` → `salida`: getItem()
  - 9. `salida` → `servicioReportes`: item
  - 10. `servicioReportes` → `item`: getProducto()
  - 11. `item` → `servicioReportes`: producto
  - 12. `servicioReportes` → `salida`: calcularMargen()
  - 13. `salida` → `servicioReportes`: margen
  - _Nota: Information Expert: (precioUnitario - costoUnitario) x calcularUnidades(); null si la salida no tiene costo._
- _Nota: Suma el margen de cada salida en su producto. Si alguna salida del producto devuelve null, el margen del producto queda null: dato incompleto (ERS 3.2.4, DA-72)._
- 14. `servicioReportes` → `coordinador`: margenes
- 15. `coordinador` → `VistaMargen`: margenes
- 16. `VistaMargen` → `Propietario`: mostrar(margenes)
- _Nota: margenes : Map. Un margen null se muestra como "dato incompleto": falta el costo de compra del producto._
