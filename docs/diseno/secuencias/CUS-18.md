# CUS-18 Gestionar producto

Diagrama de secuencia exportado de EA (3.3.18 CUS-18 Gestionar producto).

## Participantes

- `Empleado` (Actor)
- `VistaProducto` (Sequence)
- `coordinador` : `GestionarProductoCoordinator`
- `servicioCatalogo` : `ServicioCatalogo`
- `servicioInventario` : `ServicioInventario`
- `unidadTrabajo` : `IUnidadTrabajo`
- `productos` : `IProductoRepositorio`
- `interprete` : `InterpreteCodigo`
- `impresion` : `IImpresionEtiquetas`
- `producto` : `Producto`
- `codigo` : `CodigoProducto`
- `etiqueta` : `Etiqueta`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- **ref** CUS-06 Buscar producto — Punto de extensión: no hay coincidencias o el código leído no está registrado.
- 1. `Empleado` → `VistaProducto`: ingresarProducto(codigo, nombre, unidad, precioCompra, precioVenta)
- 2. `VistaProducto` → `coordinador`: crearProducto(tienda, codigo, nombre, unidad, precioCompra, precioVenta)
- 3. `coordinador` → `servicioCatalogo`: crearProducto(tienda, codigo, nombre, unidad, precioCompra, precioVenta)
- 4. `servicioCatalogo` → `productos`: buscarPorCodigo(tienda, codigo)
- 5. `productos` → `servicioCatalogo`: existente
- **[break Datos no válidos | existente != null, nombre vacío o algún precio negativo]**
  - 6. `servicioCatalogo` → `coordinador`: error("Datos no válidos")
  - 7. `coordinador` → `VistaProducto`: error("Datos no válidos")
  - 8. `VistaProducto` → `Empleado`: mostrar("El código interno ya existe o faltan datos válidos")
- 9. `servicioCatalogo` → `producto`: Producto(id, codigo, nombre, unidad, precioCompra, precioVenta)
- _Nota: precioCompra puede quedar nulo: el margen de ese producto quedará como dato incompleto (CUS-09)._
- 10. `servicioCatalogo` → `unidadTrabajo`: ejecutar(accion)
- 11. `unidadTrabajo` → `servicioCatalogo`: accion()
- 12. `servicioCatalogo` → `productos`: guardar(tienda, producto)
- _Nota: Creator: crea el ItemInventario del producto con stock cero y lo guarda con items.guardarItem, dentro de la misma transacción (RNF-04)._
- 13. `servicioCatalogo` → `servicioInventario`: crearItem(tienda, producto)
- 14. `unidadTrabajo` → `servicioCatalogo`: retorno
- 15. `servicioCatalogo` → `coordinador`: producto
- 16. `coordinador` → `VistaProducto`: producto
- 17. `VistaProducto` → `Empleado`: mostrar("Producto creado")
- **[opt Asociar código | el producto viene de una lectura o se le agrega un código]**
  - 18. `Empleado` → `VistaProducto`: asociarCodigo(valor)
  - 19. `VistaProducto` → `coordinador`: asociarCodigo(tienda, producto, valor)
  - 20. `coordinador` → `servicioCatalogo`: asociarCodigo(tienda, producto, valor)
  - 21. `servicioCatalogo` → `productos`: buscarPorCodigoProducto(tienda, valor)
  - 22. `productos` → `servicioCatalogo`: otro
  - **[break Código repetido | otro != null y otro es un producto distinto]**
    - 23. `servicioCatalogo` → `coordinador`: error("Código repetido")
    - 24. `coordinador` → `VistaProducto`: error("Código repetido")
    - 25. `VistaProducto` → `Empleado`: mostrar("Ese código ya está asociado a otro producto")
  - 26. `servicioCatalogo` → `interprete`: formatoDe(valor)
  - _Nota: Lo responde el primer intérprete que reconoce el valor; el recorrido se detalla en CUS-17._
  - 27. `interprete` → `servicioCatalogo`: formato
  - 28. `servicioCatalogo` → `codigo`: CodigoProducto(id, formato, valor)
  - 29. `servicioCatalogo` → `producto`: agregarCodigo(codigo)
  - 30. `servicioCatalogo` → `productos`: guardar(tienda, producto)
  - 31. `servicioCatalogo` → `coordinador`: codigo
  - 32. `coordinador` → `VistaProducto`: codigo
  - 33. `VistaProducto` → `Empleado`: mostrar("Código asociado")
- **[opt Editar | el Empleado edita un producto existente]**
  - _Nota: Valida nombre y precios igual que crearProducto (si no, rechaza); cambia los datos con setNombre, setUnidadMedida, setPrecioCompra y setPrecioVenta y asigna setActualizadoEn(ahora). El código interno no se edita (DA-48, DA-50)._
  - 34. `Empleado` → `VistaProducto`: editarProducto(nombre, unidad, precioCompra, precioVenta)
  - 35. `VistaProducto` → `coordinador`: editarProducto(tienda, producto, nombre, unidad, precioCompra, precioVenta)
  - 36. `coordinador` → `servicioCatalogo`: editarProducto(tienda, producto, nombre, unidad, precioCompra, precioVenta)
  - 37. `servicioCatalogo` → `productos`: guardar(tienda, producto)
  - 38. `servicioCatalogo` → `coordinador`: retorno
  - 39. `coordinador` → `VistaProducto`: retorno
  - 40. `VistaProducto` → `Empleado`: mostrar("Producto actualizado")
- **[opt Etiquetas | el Empleado imprime etiquetas]**
  - 41. `Empleado` → `VistaProducto`: imprimirEtiquetas(productos, copias)
  - 42. `VistaProducto` → `coordinador`: imprimirEtiquetas(tienda, productos, copias)
  - 43. `coordinador` → `servicioCatalogo`: imprimirEtiquetas(tienda, productos, copias)
  - 44. `servicioCatalogo` → `servicioCatalogo`: generarEtiquetas(tienda, productos, copias)
  - **[loop Por producto | por cada producto]**
    - **[opt Sin códigos | el producto no tiene códigos]**
      - 45. `servicioCatalogo` → `codigo`: CodigoProducto(id, QR, "GIP:" + producto.getCodigo())
      - _Nota: El producto se guarda con productos.guardar dentro de unidadTrabajo.ejecutar (DA-41, RNF-04)._
      - 46. `servicioCatalogo` → `producto`: agregarCodigo(codigo)
    - 47. `servicioCatalogo` → `etiqueta`: Etiqueta(producto, codigo)
    - _Nota: Una por copia; no se guarda (DA-40)._
  - 48. `servicioCatalogo` → `impresion`: imprimir(etiquetas)
  - _Nota: Protected Variations: la Data Layer arma el PDF en hojas adhesivas tamaño carta y abre la impresión; no requiere hardware especial (DA-39)._
  - 49. `servicioCatalogo` → `coordinador`: retorno
  - 50. `coordinador` → `VistaProducto`: retorno
  - 51. `VistaProducto` → `Empleado`: mostrar("Etiquetas enviadas a impresión")
