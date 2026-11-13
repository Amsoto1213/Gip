# CUS-12 Consultar rotación de productos

Diagrama de secuencia exportado de EA (3.3.12 CUS-12 Consultar rotación de productos).

## Participantes

- `Propietario` (Actor)
- `VistaRotacion` (Sequence)
- `coordinador` : `ConsultarRotacionCoordinator`
- `servicioAcceso` : `ServicioAcceso`
- `servicioReportes` : `ServicioReportes`
- `items` : `IInventarioRepositorio`
- `movimientos` : `IMovimientoInventarioRepositorio`
- `salida` : `SalidaVenta`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- 1. `Propietario` → `VistaRotacion`: consultarRotacion(desde, hasta)
- _Nota: Control de acceso por rol detallado en CUS-05: si el usuario no es propietario, se rechaza (RNF-12)._
- 2. `VistaRotacion` → `coordinador`: consultarRotacion(tienda, desde, hasta, usuario)
- 3. `coordinador` → `servicioAcceso`: exigirPropietario(usuario)
- 4. `servicioAcceso` → `coordinador`: retorno
- 5. `coordinador` → `servicioReportes`: clasificarRotacion(tienda, desde, hasta)
- 6. `servicioReportes` → `items`: listarItems(tienda)
- 7. `items` → `servicioReportes`: items
- _Nota: Todos los productos de la tienda empiezan con cero unidades, para que también aparezcan los que no se vendieron._
- 8. `servicioReportes` → `movimientos`: listarSalidasPorTienda(tienda, desde, hasta)
- 9. `movimientos` → `servicioReportes`: salidas
- _Nota: Solo salidas VIGENTES: las de ventas anuladas no cuentan._
- **[loop Unidades por producto | por cada salida del periodo]**
  - 10. `servicioReportes` → `salida`: calcularUnidades()
  - 11. `salida` → `servicioReportes`: unidades
  - _Nota: Information Expert: |getCantidad()|, porque la salida guarda la cantidad en negativo (DA-72). Las unidades se suman en el producto de salida.getItem().getProducto(), como en CUS-09._
- _Nota: Ordena los productos de mayor a menor: el tercio que más vende es ALTA, el del medio MEDIA y el resto BAJA; los que no vendieron quedan en BAJA (RF-11, DA-62)._
- 12. `servicioReportes` → `coordinador`: rotacion
- 13. `coordinador` → `VistaRotacion`: rotacion
- 14. `VistaRotacion` → `Propietario`: mostrar(rotacion)
- _Nota: rotacion : Map. No se guarda: se calcula en cada consulta (DA-40)._
