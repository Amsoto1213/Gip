# CUS-05 Consultar alertas de reabastecimiento

Diagrama de secuencia exportado de EA (3.3.5 CUS-05 Consultar alertas de reabastecimiento).

## Participantes

- `Propietario` (Actor)
- `VistaAlertas` (Sequence)
- `coordinador` : `ConsultarAlertasCoordinator`
- `servicioAcceso` : `ServicioAcceso`
- `servicioAlertas` : `ServicioAlertas`
- `alertas` : `IAlertaRepositorio`
- `ventasPerdidas` : `IVentaPerdidaRepositorio`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- 1. `Propietario` → `VistaAlertas`: consultarAlertas()
- 2. `VistaAlertas` → `coordinador`: consultarAlertas(tienda, fecha, usuario)
- 3. `coordinador` → `servicioAcceso`: exigirPropietario(usuario)
- 4. `servicioAcceso` → `servicioAcceso`: esPropietario(usuario)
- **[break Sin permiso | esPropietario = false (RNF-12)]**
  - 5. `servicioAcceso` → `coordinador`: error("Acceso denegado")
  - 6. `coordinador` → `VistaAlertas`: error("Acceso denegado")
  - 7. `VistaAlertas` → `Propietario`: mostrar("Esta consulta es solo para el propietario")
- 8. `servicioAcceso` → `coordinador`: retorno
- 9. `coordinador` → `servicioAlertas`: obtenerAlertas(tienda, fecha)
- _Nota: Las alertas se calculan y guardan una vez al día en CUS-24 Generar alertas de reabastecimiento (actor Tiempo); aquí solo se leen, por eso la consulta es rápida (RD-09)._
- 10. `servicioAlertas` → `alertas`: listarPorFecha(tienda, fecha)
- 11. `alertas` → `servicioAlertas`: alertas
- 12. `servicioAlertas` → `coordinador`: alertas
- 13. `coordinador` → `VistaAlertas`: alertas
- **[alt Alertas del día | no hay alertas para la fecha]**
  - 14. `VistaAlertas` → `Propietario`: mostrar("No hay productos por agotarse")
- **[alt Alertas del día | hay alertas]**
  - 15. `VistaAlertas` → `Propietario`: mostrar(alertas)
  - _Nota: Por cada alerta la Vista muestra el producto (alerta.getItem().getProducto().getNombre()) y su sustento: getExistencia(), getConsumoPromedioDiario(), getDiasCobertura() e isProvisional(), que es verdadero si hay menos de 30 días de historial (RNF-03). Es una sugerencia verificable: el Propietario decide si reabastece (RF-05)._
- **[opt Ventas perdidas | el Propietario consulta las ventas perdidas]**
  - _Nota: Mismo control de acceso de arriba: si no es propietario, se rechaza._
  - 16. `Propietario` → `VistaAlertas`: consultarVentasPerdidas(desde, hasta)
  - 17. `VistaAlertas` → `coordinador`: consultarVentasPerdidas(tienda, desde, hasta, usuario)
  - 18. `coordinador` → `servicioAcceso`: exigirPropietario(usuario)
  - 19. `servicioAcceso` → `coordinador`: retorno
  - 20. `coordinador` → `servicioAlertas`: obtenerVentasPerdidas(tienda, desde, hasta)
  - 21. `servicioAlertas` → `ventasPerdidas`: buscarPorPeriodo(tienda, desde, hasta)
  - 22. `ventasPerdidas` → `servicioAlertas`: ventasPerdidas
  - 23. `servicioAlertas` → `coordinador`: ventasPerdidas
  - 24. `coordinador` → `VistaAlertas`: ventasPerdidas
  - 25. `VistaAlertas` → `Propietario`: mostrar(ventasPerdidas)
