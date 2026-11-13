# CUS-08 Registrar abono

Diagrama de secuencia exportado de EA (3.3.8 CUS-08 Registrar abono).

## Participantes

- `Empleado` (Actor)
- `VistaAbono` (Sequence)
- `coordinador` : `RegistrarAbonoCoordinator`
- `servicioAbonos` : `ServicioAbonos`
- `servicioCaja` : `ServicioCaja`
- `unidadTrabajo` : `IUnidadTrabajo`
- `fiados` : `IFiadoRepositorio`
- `fiado` : `Fiado`
- `abono` : `Abono`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- **ref** CUS-19 Consultar saldo e historial de cliente — El Empleado busca al cliente, ve sus fiados pendientes y elige a cuál aplica el abono. Resultado: fiado : Fiado.
- _Nota: medio : MedioPago es EFECTIVO o NEQUI; la referencia de Nequi es opcional._
- 1. `Empleado` → `VistaAbono`: ingresarAbono(monto, medio, referencia)
- 2. `VistaAbono` → `coordinador`: registrarAbono(tienda, fiado, monto, medio, referencia)
- 3. `coordinador` → `servicioAbonos`: registrarAbono(tienda, fiado, monto, medio, referencia)
- 4. `servicioAbonos` → `fiado`: getSaldoPendiente()
- 5. `fiado` → `servicioAbonos`: saldo
- **[break Monto no válido | monto <= 0 o monto > saldo (IE-06)]**
  - 6. `servicioAbonos` → `coordinador`: error("Monto no válido")
  - 7. `coordinador` → `VistaAbono`: error("Monto no válido")
  - 8. `VistaAbono` → `Empleado`: mostrar("El abono debe ser mayor que cero y no puede superar el saldo pendiente")
- 9. `servicioAbonos` → `abono`: Abono(id, monto, fecha, medio, referencia)
- 10. `servicioAbonos` → `unidadTrabajo`: ejecutar(accion)
- 11. `unidadTrabajo` → `servicioAbonos`: accion()
- _Nota: Information Expert: agrega el abono, baja el saldo y pasa a SALDADO si llega a cero (RN-05)._
- 12. `servicioAbonos` → `fiado`: registrarAbono(abono)
- 13. `servicioAbonos` → `fiados`: registrarAbono(tienda, fiado, abono)
- 14. `servicioAbonos` → `abono`: esEfectivo()
- 15. `abono` → `servicioAbonos`: efectivo
- **[opt Ingreso en caja | efectivo = true]**
  - _Nota: Detalle en CUS-11: rechaza si la caja del día está cerrada. El abono por Nequi no mueve la caja (DA-64)._
  - 16. `servicioAbonos` → `servicioCaja`: registrarIngreso(tienda, monto, "Abono")
  - _Nota: Unit of Work (RNF-04): el abono, el nuevo saldo del fiado y el ingreso en caja se guardan juntos, con su registro en la cola de pendientes (RNF-08)._
- **[alt Resultado de la transacción | transacción confirmada]**
  - 17. `unidadTrabajo` → `servicioAbonos`: retorno
  - 18. `servicioAbonos` → `coordinador`: abono
  - 19. `coordinador` → `VistaAbono`: abono
  - 20. `VistaAbono` → `fiado`: getSaldoPendiente()
  - 21. `fiado` → `VistaAbono`: nuevoSaldo
  - 22. `VistaAbono` → `Empleado`: mostrar("Abono registrado. Nuevo saldo: " + nuevoSaldo)
- **[alt Resultado de la transacción | caja cerrada o error al guardar (rollback: no se guarda nada)]**
  - 23. `unidadTrabajo` → `servicioAbonos`: error
  - 24. `servicioAbonos` → `coordinador`: error
  - 25. `coordinador` → `VistaAbono`: error
  - 26. `VistaAbono` → `Empleado`: mostrar(mensajeError)
