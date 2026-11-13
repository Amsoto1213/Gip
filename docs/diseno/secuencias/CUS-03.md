# CUS-03 Registrar pérdida o devolución al proveedor

Diagrama de secuencia exportado de EA (3.3.3 CUS-03 Registrar pérdida o devolución al proveedor).

## Participantes

- `Empleado` (Actor)
- `VistaPerdida` (Sequence)
- `coordinador` : `RegistrarPerdidaCoordinator`
- `servicioInventario` : `ServicioInventario`
- `items` : `IInventarioRepositorio`
- `merma` : `Merma`
- `item` : `ItemInventario`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- **ref** CUS-06 Buscar producto — Resultado: producto : Producto (por nombre o con el lector de códigos).
- _Nota: motivo : MotivoMerma se elige de una lista cerrada (VENCIDO, DANADO, DEVUELTO_PROVEEDOR, OTRO); la pantalla no deja continuar sin motivo (IE-03)._
- 1. `Empleado` → `VistaPerdida`: ingresarDatos(cantidad, motivo)
- 2. `Empleado` → `VistaPerdida`: confirmar()
- 3. `VistaPerdida` → `coordinador`: registrarPerdida(tienda, producto, cantidad, motivo)
- 4. `coordinador` → `servicioInventario`: registrarMerma(tienda, producto, cantidad, motivo)
- **[break Datos no válidos | cantidad <= 0 o motivo sin elegir]**
  - 5. `servicioInventario` → `coordinador`: error("Datos no válidos")
  - 6. `coordinador` → `VistaPerdida`: error("Datos no válidos")
  - 7. `VistaPerdida` → `Empleado`: mostrar("La cantidad debe ser mayor que cero y el motivo es obligatorio")
- 8. `servicioInventario` → `servicioInventario`: obtenerItem(tienda, producto)
- 9. `servicioInventario` → `items`: buscarItem(tienda, producto)
- 10. `items` → `servicioInventario`: item
- _Nota: Si el producto no tiene ítem, obtenerItem rechaza la operación (el ItemInventario lo crea ServicioCatalogo al crear el producto)._
- 11. `servicioInventario` → `merma`: Merma(id, item, -cantidad, fecha, motivo)
- _Nota: Detalle en CUS-01: en una sola transacción calcula stock nuevo = stock anterior + cantidad (la merma la guarda en negativo, DA-19), lo bloquea si queda negativo (ERS 3.2.1 a) y guarda el movimiento y el ítem (RNF-04)._
- 12. `servicioInventario` → `servicioInventario`: aplicarMovimiento(tienda, merma)
- **[alt Resultado de la transacción | transacción confirmada]**
  - 13. `servicioInventario` → `coordinador`: merma
  - 14. `coordinador` → `VistaPerdida`: merma
  - 15. `VistaPerdida` → `merma`: getItem()
  - 16. `merma` → `VistaPerdida`: item
  - 17. `VistaPerdida` → `item`: getStockActual()
  - 18. `item` → `VistaPerdida`: nuevoStock
  - 19. `VistaPerdida` → `Empleado`: mostrar("Pérdida registrada. Nuevo stock: " + nuevoStock)
- **[alt Resultado de la transacción | stock negativo o error al guardar (rollback: no se guarda nada)]**
  - 20. `servicioInventario` → `coordinador`: error
  - 21. `coordinador` → `VistaPerdida`: error
  - _Nota: Por ejemplo: "La cantidad supera la existencia" o "No se pudo registrar la pérdida. Intente de nuevo"._
  - 22. `VistaPerdida` → `Empleado`: mostrar(mensajeError)
