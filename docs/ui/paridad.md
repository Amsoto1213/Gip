# Paridad móvil–web

Extraído del tablero "Matriz de paridad móvil–web" del canvas de mockups. Cada vista de los diagramas de secuencia tiene una pantalla en la app móvil y otra en la web. **Las dos llaman a las mismas operaciones del coordinador**: solo cambia la distribución según el tamaño de pantalla (RNF-18, RNF-20). Las cinco secciones tienen el mismo nombre y el mismo orden en las dos plataformas.

## Secciones

| Sección | Contenido |
|---|---|
| Vender | Vender, buscar, leer código, cobrar, fiar, venta perdida |
| Surtido | Existencias, entrada, pérdida, conteo, productos |
| Fiados | Clientes, saldo e historial, abono, eliminar datos |
| Caja | Movimientos, ventas de hoy y anular, cierre |
| Negocio | Resumen, alertas, reportes, usuarios, exportar, sincronización |

## Matriz

| CUS | Caso de uso | Vista en el diagrama | Actor | App móvil (PNG) | Web (PNG) |
|---|---|---|---|---|---|
| CUS-01 | Registrar entrada de mercancía | `VistaEntradaMercancia` | Empleado | Entrada (`Entrada`) | Entrada de mercancía (`wEntrada`) |
| CUS-02 | Registrar venta | `VistaVenta` | Empleado | Vender (`Main`), Cobrar (`Cobro`) | Vender (`Vender`) |
| CUS-03 | Registrar pérdida o devolución | `VistaPerdida` | Empleado | Pérdida (`mPerdida`) | Pérdida o devolución (`wPerdida`) |
| CUS-04 | Registrar conteo físico | `VistaConteo` | Empleado | Conteo (`mConteo`) | Conteo físico (`Conteo`) |
| CUS-05 | Consultar alertas de reabastecimiento | `VistaAlertas` | Propietario | Alertas (`Alertas`) | Alertas de surtido (`wAlertas`) |
| CUS-06 | Buscar producto | `VistaBusquedaProducto` | Empleado | Buscar (`mBuscar`) | Vender · lista de resultados (`Vender`) |
| CUS-07 | Registrar fiado | `VistaFiado` | Empleado | Fiar (`mFiar`) | Fiar, cuadro (`wFiar`) |
| CUS-08 | Registrar abono | `VistaAbono` | Empleado | Abono (`mAbono`) | Fiados · panel de abono (`wClientes`) |
| CUS-09 | Consultar margen de ganancia | `VistaMargen` | Propietario | Ganancia (`mMargen`) | Ganancia por producto (`wMargen`) |
| CUS-10 | Generar reporte diario | `VistaReporteDiario` | Propietario | Reporte del día (`mReporte`) | Reporte del día (`Reporte`) |
| CUS-11 | Registrar movimiento de caja | `VistaCaja` | Propietario | Caja (`mCaja`) | Caja · movimientos (`wCaja`) |
| CUS-12 | Consultar rotación de productos | `VistaRotacion` | Propietario | Rotación (`mRotacion`) | Rotación (`wRotacion`) |
| CUS-13 | Registrar venta perdida | `VistaVenta` | Empleado | Buscar · "se fue sin él" (`mBuscar`) | Vender · "se fue sin él" (`Vender`) |
| CUS-14 | Registrar cierre de caja | `VistaCierreCaja` | Propietario | Cerrar caja (`mCierre`) | Cierre de caja (`wCierre`) |
| CUS-15 | Gestionar usuarios de la tienda | `VistaUsuarios` | Propietario | Usuarios (`mUsuarios`) | Usuarios (`wUsuarios`) |
| CUS-16 | Exportar datos del negocio | `VistaExportacion` | Propietario | Exportar (`mExportar`) | Exportar datos (`wExportar`) |
| CUS-17 | Leer código de producto | `Lector2D` → `VistaBusquedaProducto` | Empleado | Leer código, Bluetooth o cámara (`Escanear`) | Vender, lector USB (`Vender`) — ver nota |
| CUS-18 | Gestionar producto | `VistaProducto` | Empleado | Producto (`mProducto`) | Producto (`wProducto`) |
| CUS-19 | Consultar saldo e historial de cliente | `VistaCliente` | Empleado | Fiados (`mClientes`), Cliente (`Cliente`) | Fiados · lista y detalle (`wClientes`) |
| CUS-20 | Anular venta | `VistaAnulacion` | Propietario | Ventas de hoy (`Anular`) | Ventas de hoy (`wAnular`) |
| CUS-21 | Eliminar datos de un cliente | `VistaCliente` | Empleado | Cliente (`Cliente`) | Fiados · detalle (`wClientes`) |
| CUS-22 | Revisar conflictos de sincronización | `VistaConflictos` | Propietario | Revisar sincronización (`mConflictos`) | Revisar sincronización (`wConflictos`) |
| CUS-23 | Conciliar datos sincronizados | — (actor Tiempo) | Automático | Aviso "Al día / por subir" (`Main`) | Aviso del menú lateral (`Panel`) |
| CUS-24 | Generar alertas de reabastecimiento | — (actor Tiempo) | Automático | "Calculadas a las 5:00 a. m." (`Alertas`) | "Calculadas a las 5:00 a. m." (`wAlertas`) |
| CUS-25 | Consultar existencias | `VistaExistencias` | Empleado | Surtido (`mExistencias`) | Existencias (`wExistencias`) |

## Reglas de la matriz

- **Roles en la navegación:** el Empleado ve Vender, Surtido y Fiados; el Propietario (Administrador) además ve Caja y Negocio (RNF-12). En el móvil, el empleado tiene 3 pestañas en lugar de 5. Lo controla `ServicioAcceso` con el rol del usuario activo.
- **Lectura de códigos (DA-47):** en el móvil, lector 2D por Bluetooth con la cámara como respaldo. Ambos entregan el mismo texto a `buscarPorLectura`.

## Nota: diferencia entre el mockup y el diseño en CUS-17

El tablero de paridad dice que en la web se lee con "lector USB o cámara web". El diagrama de secuencia de CUS-17 en el `.qea` dice que la cámara se usa **solo en la app Android** y que en la web se lee con el lector 2D. Según `CLAUDE.md`, manda el diseño: en la web solo lector 2D, sin cámara. Si el equipo quiere la cámara web, primero se cambia el diagrama en EA.
