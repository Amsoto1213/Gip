# CUS-13 Registrar venta perdida

Diagrama de secuencia exportado de EA (3.3.13 CUS-13 Registrar venta perdida).

## Participantes

- `Empleado` (Actor)
- `VistaVenta` (Sequence)
- `coordinador` : `RegistrarVentaPerdidaCoordinator`
- `servicioAlertas` : `ServicioAlertas`
- `ventasPerdidas` : `IVentaPerdidaRepositorio`
- `ventaPerdida` : `VentaPerdida`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- **ref** CUS-02 Registrar venta: agregarLinea sin existencia — La venta rechaza el producto porque no hay existencia (hayStock = false, RN-01) y el cliente se va sin él. Resultado: producto : Producto.
- 1. `Empleado` → `VistaVenta`: registrarVentaPerdida()
- 2. `VistaVenta` → `coordinador`: registrarVentaPerdida(tienda, producto)
- 3. `coordinador` → `servicioAlertas`: registrarVentaPerdida(tienda, producto)
- 4. `servicioAlertas` → `ventaPerdida`: VentaPerdida(id, producto, ahora)
- _Nota: Solo se agrega, nunca se modifica: el número de ventas perdidas se obtiene contando registros, así dos dispositivos sin conexión no se pisan (DA-48, DA-50)._
- 5. `servicioAlertas` → `ventasPerdidas`: guardar(tienda, ventaPerdida)
- 6. `servicioAlertas` → `coordinador`: ventaPerdida
- 7. `coordinador` → `VistaVenta`: ventaPerdida
- 8. `VistaVenta` → `Empleado`: mostrar("Venta perdida registrada")
- _Nota: El caso vuelve a CUS-02. Las ventas perdidas se suman al consumo en el cálculo de alertas (CUS-24) y se consultan en el panel de CUS-05 (RF-12)._
