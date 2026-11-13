# CUS-04 Registrar conteo físico

Diagrama de secuencia exportado de EA (3.3.4 CUS-04 Registrar conteo físico).

## Participantes

- `Empleado` (Actor)
- `VistaConteo` (Sequence)
- `coordinador` : `RegistrarConteoCoordinator`
- `servicioInventario` : `ServicioInventario`
- `items` : `IInventarioRepositorio`
- `item` : `ItemInventario`
- `ajuste` : `AjusteConteo`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- 1. `Empleado` → `VistaConteo`: abrirConteo()
- 2. `VistaConteo` → `coordinador`: listarExistencias(tienda)
- 3. `coordinador` → `servicioInventario`: listarExistencias(tienda)
- 4. `servicioInventario` → `items`: listarItems(tienda)
- 5. `items` → `servicioInventario`: items
- 6. `servicioInventario` → `coordinador`: items
- 7. `coordinador` → `VistaConteo`: items
- _Nota: Cada ítem trae su producto (item.getProducto()); la pantalla muestra cada producto con un campo para la cantidad contada (IE-04)._
- 8. `VistaConteo` → `Empleado`: mostrar(items)
- **[loop Conteo | por cada producto contado]**
  - **ref** CUS-06 Buscar producto — Ubica el producto en la lista. Resultado: producto : Producto.
  - 9. `Empleado` → `VistaConteo`: ingresarCantidadContada(producto, cantidadContada)
  - 10. `VistaConteo` → `coordinador`: calcularDiferencia(tienda, producto, cantidadContada)
  - 11. `coordinador` → `servicioInventario`: calcularDiferencia(tienda, producto, cantidadContada)
  - 12. `servicioInventario` → `servicioInventario`: obtenerItem(tienda, producto)
  - 13. `servicioInventario` → `items`: buscarItem(tienda, producto)
  - 14. `items` → `servicioInventario`: item
  - 15. `servicioInventario` → `item`: getStockActual()
  - 16. `item` → `servicioInventario`: stockActual
  - _Nota: diferencia = cantidadContada - stockActual (IE-04)_
  - 17. `servicioInventario` → `coordinador`: diferencia
  - 18. `coordinador` → `VistaConteo`: diferencia
  - 19. `VistaConteo` → `coordinador`: requiereRevision(diferencia)
  - _Nota: Verdadero si |diferencia| supera umbralRevisionConteo, configurable (IE-04 b)._
  - 20. `coordinador` → `servicioInventario`: requiereRevision(diferencia)
  - 21. `servicioInventario` → `coordinador`: revisar
  - 22. `coordinador` → `VistaConteo`: revisar
  - 23. `VistaConteo` → `Empleado`: mostrar("Diferencia: " + diferencia)
  - **[opt Revisión | revisar = true]**
    - 24. `VistaConteo` → `Empleado`: mostrar("La diferencia supera el umbral. Revise el conteo antes de confirmar")
    - _Nota: El Empleado puede volver a contar y corregir la cantidad (vuelve a ingresarCantidadContada) o confirmar el ajuste._
  - 25. `Empleado` → `VistaConteo`: confirmar()
  - 26. `VistaConteo` → `coordinador`: confirmarAjuste(tienda, producto, cantidadContada)
  - 27. `coordinador` → `servicioInventario`: registrarConteo(tienda, producto, cantidadContada)
  - **[break Cantidad no válida | cantidadContada < 0 (IE-04 b)]**
    - 28. `servicioInventario` → `coordinador`: error("Cantidad no válida")
    - 29. `coordinador` → `VistaConteo`: error("Cantidad no válida")
    - _Nota: Obtiene el ítem con obtenerItem y devuelve cantidadContada - item.getStockActual(), como en el cálculo previo._
    - 30. `VistaConteo` → `Empleado`: mostrar("La cantidad contada no puede ser negativa")
  - 31. `servicioInventario` → `servicioInventario`: calcularDiferencia(tienda, producto, cantidadContada)
  - 32. `servicioInventario` → `ajuste`: AjusteConteo(id, item, diferencia, fecha, cantidadContada)
  - _Nota: Detalle en CUS-01: dentro de unidadTrabajo.ejecutar, stock nuevo = stock actual + diferencia = cantidadContada (prevalece lo contado, RF-04); guarda el movimiento y el ítem en una sola transacción (RNF-04)._
  - 33. `servicioInventario` → `servicioInventario`: aplicarMovimiento(tienda, ajuste)
  - **[alt Resultado | ajuste guardado]**
    - 34. `servicioInventario` → `coordinador`: ajuste
    - 35. `coordinador` → `VistaConteo`: ajuste
    - 36. `VistaConteo` → `Empleado`: mostrar("Ajuste registrado. Nuevo stock: " + cantidadContada)
  - **[alt Resultado | error al guardar (rollback: no se guarda nada)]**
    - 37. `servicioInventario` → `coordinador`: error
    - 38. `coordinador` → `VistaConteo`: error
    - 39. `VistaConteo` → `Empleado`: mostrar("No se pudo registrar el ajuste. Intente de nuevo")
