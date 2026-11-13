# CUS-24 Generar alertas de reabastecimiento

Diagrama de secuencia exportado de EA (3.3.24 CUS-24 Generar alertas de reabastecimiento).

## Participantes

- `Tiempo` (Actor)
- `coordinador` : `GenerarAlertasDiariasCoordinator`
- `servicioAlertas` : `ServicioAlertas`
- `items` : `IInventarioRepositorio`
- `movimientos` : `IMovimientoInventarioRepositorio`
- `ventasPerdidas` : `IVentaPerdidaRepositorio`
- `estrategiaConsumo` : `EstrategiaConsumo`
- `item` : `ItemInventario`
- `alerta` : `AlertaReabastecimiento`
- `alertas` : `IAlertaRepositorio`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- _Nota: Lo dispara un temporizador o la primera apertura del día, después de sincronizar (CUS-23)._
- 1. `Tiempo` → `coordinador`: ejecutar(tienda, fecha)
- 2. `coordinador` → `servicioAlertas`: generarAlertas(tienda, fecha)
- 3. `servicioAlertas` → `items`: listarItems(tienda)
- 4. `items` → `servicioAlertas`: items
- **[loop Evaluación | por cada ítem de la tienda]**
  - 5. `servicioAlertas` → `servicioAlertas`: evaluarItem(item, fecha)
  - 6. `servicioAlertas` → `movimientos`: listarSalidas(item, fecha - 30 días, fecha)
  - 7. `movimientos` → `servicioAlertas`: salidas
  - 8. `servicioAlertas` → `item`: getProducto()
  - 9. `item` → `servicioAlertas`: producto
  - _Nota: Las ventas perdidas (CUS-13) cuentan como demanda aunque no se vendieron (RF-12)._
  - 10. `servicioAlertas` → `ventasPerdidas`: listarPorProducto(producto, fecha - 30 días, fecha)
  - 11. `ventasPerdidas` → `servicioAlertas`: perdidas
  - _Nota: Strategy: ConsumoPromedioSimple suma las unidades vendidas más una por cada venta perdida y divide entre los días con datos, sin contar los días sin sincronizar (ERS 3.2.2 c). Otra forma de estimar es otra clase (OCP)._
  - 12. `servicioAlertas` → `estrategiaConsumo`: calcularConsumoDiario(salidas, perdidas, dias)
  - 13. `estrategiaConsumo` → `servicioAlertas`: consumo
  - 14. `servicioAlertas` → `item`: getStockActual()
  - 15. `item` → `servicioAlertas`: stock
  - **[opt Alerta | consumo > 0 y stock / consumo < umbralDiasCobertura]**
    - _Nota: diasCobertura = stock / consumo. Provisional si hay menos de 30 días de historial (RNF-03); guarda la existencia del momento (RNF-02)._
    - 16. `servicioAlertas` → `alerta`: AlertaReabastecimiento(id, item, fecha, stock, consumo, diasCobertura, provisional)
    - _Nota: Si el consumo es cero no se genera alerta: evita la división por cero (RF-05)._
- 17. `servicioAlertas` → `alertas`: reemplazar(tienda, fecha, alertas)
- _Nota: Guarda las alertas del día y descarta las anteriores de esa fecha: si varios dispositivos lo ejecutan, no se duplican (RD-11, DA-35)._
- 18. `servicioAlertas` → `coordinador`: retorno
- 19. `coordinador` → `Tiempo`: retorno
- _Nota: El Propietario consulta las alertas ya calculadas en CUS-05._
