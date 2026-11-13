# CUS-23 Conciliar datos sincronizados

Diagrama de secuencia exportado de EA (3.3.23 CUS-23 Conciliar datos sincronizados).

## Participantes

- `Tiempo` (Actor)
- `Sincronizador` (Sequence)
- `coordinador` : `ConciliarCoordinator`
- `servicioConciliacion` : `ServicioConciliacion`
- `servicioInventario` : `ServicioInventario`
- `unidadTrabajo` : `IUnidadTrabajo`
- `conflictos` : `IConflictoRepositorio`
- `conflicto` : `ConflictoSincronizacion`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- 1. `Tiempo` → `Sincronizador`: sincronizar(tienda)
- 2. `Sincronizador` → `coordinador`: ejecutar(tienda, desde)
- 3. `coordinador` → `servicioConciliacion`: conciliar(tienda, desde)
- _Nota: Cuando hay conexión: sube la cola de pendientes y baja los cambios de las demás terminales (RNF-08). Al terminar, dispara la conciliación._
- 4. `servicioConciliacion` → `unidadTrabajo`: ejecutar(accion)
- 5. `unidadTrabajo` → `servicioConciliacion`: accion()
- 6. `servicioConciliacion` → `servicioConciliacion`: detectarPosiblesDuplicados(tienda, desde)
- 7. `servicioConciliacion` → `servicioConciliacion`: detectarStockNegativo(tienda, desde)
- **[loop Stock | por cada ítem con movimientos recibidos desde la fecha]**
  - 8. `servicioConciliacion` → `servicioInventario`: recalcularStock(tienda, item)
  - 9. `servicioInventario` → `servicioConciliacion`: stock
- _Nota: Suma los movimientos VIGENTES de todo el historial del ítem y guarda el resultado: el stock no se sincroniza como número, se recalcula (ERS 3.2.1 c, DA-48)._
- 10. `servicioConciliacion` → `servicioConciliacion`: detectarAbonosExcedidos(tienda, desde)
- _Nota: Choques que debe decidir el Propietario: dos entradas iguales (POSIBLE_DUPLICADO, la segunda queda EN_REVISION), stock negativo (STOCK_NEGATIVO), saldo de fiado negativo tras recalcularlo (ABONO_EXCEDE_SALDO), códigos repetidos (CODIGO_REPETIDO) y movimientos en una caja ya cerrada (MOVIMIENTO_CAJA_CERRADA)._
- 11. `servicioConciliacion` → `servicioConciliacion`: detectarCodigosRepetidos(tienda)
- 12. `servicioConciliacion` → `servicioConciliacion`: detectarMovimientosCajaCerrada(tienda, desde)
- **[loop Conflictos | por cada choque detectado]**
  - 13. `servicioConciliacion` → `conflicto`: ConflictoSincronizacion(id, tipo, descripcion, idsRegistros, ahora)
  - _Nota: El id es determinista (tipo + registros): si otro dispositivo ya creó el mismo conflicto, no se duplica (DA-48)._
  - 14. `servicioConciliacion` → `conflictos`: guardar(tienda, conflicto)
- 15. `unidadTrabajo` → `servicioConciliacion`: retorno
- 16. `servicioConciliacion` → `coordinador`: conflictosNuevos
- 17. `coordinador` → `Sincronizador`: conflictosNuevos
- _Nota: Alimentan el indicador de pendientes y conflictos (RNF-09); el Propietario los resuelve en CUS-22._
