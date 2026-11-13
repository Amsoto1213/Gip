# CUS-17 Leer código de producto

Diagrama de secuencia exportado de EA (3.3.17 CUS-17 Leer código de producto).

## Participantes

- `Empleado` (Actor)
- `Lector2D` (Sequence)
- `Cámara del celular` (Sequence)
- `VistaBusquedaProducto` (Sequence)
- `coordinador` : `BuscarProductoCoordinator`
- `servicioCatalogo` : `ServicioCatalogo`
- `interprete` : `InterpreteCodigo`
- `productos` : `IProductoRepositorio`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- **[alt Dispositivo de lectura | lector de hardware]**
  - _Nota: En modo teclado el lector solo entrega texto, igual que la cámara: la Business Layer no conoce el dispositivo (Protected Variations, DA-47)._
  - 1. `Empleado` → `Lector2D`: escanear(codigo)
  - 2. `Lector2D` → `VistaBusquedaProducto`: lectura(texto)
- **[alt Dispositivo de lectura | cámara del celular, app Android]**
  - 3. `Empleado` → `VistaBusquedaProducto`: abrirCamara()
  - 4. `VistaBusquedaProducto` → `Cámara del celular`: escanear()
  - 5. `Cámara del celular` → `VistaBusquedaProducto`: lectura(texto)
- **[alt Lectura fallida | lector desconectado, permiso denegado o código ilegible]**
  - 6. `VistaBusquedaProducto` → `Empleado`: mostrar(mensaje)
  - **ref** CUS-06 Buscar producto (búsqueda por nombre) — Tras la lectura fallida, el Empleado continúa con la búsqueda por nombre del producto.
- 7. `VistaBusquedaProducto` → `coordinador`: buscarPorLectura(tienda, lectura)
- 8. `coordinador` → `servicioCatalogo`: buscarPorLectura(tienda, lectura)
- **[loop Intérpretes | por cada intérprete, en orden, hasta que uno reconozca la lectura]**
  - 9. `servicioCatalogo` → `interprete`: reconoce(lectura)
  - 10. `interprete` → `servicioCatalogo`: reconoce
- _Nota: Polymorphism: InterpreteCodigoBarras va primero (EAN-13, EAN-8 o UPC-A con dígito de control válido) e InterpreteCodigoQR de último, porque reconoce cualquier otro texto. Un formato nuevo es una clase nueva (OCP)._
- 11. `servicioCatalogo` → `interprete`: buscar(tienda, lectura)
- 12. `interprete` → `productos`: buscarPorCodigoProducto(tienda, lectura)
- 13. `productos` → `interprete`: producto
- _Nota: Compara el texto exacto de la lectura con los códigos (de barras o QR) asociados a los productos (DA-41). No usa buscarPorCodigo, que es el código interno y solo valida duplicados al crear._
- 14. `interprete` → `servicioCatalogo`: producto
- 15. `servicioCatalogo` → `coordinador`: producto
- 16. `coordinador` → `VistaBusquedaProducto`: producto
- _Nota: producto o null. El resultado vuelve a CUS-06: si es un producto, sigue el flujo que invocó la búsqueda; si es null, se ofrece crearlo (CUS-18)._
