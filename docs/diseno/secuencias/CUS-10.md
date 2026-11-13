# CUS-10 Generar reporte diario

Diagrama de secuencia exportado de EA (3.3.10 CUS-10 Generar reporte diario).

## Participantes

- `Propietario` (Actor)
- `VistaReporteDiario` (Sequence)
- `coordinador` : `GenerarReporteDiarioCoordinator`
- `servicioAcceso` : `ServicioAcceso`
- `servicioReportes` : `ServicioReportes`
- `ventas` : `IVentaRepositorio`
- `movimientos` : `IMovimientoInventarioRepositorio`
- `fiados` : `IFiadoRepositorio`
- `cajas` : `ICajaRepositorio`
- `reporte` : `ReporteDiario`
- `estadoSincronizacion` : `IEstadoSincronizacion`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- 1. `Propietario` → `VistaReporteDiario`: generarReporte(fecha)
- 2. `VistaReporteDiario` → `coordinador`: generarReporte(tienda, fecha, usuario)
- 3. `coordinador` → `servicioAcceso`: exigirPropietario(usuario)
- _Nota: Control de acceso por rol detallado en CUS-05: si el usuario no es propietario, se rechaza (RNF-12)._
- 4. `servicioAcceso` → `coordinador`: retorno
- _Nota: desde y hasta = inicio y fin de la fecha. Cada total lo calcula la entidad que tiene el dato (Information Expert, DA-72)._
- 5. `coordinador` → `servicioReportes`: generarReporteDiario(tienda, fecha)
- _Nota: Sin las anuladas: totalVentas = suma de venta.getTotal(); ventasFiadas y ventasNequi = suma de forma.calcularMontoCubierto() de las formas Fiado y PagoNequi (Polymorphism)._
- 6. `servicioReportes` → `ventas`: listarPorPeriodo(tienda, desde, hasta)
- 7. `ventas` → `servicioReportes`: ventas
- 8. `servicioReportes` → `movimientos`: listarSalidasPorTienda(tienda, desde, hasta)
- _Nota: margen = suma de salida.calcularMargen() (detalle en CUS-09); incompleto si alguna devuelve null._
- 9. `movimientos` → `servicioReportes`: salidas
- 10. `servicioReportes` → `movimientos`: listarEntradasPorTienda(tienda, desde, hasta)
- _Nota: totalEntradas = suma de entrada.calcularCostoTotal()._
- 11. `movimientos` → `servicioReportes`: entradas
- 12. `servicioReportes` → `fiados`: listarAbonos(tienda, desde, hasta)
- 13. `fiados` → `servicioReportes`: abonos
- _Nota: Sin los anulados: abonosRecibidos = suma de abono.getMonto(); abonosNequi = los de medio NEQUI._
- 14. `servicioReportes` → `cajas`: listarMovimientos(tienda, desde, hasta)
- _Nota: Solo egresos (esIngreso() falso): gastosNegocio = los que esDelNegocio(); retirosPersonales = los PERSONAL; los de ANULACION no suman a ninguno (RF-10)._
- 15. `cajas` → `servicioReportes`: movimientosCaja
- 16. `servicioReportes` → `estadoSincronizacion`: hayPendientes(tienda)
- 17. `estadoSincronizacion` → `servicioReportes`: parcial
- _Nota: Verdadero si quedan operaciones sin sincronizar (ERS 3.2.5)._
- _Nota: utilidad = margen - gastosNegocio (no resta retiros personales ni devoluciones por anulación)._
- 18. `servicioReportes` → `reporte`: ReporteDiario(fecha, totalVentas, ventasFiadas, ventasNequi, abonosRecibidos, abonosNequi, totalEntradas, gastosNegocio, utilidad, retirosPersonales, incompleto, parcial)
- 19. `servicioReportes` → `coordinador`: reporte
- 20. `coordinador` → `VistaReporteDiario`: reporte
- 21. `VistaReporteDiario` → `reporte`: calcularDineroNequi()
- 22. `reporte` → `VistaReporteDiario`: dineroNequi
- 23. `VistaReporteDiario` → `Propietario`: mostrar(reporte)
- _Nota: Muestra ventas, entradas y utilidad, con los retiros personales en una columna aparte (RF-10) y el dinero que entró por Nequi; avisa si es incompleto (falta costo) o parcial (pendiente de sincronizar). No se guarda: se genera cada vez (DA-40), en 5 s o menos (RD-10)._
