# CUS-14 Registrar cierre de caja

Diagrama de secuencia exportado de EA (3.3.14 CUS-14 Registrar cierre de caja).

## Participantes

- `Propietario` (Actor)
- `VistaCierreCaja` (Sequence)
- `coordinador` : `RegistrarCierreCajaCoordinator`
- `servicioAcceso` : `ServicioAcceso`
- `servicioCaja` : `ServicioCaja`
- `cajas` : `ICajaRepositorio`
- `caja` : `Caja`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- 1. `Propietario` → `VistaCierreCaja`: iniciarCierre()
- 2. `VistaCierreCaja` → `coordinador`: consultarSaldoEsperado(tienda, usuario)
- 3. `coordinador` → `servicioAcceso`: exigirPropietario(usuario)
- _Nota: Control de acceso por rol detallado en CUS-05: si el usuario no es propietario, se rechaza (RNF-12)._
- 4. `servicioAcceso` → `coordinador`: retorno
- 5. `coordinador` → `servicioCaja`: consultarSaldoEsperado(tienda)
- 6. `servicioCaja` → `servicioCaja`: obtenerCajaDelDia(tienda, hoy)
- _Nota: Detalle en CUS-11: busca la caja de hoy y, si no existe, la crea._
- 7. `servicioCaja` → `caja`: calcularSaldoEsperado()
- 8. `caja` → `servicioCaja`: saldoEsperado
- _Nota: Information Expert: suma los ingresos y resta los egresos de sus movimientos (esIngreso()). El saldo no se guarda, se calcula (DA-62)._
- 9. `servicioCaja` → `coordinador`: saldoEsperado
- 10. `coordinador` → `VistaCierreCaja`: saldoEsperado
- 11. `VistaCierreCaja` → `Propietario`: mostrar("Saldo esperado: " + saldoEsperado)
- 12. `Propietario` → `VistaCierreCaja`: ingresarEfectivoContado(efectivoContado)
- 13. `VistaCierreCaja` → `coordinador`: cerrarCaja(tienda, efectivoContado, usuario)
- 14. `coordinador` → `servicioAcceso`: exigirPropietario(usuario)
- 15. `servicioAcceso` → `coordinador`: retorno
- 16. `coordinador` → `servicioCaja`: cerrarCaja(tienda, efectivoContado)
- 17. `servicioCaja` → `servicioCaja`: obtenerCajaDelDia(tienda, hoy)
- 18. `servicioCaja` → `caja`: cerrar(efectivoContado)
- **[break Caja ya cerrada | caja.isCerrada() (ya se hizo el cierre de hoy)]**
  - 19. `caja` → `servicioCaja`: error("Caja cerrada")
  - 20. `servicioCaja` → `coordinador`: error("Caja cerrada")
  - 21. `coordinador` → `VistaCierreCaja`: error("Caja cerrada")
  - 22. `VistaCierreCaja` → `Propietario`: mostrar("La caja de hoy ya está cerrada")
- 23. `caja` → `caja`: calcularSaldoEsperado()
- _Nota: Information Expert: diferencia = efectivoContado - saldoEsperado; guarda efectivoContado, diferencia y fechaCierre y queda cerrada._
- 24. `caja` → `servicioCaja`: diferencia
- _Nota: Guarda solo el cierre: cerrada, efectivoContado, diferencia y fechaCierre (RF-13)._
- 25. `servicioCaja` → `cajas`: cerrar(tienda, caja)
- 26. `servicioCaja` → `coordinador`: diferencia
- 27. `coordinador` → `VistaCierreCaja`: diferencia
- 28. `VistaCierreCaja` → `Propietario`: mostrar("Faltante o sobrante: " + diferencia)
- _Nota: diferencia  0 es sobrante. Desde el cierre, la caja rechaza nuevos movimientos del día (CUS-11)._
