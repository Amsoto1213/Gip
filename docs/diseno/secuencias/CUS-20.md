# CUS-20 Anular venta

Diagrama de secuencia exportado de EA (3.3.20 CUS-20 Anular venta).

## Participantes

- `Propietario` (Actor)
- `VistaAnulacion` (Sequence)
- `coordinador` : `AnularVentaCoordinator`
- `servicioAcceso` : `ServicioAcceso`
- `servicioVentas` : `ServicioVentas`
- `servicioInventario` : `ServicioInventario`
- `procesador` : `ProcesadorPago`
- `unidadTrabajo` : `IUnidadTrabajo`
- `ventas` : `IVentaRepositorio`
- `venta` : `Venta`
- `anulacion` : `AnulacionVenta`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- 1. `Propietario` → `VistaAnulacion`: consultarVentas(desde, hasta)
- 2. `VistaAnulacion` → `coordinador`: listarVentas(tienda, desde, hasta, usuario)
- 3. `coordinador` → `servicioAcceso`: exigirPropietario(usuario)
- _Nota: Control de acceso por rol detallado en CUS-05; cada operación del coordinador lo exige (RNF-12)._
- 4. `servicioAcceso` → `coordinador`: retorno
- 5. `coordinador` → `servicioVentas`: listarVentas(tienda, desde, hasta)
- 6. `servicioVentas` → `ventas`: listarPorPeriodo(tienda, desde, hasta)
- 7. `ventas` → `servicioVentas`: ventas
- 8. `servicioVentas` → `coordinador`: ventas
- 9. `coordinador` → `VistaAnulacion`: ventas
- 10. `VistaAnulacion` → `Propietario`: mostrar(ventas)
- _Nota: Cada venta con sus formas de pago y su estado (anulada o no)._
- 11. `Propietario` → `VistaAnulacion`: anular(venta, motivo)
- 12. `VistaAnulacion` → `Propietario`: mostrar("¿Confirma la anulación de la venta?")
- 13. `Propietario` → `VistaAnulacion`: confirmar()
- 14. `VistaAnulacion` → `coordinador`: anularVenta(tienda, venta, motivo, usuario)
- 15. `coordinador` → `servicioAcceso`: exigirPropietario(usuario)
- 16. `servicioAcceso` → `coordinador`: retorno
- 17. `coordinador` → `servicioVentas`: anular(tienda, venta, motivo, usuario)
- 18. `servicioVentas` → `venta`: isAnulada()
- 19. `venta` → `servicioVentas`: anulada
- **[break Ya anulada | anulada = true]**
  - 20. `servicioVentas` → `coordinador`: error("Venta ya anulada")
  - 21. `coordinador` → `VistaAnulacion`: error("Venta ya anulada")
  - 22. `VistaAnulacion` → `Propietario`: mostrar("La venta ya estaba anulada")
- 23. `servicioVentas` → `anulacion`: AnulacionVenta(id, usuario, ahora, motivo)
- 24. `servicioVentas` → `unidadTrabajo`: ejecutar(accion)
- 25. `unidadTrabajo` → `servicioVentas`: accion()
- 26. `servicioVentas` → `venta`: anular(anulacion)
- _Nota: Information Expert: guarda la anulación; la venta no se borra ni cambia sus datos (RNF-15, DA-51)._
- 27. `servicioVentas` → `ventas`: registrarAnulacion(tienda, venta, anulacion)
- _Nota: Busca las salidas con movimientos.listarSalidasPorVenta y llama a anularMovimiento por cada una: la marca ANULADO y el stock vuelve (stock nuevo = stock actual - cantidad), en la misma transacción._
- 28. `servicioVentas` → `servicioInventario`: anularSalidas(tienda, venta)
- **[loop Revertir pagos | por cada forma en venta.getFormasPago()]**
  - _Nota: Polymorphism: ProcesadorPagoContado registra un EGRESO de clasificación ANULACION en la caja de hoy (registrarMovimiento, detalle en CUS-11); ProcesadorFiado llama a servicioFiados.anularFiado, que rechaza si el fiado ya tiene abonos; ProcesadorNequi no mueve la caja (la devolución se hace por Nequi)._
  - 29. `servicioVentas` → `servicioVentas`: procesadorPara(forma)
  - 30. `servicioVentas` → `procesador`: revertir(tienda, venta, forma)
- **[alt Resultado de la transacción | transacción confirmada]**
  - 31. `unidadTrabajo` → `servicioVentas`: retorno
  - 32. `servicioVentas` → `coordinador`: anulacion
  - 33. `coordinador` → `VistaAnulacion`: anulacion
  - 34. `VistaAnulacion` → `Propietario`: mostrar("Venta anulada")
- **[alt Resultado de la transacción | caja cerrada, fiado con abonos o error al guardar (rollback: no se guarda nada)]**
  - 35. `unidadTrabajo` → `servicioVentas`: error
  - 36. `servicioVentas` → `coordinador`: error
  - 37. `coordinador` → `VistaAnulacion`: error
  - 38. `VistaAnulacion` → `Propietario`: mostrar(mensajeError)
