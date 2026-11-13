# CUS-06 Buscar producto

Diagrama de secuencia exportado de EA (3.3.6 CUS-06 Buscar producto).

## Participantes

- `Empleado` (Actor)
- `VistaBusquedaProducto` (Sequence)
- `coordinador` : `BuscarProductoCoordinator`
- `servicioCatalogo` : `ServicioCatalogo`
- `productos` : `IProductoRepositorio`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- **[alt Forma de búsqueda | el Empleado busca por nombre]**
  - **[loop Filtro en tiempo real | por cada cambio en el texto de búsqueda]**
    - 1. `Empleado` → `VistaBusquedaProducto`: escribirTexto(texto)
    - 2. `VistaBusquedaProducto` → `coordinador`: buscarPorNombre(tienda, texto)
    - 3. `coordinador` → `servicioCatalogo`: buscarPorNombre(tienda, texto)
    - 4. `servicioCatalogo` → `productos`: buscarPorNombre(tienda, texto)
    - 5. `productos` → `servicioCatalogo`: productos
    - _Nota: Coincidencia parcial sobre el nombre normalizado, sin mayúsculas ni tildes (RD-08); 1 s o menos con 2.000 productos. Opera sobre la base local si no hay conexión (RNF-08)._
    - 6. `servicioCatalogo` → `coordinador`: productos
    - 7. `coordinador` → `VistaBusquedaProducto`: productos
    - 8. `VistaBusquedaProducto` → `Empleado`: mostrar(productos)
  - **[alt Resultado | hay coincidencias]**
    - _Nota: El producto seleccionado vuelve al flujo que invocó la búsqueda: entrada, venta, pérdida o conteo (CUS-01 a CUS-04)._
    - 9. `Empleado` → `VistaBusquedaProducto`: seleccionar(producto)
  - **[alt Resultado | no hay coincidencias]**
    - 10. `VistaBusquedaProducto` → `Empleado`: mostrar("No se encontró el producto. ¿Desea crearlo?")
    - **[opt Crear producto | el Empleado decide crearlo]**
      - **ref** CUS-18 Gestionar producto (extiende) — Crea el producto con GestionarProductoCoordinator.crearProducto. Resultado: producto : Producto.
- **[alt Forma de búsqueda | el Empleado lee el código con el lector]**
  - **ref** CUS-17 Leer código de producto (extiende) — Lectura con el lector 2D o la cámara; BuscarProductoCoordinator.buscarPorLectura. Resultado: producto : Producto o null.
  - _Nota: Si la lectura devuelve un producto, vuelve al flujo que invocó la búsqueda; si devuelve null, se ofrece crear el producto (CUS-18), igual que en la búsqueda por nombre._
