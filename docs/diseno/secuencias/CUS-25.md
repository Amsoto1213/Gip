# CUS-25 Consultar existencias

Diagrama de secuencia exportado de EA (3.3.25 CUS-25 Consultar existencias).

## Participantes

- `Empleado` (Actor)
- `VistaExistencias` (Sequence)
- `coordinador` : `ConsultarExistenciasCoordinator`
- `servicioInventario` : `ServicioInventario`
- `items` : `IInventarioRepositorio`
- `movimientos` : `IMovimientoInventarioRepositorio`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- 1. `Empleado` → `VistaExistencias`: abrirExistencias()
- 2. `VistaExistencias` → `coordinador`: listarExistencias(tienda)
- 3. `coordinador` → `servicioInventario`: listarExistencias(tienda)
- 4. `servicioInventario` → `items`: listarItems(tienda)
- 5. `items` → `servicioInventario`: items
- 6. `servicioInventario` → `coordinador`: items
- 7. `coordinador` → `VistaExistencias`: items
- 8. `VistaExistencias` → `Empleado`: mostrar(items)
- _Nota: Cada ítem con su producto (item.getProducto()) y su stock actual, ordenados por nombre. Funciona sin conexión sobre la base local (RNF-08)._
- **[opt Historial | el Empleado consulta los movimientos de un producto]**
  - 9. `Empleado` → `VistaExistencias`: verHistorial(producto, desde, hasta)
  - 10. `VistaExistencias` → `coordinador`: consultarMovimientos(tienda, producto, desde, hasta)
  - 11. `coordinador` → `servicioInventario`: consultarMovimientos(tienda, producto, desde, hasta)
  - 12. `servicioInventario` → `items`: buscarItem(tienda, producto)
  - 13. `items` → `servicioInventario`: item
  - 14. `servicioInventario` → `movimientos`: listarPorItem(item, desde, hasta)
  - 15. `movimientos` → `servicioInventario`: movimientos
  - _Nota: Entradas, salidas, mermas y ajustes del periodo, del más reciente al más antiguo, cada uno con su estado: VIGENTE, EN_REVISION o ANULADO (DA-50)._
  - 16. `servicioInventario` → `coordinador`: movimientos
  - 17. `coordinador` → `VistaExistencias`: movimientos
  - 18. `VistaExistencias` → `Empleado`: mostrar(movimientos)
