# CUS-22 Revisar conflictos de sincronización

Diagrama de secuencia exportado de EA (3.3.22 CUS-22 Revisar conflictos de sincronización).

## Participantes

- `Propietario` (Actor)
- `VistaConflictos` (Sequence)
- `coordinador` : `RevisarConflictosCoordinator`
- `servicioAcceso` : `ServicioAcceso`
- `servicioConciliacion` : `ServicioConciliacion`
- `unidadTrabajo` : `IUnidadTrabajo`
- `conflictos` : `IConflictoRepositorio`
- `resolutor` : `ResolutorConflicto`
- `conflicto` : `ConflictoSincronizacion`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- 1. `Propietario` → `VistaConflictos`: abrirConflictos()
- 2. `VistaConflictos` → `coordinador`: consultarConflictos(tienda, usuario)
- 3. `coordinador` → `servicioAcceso`: exigirPropietario(usuario)
- 4. `servicioAcceso` → `coordinador`: retorno
- _Nota: Control de acceso por rol detallado en CUS-05; cada operación del coordinador lo exige (RNF-12)._
- 5. `coordinador` → `servicioConciliacion`: obtenerConflictos(tienda)
- 6. `servicioConciliacion` → `conflictos`: listarPendientes(tienda)
- 7. `conflictos` → `servicioConciliacion`: conflictos
- 8. `servicioConciliacion` → `coordinador`: conflictos
- 9. `coordinador` → `VistaConflictos`: conflictos
- 10. `VistaConflictos` → `Propietario`: mostrar(conflictos)
- _Nota: Los conflictos se detectan al sincronizar (CUS-23). Cada uno muestra su tipo y su descripción en el lenguaje del tendero (getDescripcion(), RNF-25)._
- _Nota: idsElegidos son los registros que el Propietario escoge, por ejemplo cuál de dos entradas duplicadas anular; puede ir vacío._
- 11. `Propietario` → `VistaConflictos`: resolver(conflicto, idsElegidos)
- 12. `VistaConflictos` → `coordinador`: resolver(tienda, conflicto, idsElegidos, usuario)
- 13. `coordinador` → `servicioAcceso`: exigirPropietario(usuario)
- 14. `servicioAcceso` → `coordinador`: retorno
- 15. `coordinador` → `servicioConciliacion`: resolverConflicto(tienda, conflicto, idsElegidos)
- 16. `servicioConciliacion` → `unidadTrabajo`: ejecutar(accion)
- _Nota: Devuelve el primer resolutor cuyo admite(conflicto) es verdadero (Polymorphism)._
- 17. `unidadTrabajo` → `servicioConciliacion`: accion()
- 18. `servicioConciliacion` → `servicioConciliacion`: resolutorPara(conflicto)
- _Nota: Strategy: ResolutorMovimientos (POSIBLE_DUPLICADO, STOCK_NEGATIVO) anula los movimientos elegidos y recalcula el stock; ResolutorAbonoExcedido anula los abonos elegidos y devuelve el efectivo por la caja (CUS-11); ResolutorCodigoRepetido quita el código o cambia el código interno; ResolutorCajaCerrada recalcula la diferencia de la caja. Un tipo nuevo es una clase nueva (OCP)._
- 19. `servicioConciliacion` → `resolutor`: resolver(tienda, conflicto, idsElegidos)
- 20. `servicioConciliacion` → `conflicto`: setResuelto(true)
- 21. `servicioConciliacion` → `conflictos`: marcarResuelto(tienda, conflicto)
- **[alt Resultado de la transacción | transacción confirmada]**
  - 22. `unidadTrabajo` → `servicioConciliacion`: retorno
  - 23. `servicioConciliacion` → `coordinador`: retorno
  - 24. `coordinador` → `VistaConflictos`: retorno
  - 25. `VistaConflictos` → `Propietario`: mostrar("Conflicto resuelto")
- **[alt Resultado de la transacción | error al aplicar la decisión (rollback: no se guarda nada)]**
  - 26. `unidadTrabajo` → `servicioConciliacion`: error
  - 27. `servicioConciliacion` → `coordinador`: error
  - 28. `coordinador` → `VistaConflictos`: error
  - 29. `VistaConflictos` → `Propietario`: mostrar(mensajeError)
