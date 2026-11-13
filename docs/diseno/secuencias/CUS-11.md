# CUS-11 Registrar movimiento de caja

Diagrama de secuencia exportado de EA (3.3.11 CUS-11 Registrar movimiento de caja).

## Participantes

- `Propietario` (Actor)
- `VistaCaja` (Sequence)
- `coordinador` : `RegistrarMovimientoCajaCoordinator`
- `servicioAcceso` : `ServicioAcceso`
- `servicioCaja` : `ServicioCaja`
- `cajas` : `ICajaRepositorio`
- `caja` : `Caja`
- `movimiento` : `MovimientoCaja`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- _Nota: tipo : TipoMovimientoCaja (INGRESO o EGRESO); clasificacion : ClasificacionMovimiento (NEGOCIO o PERSONAL), para separar la caja del negocio de los gastos personales (RF-10)._
- 1. `Propietario` → `VistaCaja`: ingresarMovimiento(tipo, clasificacion, valor, descripcion)
- _Nota: Control de acceso por rol detallado en CUS-05: si el usuario no es propietario, se rechaza (RNF-12)._
- 2. `VistaCaja` → `coordinador`: registrarMovimiento(tienda, tipo, clasificacion, valor, descripcion, usuario)
- 3. `coordinador` → `servicioAcceso`: exigirPropietario(usuario)
- 4. `servicioAcceso` → `coordinador`: retorno
- 5. `coordinador` → `servicioCaja`: registrarMovimientoManual(tienda, tipo, clasificacion, valor, descripcion)
- **[break Clasificación no permitida | clasificacion = ANULACION]**
  - 6. `servicioCaja` → `coordinador`: error("Clasificación no permitida")
  - 7. `coordinador` → `VistaCaja`: error("Clasificación no permitida")
  - 8. `VistaCaja` → `Propietario`: mostrar("Esa clasificación solo la usa la anulación de ventas")
- 9. `servicioCaja` → `servicioCaja`: registrarMovimiento(tienda, tipo, clasificacion, valor, descripcion)
- **[break Valor no válido | valor <= 0]**
  - _Nota: También la llaman registrarIngreso (venta de contado en CUS-02 y abono en efectivo en CUS-08) y ProcesadorPagoContado.revertir._
  - 10. `servicioCaja` → `coordinador`: error("Valor no válido")
  - 11. `coordinador` → `VistaCaja`: error("Valor no válido")
  - 12. `VistaCaja` → `Propietario`: mostrar("El valor debe ser mayor que cero")
- 13. `servicioCaja` → `servicioCaja`: obtenerCajaDelDia(tienda, hoy)
- 14. `servicioCaja` → `cajas`: buscarPorFecha(tienda, hoy)
- 15. `cajas` → `servicioCaja`: caja
- **[opt Abrir caja | caja = null (primer movimiento del día)]**
  - 16. `servicioCaja` → `caja`: Caja(id, hoy)
  - _Nota: Creator: id = tienda + fecha, así dos dispositivos sin conexión abren la misma caja._
  - 17. `servicioCaja` → `cajas`: crear(tienda, caja)
- 18. `servicioCaja` → `movimiento`: MovimientoCaja(id, valor, descripcion, clasificacion, tipo, fecha)
- 19. `servicioCaja` → `caja`: registrarMovimiento(movimiento)
- **[break Caja cerrada | caja.isCerrada() (ya se hizo el cierre del día)]**
  - 20. `caja` → `servicioCaja`: error("Caja cerrada")
  - 21. `servicioCaja` → `coordinador`: error("Caja cerrada")
  - 22. `coordinador` → `VistaCaja`: error("Caja cerrada")
  - 23. `VistaCaja` → `Propietario`: mostrar("La caja de hoy ya está cerrada")
- _Nota: Information Expert: la caja agrega el movimiento a su lista; el saldo no se guarda, se calcula de los movimientos (DA-62)._
- 24. `caja` → `servicioCaja`: movimiento
- 25. `servicioCaja` → `cajas`: registrarMovimiento(tienda, caja, movimiento)
- _Nota: Inserta solo el movimiento nuevo; nunca reescribe la caja ni los demás movimientos (DA-48, DA-62)._
- 26. `servicioCaja` → `coordinador`: movimiento
- 27. `coordinador` → `VistaCaja`: movimiento
- 28. `VistaCaja` → `Propietario`: mostrar("Movimiento registrado")
