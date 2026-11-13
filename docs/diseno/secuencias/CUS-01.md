# CUS-01 Registrar entrada de mercancía

Diagrama de secuencia exportado de EA (3.3.1 CUS-01 Registrar entrada de mercancía).

## Participantes

- `Empleado` (Actor)
- `VistaEntradaMercancia` (Sequence)
- `coordinador` : `RegistrarEntradaMercanciaCoordinator`
- `servicioInventario` : `ServicioInventario`
- `unidadTrabajo` : `IUnidadTrabajo`
- `items` : `IInventarioRepositorio`
- `movimientos` : `IMovimientoInventarioRepositorio`
- `entrada` : `EntradaMercancia`
- `item` : `ItemInventario`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- **ref** CUS-06 Buscar producto — Resultado: producto : Producto. Si no existe, se crea en la extensión CUS-18 Gestionar producto.
- 1. `Empleado` → `VistaEntradaMercancia`: ingresarDatos(cantidad, costoUnitario, numeroFactura)
- 2. `VistaEntradaMercancia` → `coordinador`: verificarCosto(tienda, producto, costoUnitario)
- 3. `coordinador` → `servicioInventario`: costoDifiereDelHistorico(tienda, producto, costoUnitario)
- 4. `servicioInventario` → `servicioInventario`: obtenerItem(tienda, producto)
- 5. `servicioInventario` → `items`: buscarItem(tienda, producto)
- 6. `items` → `servicioInventario`: item
- _Nota: Si el producto no tiene ítem, obtenerItem rechaza la operación (el ItemInventario lo crea ServicioCatalogo al crear el producto)._
- 7. `servicioInventario` → `movimientos`: buscarUltimaEntrada(item)
- 8. `movimientos` → `servicioInventario`: ultimaEntrada
- _Nota: difiere = ultimaEntrada ≠ null y ultimaEntrada.getCostoUnitario() ≠ costoUnitario_
- 9. `servicioInventario` → `coordinador`: difiere
- 10. `coordinador` → `VistaEntradaMercancia`: difiere
- **[opt Advertencia de costo | difiere = true]**
  - 11. `VistaEntradaMercancia` → `Empleado`: mostrar("El costo es distinto al de la última entrada")
  - _Nota: Advertencia no bloqueante (IE-02): el Empleado puede corregir el costo o seguir. Si corrige, vuelve a ingresarDatos(...)._
- 12. `Empleado` → `VistaEntradaMercancia`: confirmar()
- 13. `VistaEntradaMercancia` → `coordinador`: registrarEntrada(tienda, producto, cantidad, costoUnitario, numeroFactura)
- 14. `coordinador` → `servicioInventario`: registrarEntrada(tienda, producto, cantidad, costoUnitario, numeroFactura)
- **[break Datos no válidos | cantidad <= 0 o costoUnitario < 0]**
  - 15. `servicioInventario` → `coordinador`: error("Datos no válidos")
  - 16. `coordinador` → `VistaEntradaMercancia`: error("Datos no válidos")
  - 17. `VistaEntradaMercancia` → `Empleado`: mostrar("La cantidad debe ser mayor que cero y el costo no puede ser negativo")
- 18. `servicioInventario` → `servicioInventario`: obtenerItem(tienda, producto)
- 19. `servicioInventario` → `entrada`: EntradaMercancia(id, item, cantidad, fecha, costoUnitario, numeroFactura)
- 20. `servicioInventario` → `servicioInventario`: aplicarMovimiento(tienda, entrada)
- 21. `servicioInventario` → `unidadTrabajo`: ejecutar(accion)
- 22. `unidadTrabajo` → `servicioInventario`: accion()
- 23. `servicioInventario` → `item`: getStockActual()
- 24. `item` → `servicioInventario`: stockAnterior
- 25. `servicioInventario` → `entrada`: getCantidad()
- 26. `entrada` → `servicioInventario`: cantidad
- 27. `servicioInventario` → `item`: setStockActual(stockAnterior + cantidad)
- 28. `servicioInventario` → `movimientos`: guardar(tienda, entrada)
- _Nota: Unit of Work (RNF-04): el movimiento y el nuevo stock se guardan en una sola transacción (drift), con su registro en la cola de pendientes para sincronizar (RNF-08). Si el stock quedara negativo, aplicarMovimiento bloquea la operación (ERS 3.2.1 a)._
- 29. `servicioInventario` → `items`: guardarItem(tienda, item)
- _Nota: Las entidades viajan entre capas: la Vista lee el nuevo stock con entrada.getItem().getStockActual(), como indica registrarEntrada del Coordinator._
- **[alt Resultado de la transacción | Transacción confirmada]**
  - 30. `unidadTrabajo` → `servicioInventario`: retorno
  - 31. `servicioInventario` → `coordinador`: entrada
  - 32. `coordinador` → `VistaEntradaMercancia`: entrada
  - 33. `VistaEntradaMercancia` → `entrada`: getItem()
  - 34. `entrada` → `VistaEntradaMercancia`: item
  - 35. `VistaEntradaMercancia` → `item`: getStockActual()
  - 36. `item` → `VistaEntradaMercancia`: nuevoStock
  - 37. `VistaEntradaMercancia` → `Empleado`: mostrar("Entrada registrada. Nuevo stock: " + nuevoStock)
- **[alt Resultado de la transacción | Error al guardar (rollback: no se guarda nada)]**
  - 38. `unidadTrabajo` → `servicioInventario`: error
  - 39. `servicioInventario` → `coordinador`: error
  - 40. `coordinador` → `VistaEntradaMercancia`: error
  - 41. `VistaEntradaMercancia` → `Empleado`: mostrar("No se pudo registrar la entrada. Intente de nuevo")
