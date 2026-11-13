# Diseño detallado de la Business Layer (exportado de ProyectoUML.qea)

Fuente de verdad del diseño. Generado automáticamente: no editar a mano; regenerar con `tool/export_qea.py` cuando cambie el modelo de EA.

Dependencias permitidas: Workflow → Componentes → Interfaces → Entidades. Getters/setters omitidos cuando son triviales.

## Entidades/GestionCaja

### `Caja` (class)

> Caja del dia de una tienda; agrupa sus movimientos de dinero. Su id se forma con la tienda y la fecha. El saldo esperado se calcula de los movimientos y no se guarda (DA-48, DA-62). Traza a Caja.

Atributos:
- `- cerrada: bool`
- `- diferencia: Decimal?` — Efectivo contado menos saldo esperado: positivo sobrante, negativo faltante; nulo mientras esta abierta (RF-13).
- `- efectivoContado: Decimal?` — Efectivo contado al cerrar; nulo mientras la caja esta abierta.
- `- fecha: DateTime`
- `- fechaCierre: DateTime?` — Fecha y hora del cierre; nula mientras esta abierta. La usa la conciliacion para detectar movimientos posteriores al cierre.
- `- id: String` — Se forma con la tienda y la fecha: dos dispositivos sin conexion abren la misma caja del dia (DA-62).
- `- movimientos: List<MovimientoCaja>`

Operaciones:
- `+ Caja(id: String, fecha: DateTime)`
- `+ calcularSaldoEsperado(): Decimal` — Information Expert: suma los ingresos y resta los egresos de sus movimientos con esIngreso(). El saldo no se guarda, se calcula (DA-48, DA-62).
- `+ cerrar(efectivoContado: Decimal): Decimal` — Information Expert: rechaza si ya esta cerrada; si no, diferencia = efectivoContado - calcularSaldoEsperado(), guarda efectivoContado, diferencia y fechaCierre, queda cerrada y devuelve la diferencia (RF-13).
- `+ recalcularDiferencia(): Decimal` — Information Expert: en una caja cerrada vuelve a calcular diferencia = efectivoContado - calcularSaldoEsperado(), por ejemplo cuando se acepta un movimiento que llego despues del cierre (DA-66).
- `+ getFechaCierre(): DateTime?` — Fecha del cierre, o nula.
- `+ getId(): String` — Identificador unico del objeto (DA-43).
- `+ registrarMovimiento(movimiento: MovimientoCaja): MovimientoCaja` — Information Expert: rechaza si la caja esta cerrada; si no, agrega el movimiento a su lista.

### `ClasificacionMovimiento` (enum)

> Clasificacion de un movimiento de caja: NEGOCIO, PERSONAL o ANULACION (dinero devuelto por una venta anulada; no es gasto ni retiro, DA-51).

Valores: `NEGOCIO`, `PERSONAL`, `ANULACION`

### `MovimientoCaja` (class)

> Movimiento de dinero de la caja: ingreso (venta de contado, abono) o egreso (gasto, retiro personal, devolucion por anulacion), con su clasificacion (RF-10). Solo se agrega (DA-48). Traza a Caja (R4).

Atributos:
- `- id: String` — Identificador unico (UUID) generado en el dispositivo al crear el objeto, para guardarlo, relacionarlo y sincronizarlo sin conexion (RNF-08, RD-12, DA-43).
- `- clasificacion: ClasificacionMovimiento`
- `- descripcion: String`
- `- fecha: DateTime`
- `- valor: Decimal`
- `- tipo: TipoMovimientoCaja`

Operaciones:
- `+ esDelNegocio(): bool` — Information Expert: verdadero solo si la clasificacion es NEGOCIO; PERSONAL y ANULACION no suman a la utilidad (RF-10).
- `+ esIngreso(): bool` — Verdadero si el tipo es INGRESO.
- `+ MovimientoCaja(id: String, valor: Decimal, descripcion: String, clasificacion: ClasificacionMovimiento, tipo: TipoMovimientoCaja, fecha: DateTime)`
- `+ getId(): String` — Identificador unico del objeto (DA-43).

Relaciones: Aggregation → `Caja` [1] (composición); Dependency → `ClasificacionMovimiento`; Dependency → `TipoMovimientoCaja`

### `ReporteDiario` (class)

> Resultado del reporte diario (RF-09, RF-10, IE-08): ventas (y cuanto quedo fiado), abonos, entradas, gastos, utilidad y retiros personales aparte. No se guarda: se genera cada vez (DA-40).

Atributos:
- `- fecha: DateTime`
- `- totalVentas: Decimal`
- `- totalEntradas: Decimal`
- `- utilidad: Decimal`
- `- retirosPersonales: Decimal`
- `- parcial: bool`
- `- ventasFiadas: Decimal` — Parte de totalVentas que quedo fiada (IE-06).
- `- abonosRecibidos: Decimal` — Abonos a fiados recibidos en el dia (IE-06).
- `- gastosNegocio: Decimal` — Egresos de caja clasificados NEGOCIO (RF-10).
- `- incompleto: bool` — Verdadero si alguna salida del dia no tiene costo y la utilidad no es exacta (ERS 3.2.4).
- `- ventasNequi: Decimal` — Parte de totalVentas pagada por Nequi, para cruzarla con la app de Nequi (DA-63).
- `- abonosNequi: Decimal` — Parte de abonosRecibidos que llego por Nequi (DA-64).

Operaciones:
- `+ ReporteDiario(fecha: DateTime, totalVentas: Decimal, ventasFiadas: Decimal, ventasNequi: Decimal, abonosRecibidos: Decimal, abonosNequi: Decimal, totalEntradas: Decimal, gastosNegocio: Decimal, utilidad: Decimal, retirosPersonales: Decimal, incompleto: bool, parcial: bool)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ getFecha(): DateTime` — Fecha del reporte.
- `+ getTotalVentas(): Decimal` — Total vendido.
- `+ getVentasFiadas(): Decimal` — Ventas fiadas del dia.
- `+ getVentasNequi(): Decimal` — Ventas pagadas por Nequi en el dia.
- `+ getAbonosRecibidos(): Decimal` — Abonos recibidos en el dia.
- `+ getAbonosNequi(): Decimal` — Abonos recibidos por Nequi en el dia.
- `+ calcularDineroNequi(): Decimal` — Information Expert: ventasNequi + abonosNequi, todo el dinero que entro por Nequi en el dia, para cruzarlo con la app de Nequi.
- `+ getTotalEntradas(): Decimal` — Total de entradas de mercancia.
- `+ getGastosNegocio(): Decimal` — Gastos del negocio del dia.
- `+ getUtilidad(): Decimal` — Margen de las salidas VIGENTES del dia (con el precio y el costo guardados en cada salida) menos los gastos del negocio; no resta retiros personales ni devoluciones por anulacion.
- `+ getRetirosPersonales(): Decimal` — Columna separada de retiros personales (RF-10).
- `+ isIncompleto(): bool` — Verdadero si la utilidad no es exacta por falta de costos.
- `+ isParcial(): bool` — Verdadero si hay operaciones pendientes de sincronizar (ERS 3.2.5).

### `Rotacion` (enum)

> Clasificacion de un producto por unidades vendidas (RF-11). No se guarda (DA-40). Usada por ServicioReportes (Componentes): clasificarRotacion devuelve Map&lt;Producto, Rotacion&gt;. Ninguna entidad la tiene como atributo, por eso no tiene lineas en este diagrama.

Valores: `ALTA`, `MEDIA`, `BAJA`

### `TipoMovimientoCaja` (enum)

> Si el movimiento entra (INGRESO) o sale (EGRESO) de la caja.

Valores: `EGRESO`, `INGRESO`

## Entidades/GestionInventario

### `AjusteConteo` (class) extends MovimientoInventario

> Diferencia entre lo contado y el stock en un conteo fisico; prevalece lo contado (RF-04). Traza a Diferencia.

Atributos:
- `- cantidadContada: Decimal`

Operaciones:
- `+ AjusteConteo(id: String, item: ItemInventario, cantidad: Decimal, fecha: DateTime, cantidadContada: Decimal)`

### `AlertaReabastecimiento` (class)

> Sugerencia verificable de reabastecimiento (RF-05). Traza a Lista de faltantes.

Atributos:
- `- id: String` — Identificador unico (UUID) generado en el dispositivo al crear el objeto, para guardarlo, relacionarlo y sincronizarlo sin conexion (RNF-08, RD-12, DA-43).
- `- consumoPromedioDiario: Decimal`
- `- diasCobertura: Decimal`
- `- fecha: DateTime`
- `- item: ItemInventario`
- `- provisional: bool`
- `- existencia: Decimal`

Operaciones:
- `+ AlertaReabastecimiento(id: String, item: ItemInventario, fecha: DateTime, existencia: Decimal, consumoPromedioDiario: Decimal, diasCobertura: Decimal, provisional: bool)`
- `+ getId(): String` — Identificador unico del objeto (DA-43).

Relaciones: Association → `ItemInventario` [1]

### `CodigoProducto` (class)

> Codigo asociado a un producto: de barras (EAN-13, EAN-8, UPC-A) o QR. valor guarda el texto exacto que devuelve la lectura; un mismo valor no se repite entre productos de una tienda (RF-06, DA-41).

Atributos:
- `- id: String` — Identificador unico (UUID) generado en el dispositivo al crear el objeto, para guardarlo, relacionarlo y sincronizarlo sin conexion (RNF-08, RD-12, DA-43).
- `- valor: String`
- `- formato: FormatoCodigo`

Operaciones:
- `+ CodigoProducto(id: String, formato: FormatoCodigo, valor: String)`
- `+ getId(): String` — Identificador unico del objeto (DA-43).

Relaciones: Aggregation → `Producto` [1] (composición); Dependency → `FormatoCodigo`

### `EntradaMercancia` (class) extends MovimientoInventario

> Entrada de mercancia de un producto, con su costo y, si hay, el numero de factura (RF-01). Traza a Mercancia (DA-11).

Atributos:
- `- costoUnitario: Decimal`
- `- numeroFactura: String?` — Numero de la factura del proveedor; nulo si la entrada llego sin factura (IE-02).

Operaciones:
- `+ calcularCostoTotal(): Decimal` — Information Expert: getCantidad() x getCostoUnitario() (RF-09, DA-72).
- `+ EntradaMercancia(id: String, item: ItemInventario, cantidad: Decimal, fecha: DateTime, costoUnitario: Decimal, numeroFactura: String?)`

### `EstadoMovimiento` (enum)

> Estado de un movimiento de inventario para la conciliacion (DA-48).

Valores: `VIGENTE`, `EN_REVISION`, `ANULADO`

### `Etiqueta` (class)

> Etiqueta para pegar en un producto: apunta al producto (nombre y precio) y al codigo que se imprime. No se guarda; la crea ServicioCatalogo y la recibe IImpresionEtiquetas (DA-39, DA-40, DA-41).

Atributos:
- `- producto: Producto`
- `- codigo: CodigoProducto`

Operaciones:
- `+ Etiqueta(producto: Producto, codigo: CodigoProducto)` — Constructor: recibe sus dependencias o datos.
- `+ getProducto(): Producto` — Producto de la etiqueta.
- `+ getCodigo(): CodigoProducto` — Codigo que se imprime; su formato dice si es QR o de barras.

Relaciones: Association → `Producto` [1]; Association → `CodigoProducto` [1]

### `FormatoCodigo` (enum)

> Formato del codigo leido; lo deduce el interprete con formatoDe (DA-41, DA-47).

Valores: `EAN13`, `EAN8`, `UPCA`, `QR`

### `ItemInventario` (class)

> Stock de un producto en la tienda; lo mantiene ServicioInventario sumando los movimientos (DA-19). Es parte del Producto (composicion): se crea con el y no existe sin el; se guarda con su propio repositorio para no cargar el stock con cada producto (DA-60).

Atributos:
- `- id: String` — Identificador unico (UUID) generado en el dispositivo al crear el objeto, para guardarlo, relacionarlo y sincronizarlo sin conexion (RNF-08, RD-12, DA-43).
- `- producto: Producto`
- `- stockActual: Decimal`

Operaciones:
- `+ ItemInventario(id: String, producto: Producto, stockActual: Decimal)`
- `+ getId(): String` — Identificador unico del objeto (DA-43).

Relaciones: Aggregation → `Producto` [1] (composición)

### `Merma` (class) extends MovimientoInventario

> Mercancia retirada por vencimiento, dano o devolucion, con su motivo (RF-03). Traza a Merma.

Atributos:
- `- motivo: MotivoMerma`

Operaciones:
- `+ Merma(id: String, item: ItemInventario, cantidad: Decimal, fecha: DateTime, motivo: MotivoMerma)`

Relaciones: Dependency → `MotivoMerma`

### `MotivoMerma` (enum)

> Motivo de una perdida o devolucion (RF-03, IE-03 b).

Valores: `VENCIDO`, `DANADO`, `DEVUELTO_PROVEEDOR`, `OTRO`

### `MovimientoInventario` (abstract class)

> Movimiento de stock con cantidad con signo: positiva suma, negativa resta (DA-19, ERS 3.2.1).

Atributos:
- `- id: String` — Identificador unico (UUID) generado en el dispositivo al crear el objeto, para guardarlo, relacionarlo y sincronizarlo sin conexion (RNF-08, RD-12, DA-43).
- `- item: ItemInventario`
- `- cantidad: Decimal`
- `- fecha: DateTime`
- `- estado: EstadoMovimiento` — Solo los VIGENTES suman al stock; EN_REVISION y ANULADO no (ERS 3.2.1 c, DA-48).

Operaciones:
- `+ MovimientoInventario(id: String, item: ItemInventario, cantidad: Decimal, fecha: DateTime)`
- `+ getId(): String` — Identificador unico del objeto (DA-43).
- `+ getEstado(): EstadoMovimiento` — Estado del movimiento.
- `+ setEstado(estado: EstadoMovimiento): void` — Lo cambian ServicioConciliacion (posible duplicado o conflicto resuelto) y ServicioInventario.anularMovimiento (venta anulada).

Relaciones: Association → `ItemInventario` [1]; Dependency → `EstadoMovimiento`

### `Producto` (class)

> Producto del catalogo con sus precios y sus codigos (de barras o QR); su stock esta en ItemInventario (DA-19). Se identifica por id; codigo es el codigo interno que pone la tienda y no se repite dentro de ella (DA-59). Traza a Producto.

Atributos:
- `- id: String` — Identificador unico (UUID) generado en el dispositivo al crear el producto (RNF-08, DA-43, DA-59).
- `- codigo: String` — Codigo interno de la tienda; no se edita. Si dos dispositivos sin conexion crean el mismo codigo, la conciliacion lo reporta (DA-59).
- `- nombre: String`
- `- precioCompra: Decimal?` — Precio de compra; nulo si la tienda no lo conoce: los margenes de ese producto quedan como dato incompleto (ERS 3.2.4).
- `- precioVenta: Decimal`
- `- unidadMedida: UnidadMedida`
- `- codigos: List<CodigoProducto>`
- `- actualizadoEn: DateTime` — Fecha de la ultima edicion; al sincronizar gana la edicion mas reciente (DA-48).

Operaciones:
- `+ getId(): String` — Identificador unico del objeto (DA-43).
- `+ Producto(id: String, codigo: String, nombre: String, unidadMedida: UnidadMedida, precioCompra: Decimal?, precioVenta: Decimal)`
- `+ agregarCodigo(codigo: CodigoProducto): void`
- `+ quitarCodigo(codigo: CodigoProducto): void` — Quita el codigo de su lista. Lo usa la resolucion de un CODIGO_REPETIDO (DA-66).
- `+ cambiarCodigoInterno(codigo: String): void` — Cambia el codigo interno. Solo lo usa la resolucion de un CODIGO_REPETIDO; ningun caso de uso lo edita (DA-66).
- `+ getActualizadoEn(): DateTime` — Fecha de la ultima edicion; la usa la sincronizacion para decidir que edicion gana (DA-48).
- `+ setActualizadoEn(actualizadoEn: DateTime): void` — La asigna el servicio al editar (DA-48).

Relaciones: Dependency → `UnidadMedida`

### `SalidaVenta` (class) extends MovimientoInventario

> Salida de stock por una venta; cantidad negativa. Guarda el precio de venta y el costo del producto en el momento de la venta, para que los reportes no cambien si despues se editan los precios (DA-61).

Atributos:
- `- venta: Venta`
- `- precioUnitario: Decimal` — Precio de venta del producto en el momento de la venta (DA-61).
- `- costoUnitario: Decimal?` — Precio de compra del producto en el momento de la venta; nulo si no estaba registrado (ERS 3.2.4, DA-61).

Operaciones:
- `+ getPrecioUnitario(): Decimal` — Precio al que se vendio.
- `+ getCostoUnitario(): Decimal?` — Costo con que se vendio, o nulo.
- `+ calcularUnidades(): Decimal` — Information Expert: unidades vendidas, |getCantidad()|; la salida guarda la cantidad en negativo (RF-11, DA-72).
- `+ calcularMargen(): Decimal?` — Information Expert: (getPrecioUnitario() - getCostoUnitario()) x calcularUnidades(); null si getCostoUnitario() es null, porque el dato esta incompleto (RF-08, ERS 3.2.4, DA-61, DA-72).
- `+ SalidaVenta(id: String, item: ItemInventario, cantidad: Decimal, fecha: DateTime, venta: Venta, precioUnitario: Decimal, costoUnitario: Decimal?)`

Relaciones: Aggregation → `Venta` [1] (composición)

### `UnidadMedida` (enum)

> Unidad en que se vende el producto; KILOGRAMO y LIBRA admiten decimales (IE-01 b).

Valores: `UNIDAD`, `KILOGRAMO`, `LIBRA`

### `VentaPerdida` (class)

> Venta que no se realizo porque el producto estaba agotado, con su fecha (RF-12). Es un registro que solo se agrega: el numero de ventas perdidas de un periodo se obtiene contando los registros, asi dos dispositivos sin conexion no se pisan (DA-48, DA-50). Traza a Venta perdida.

Atributos:
- `- id: String` — Identificador unico (UUID) generado en el dispositivo al crear el objeto, para guardarlo, relacionarlo y sincronizarlo sin conexion (RNF-08, RD-12, DA-43).
- `- producto: Producto`
- `- fecha: DateTime` — Fecha y hora en que el cliente pidio el producto agotado.

Operaciones:
- `+ VentaPerdida(id: String, producto: Producto, fecha: DateTime)`
- `+ getId(): String` — Identificador unico del objeto (DA-43).
- `+ getFecha(): DateTime` — Fecha de la venta perdida.

Relaciones: Association → `Producto` [1]

## Entidades/InfoTienda

### `Administrador` (class) extends Usuario

> Propietario: hereda lo del empleado y accede a reportes y caja (actor Propietario, RNF-12).

Operaciones:
- `+ Administrador(id: String, nombre: String, cedula: String)`

### `ConflictoSincronizacion` (class)

> Choque detectado al sincronizar que solo una persona puede decidir; se guarda y se muestra al propietario. Su id es determinista (tipo + registros) para que dos dispositivos no creen el mismo conflicto dos veces (DA-48).

Atributos:
- `- id: String`
- `- tipo: TipoConflicto`
- `- descripcion: String`
- `- idsRegistros: List<String>`
- `- fecha: DateTime`
- `- resuelto: bool`

Operaciones:
- `+ ConflictoSincronizacion(id: String, tipo: TipoConflicto, descripcion: String, idsRegistros: List<String>, fecha: DateTime)` — Constructor: recibe sus dependencias o datos.
- `+ getId(): String` — Identificador del conflicto.
- `+ getTipo(): TipoConflicto` — Tipo de choque.
- `+ getDescripcion(): String` — Explicacion en el lenguaje del tendero (RNF-25).
- `+ getIdsRegistros(): List<String>` — Ids de los registros involucrados.
- `+ getFecha(): DateTime` — Fecha en que se detecto.
- `+ isResuelto(): bool` — Verdadero si el propietario ya lo resolvio.
- `+ setResuelto(resuelto: bool): void` — Lo llama ServicioConciliacion.resolverConflicto.

Relaciones: Dependency → `TipoConflicto`

### `DatosExportacion` (class)

> Datos del negocio que se exportan (CUS-16, RNF-22): inventario con su stock, ventas del periodo y fiados con sus abonos. No se guarda: la arma ServicioExportacion y la recibe IExportador (DA-68).

Atributos:
- `- fecha: DateTime`
- `- desde: DateTime`
- `- hasta: DateTime`
- `- formato: FormatoExportacion`
- `- items: List<ItemInventario>`
- `- ventas: List<Venta>`
- `- fiados: List<Fiado>`

Operaciones:
- `+ DatosExportacion(fecha: DateTime, desde: DateTime, hasta: DateTime, formato: FormatoExportacion, items: List<ItemInventario>, ventas: List<Venta>, fiados: List<Fiado>)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ getFecha(): DateTime` — Fecha y hora en que se genero.
- `+ getDesde(): DateTime` — Inicio del periodo de las ventas.
- `+ getHasta(): DateTime` — Fin del periodo de las ventas.
- `+ getFormato(): FormatoExportacion` — CSV o EXCEL.
- `+ getItems(): List<ItemInventario>` — Inventario: cada item con su producto y su stock.
- `+ getVentas(): List<Venta>` — Ventas del periodo con sus formas de pago y su anulacion, si la tienen.
- `+ getFiados(): List<Fiado>` — Fiados de la tienda con sus abonos.

Relaciones: Association → `ItemInventario` [0..*]; Association → `Venta` [0..*]; Association → `Fiado` [0..*]; Dependency → `FormatoExportacion`

### `Empleado` (class) extends Usuario

> Usuario que atiende el mostrador (actor Empleado).

Operaciones:
- `+ Empleado(id: String, nombre: String, cedula: String)`

### `FormatoExportacion` (enum)

> Formato del archivo exportado (RNF-22).

Valores: `CSV`, `EXCEL`

### `Tienda` (class)

> Identifica la tienda; los repositorios la reciben como parametro para aislar los datos (RNF-13, DA-28). Ningun caso de uso la edita (DA-65). Traza a Tienda.

Atributos:
- `- codigo: String`
- `- direccion: String`
- `- nombre: String`

Operaciones:
- `+ getCodigo(): String` — Codigo de la tienda; con el se aislan sus datos (RNF-13).
- `+ getDireccion(): String` — Direccion de la tienda.
- `+ getNombre(): String` — Nombre de la tienda.
- `+ Tienda(codigo: String, nombre: String, direccion: String)` — Constructor: la tienda se registra fuera de la Business Layer (alta en Supabase); aqui solo se lee.

### `TipoConflicto` (enum)

> Tipos de choque que requieren revision del propietario (DA-48).

Valores: `STOCK_NEGATIVO`, `ABONO_EXCEDE_SALDO`, `CODIGO_REPETIDO`, `POSIBLE_DUPLICADO`, `MOVIMIENTO_CAJA_CERRADA`

### `Usuario` (class)

> Usuario del sistema; su rol es la subclase (Empleado o Administrador), RNF-12. Se crea y se desactiva en CUS-15; no se borra. Traza a Tendero y Administrador.

Atributos:
- `- id: String` — Identificador unico (UUID) generado en el dispositivo al crear el objeto, para guardarlo, relacionarlo y sincronizarlo sin conexion (RNF-08, RD-12, DA-43).
- `- nombre: String`
- `- cedula: String`
- `- activo: bool` — Falso si el propietario lo desactivo; un usuario inactivo no puede entrar (CUS-15).

Operaciones:
- `+ getNombre(): String` — Dato del usuario; no se edita (CUS-15 solo crea y desactiva).
- `+ Usuario(id: String, nombre: String, cedula: String)`
- `+ getCedula(): String` — Dato del usuario; no se edita (CUS-15 solo crea y desactiva).
- `+ isActivo(): bool` — Verdadero si puede usar el sistema.
- `+ desactivar(): void` — Information Expert: rechaza si ya esta inactivo; si no, queda inactivo.
- `+ getId(): String` — Identificador unico del objeto (DA-43).

## Entidades/Pagos

### `Abono` (class)

> Pago parcial o total de un fiado, en efectivo o por Nequi. No tiene cambio: un abono mayor al saldo se rechaza (IE-06). Traza a Abono.

Atributos:
- `- id: String` — Identificador unico (UUID) generado en el dispositivo al crear el objeto, para guardarlo, relacionarlo y sincronizarlo sin conexion (RNF-08, RD-12, DA-43).
- `- fecha: DateTime`
- `- monto: Decimal`
- `- medio: MedioPago` — EFECTIVO o NEQUI (DA-64).
- `- referencia: String?` — Numero de la transaccion de Nequi; nulo si fue en efectivo.
- `- anulado: bool` — Verdadero si el propietario lo anulo al resolver un conflicto ABONO_EXCEDE_SALDO (DA-66).

Operaciones:
- `+ Abono(id: String, monto: Decimal, fecha: DateTime, medio: MedioPago, referencia: String?)`
- `+ getMedio(): MedioPago` — Medio con que se pago.
- `+ getReferencia(): String?` — Referencia de Nequi, o nula.
- `+ esEfectivo(): bool` — Information Expert: verdadero si medio es EFECTIVO; solo esos abonos entran a la caja.
- `+ anular(): void` — Information Expert: rechaza si ya esta anulado; si no, queda anulado.
- `+ isAnulado(): bool` — Verdadero si fue anulado.
- `+ getId(): String` — Identificador unico del objeto (DA-43).

Relaciones: Aggregation → `Fiado` [1] (composición); Dependency → `MedioPago`

### `AnulacionVenta` (class)

> Registro de la anulacion de una venta: quien, cuando y por que (RNF-15). Solo se agrega: la venta no se borra ni cambia sus datos (DA-48, DA-51).

Atributos:
- `- id: String`
- `- usuario: Usuario`
- `- fecha: DateTime`
- `- motivo: String`

Operaciones:
- `+ AnulacionVenta(id: String, usuario: Usuario, fecha: DateTime, motivo: String)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ getId(): String` — Identificador unico del objeto (DA-43).
- `+ getUsuario(): Usuario` — Propietario que anulo la venta (RNF-15).
- `+ getFecha(): DateTime` — Fecha y hora de la anulacion (RNF-15).
- `+ getMotivo(): String` — Motivo que escribio el propietario.

Relaciones: Aggregation → `Venta` [1] (composición); Association → `Usuario` [1]

### `Cliente` (class)

> Cliente de la tienda que puede tener fiados; solo nombre y telefono (RNF-16). No se edita: se registra y se elimina cuando ya no debe (DA-59). Traza a Cliente.

Atributos:
- `- id: String` — Identificador unico (UUID) generado en el dispositivo al crear el objeto, para guardarlo, relacionarlo y sincronizarlo sin conexion (RNF-08, RD-12, DA-43).
- `- nombre: String`
- `- telefono: String`
- `- fiados: List<Fiado>`

Operaciones:
- `+ Cliente(id: String, nombre: String, telefono: String)`
- `+ obtenerFiadosPendientes(): List<Fiado>` — Information Expert: fiados en estado PENDIENTE (CUR-07, CUR-08).
- `+ calcularSaldoPendiente(): Decimal` — Information Expert: suma getSaldoPendiente() de cada fiado de obtenerFiadosPendientes() (CUS-19, DA-69).
- `+ obtenerHistorial(): List<Fiado>` — Information Expert: sus fiados del mas reciente al mas antiguo, cada uno con sus abonos (CUS-19, DA-69).
- `+ puedeEliminarse(): bool` — Information Expert: verdadero si no tiene fiados pendientes (CUR-08 7b, CUS-21, DA-69).
- `+ agregarFiado(fiado: Fiado): void` — Information Expert: agrega el fiado a su lista; asi la lista no se modifica desde afuera (encapsulamiento).
- `+ getId(): String` — Identificador unico del objeto (DA-43).

Relaciones: Association → `Fiado` [0..*]

### `EstadoFiado` (enum)

> Estado del fiado: PENDIENTE, SALDADO o ANULADO (la venta que lo origino se anulo; DA-51).

Valores: `PENDIENTE`, `SALDADO`, `ANULADO`

### `Fiado` (class) extends FormaPago

> Venta a credito con su saldo pendiente; es una forma de pago de la venta (DA-04, DA-20). Traza a Fiado.

Atributos:
- `- abonos: List<Abono>`
- `- estado: EstadoFiado`
- `- fechaInicio: DateTime`
- `- montoInicial: Decimal`
- `- saldoPendiente: Decimal`
- `- cliente: Cliente`

Operaciones:
- `+ Fiado(id: String, montoInicial: Decimal, fecha: DateTime, cliente: Cliente)`
- `+ registrarAbono(abono: Abono): Abono` — Information Expert: agrega el abono a su lista, baja el saldo y pasa a SALDADO si llega a cero (RN-05).
- `+ getCliente(): Cliente` — Cliente que debe el fiado.
- `+ recalcularSaldo(): void` — Saldo = monto inicial - suma de sus abonos no anulados; estado SALDADO si llega a cero; si esta ANULADO el saldo queda en cero. Se usa al conciliar (Information Expert, DA-30, DA-48, DA-66).
- `+ anular(): void` — Information Expert: rechaza si ya tiene abonos; si no, saldo cero y estado ANULADO (DA-51).
- `+ calcularMontoCubierto(): Decimal` — Devuelve getMontoInicial(): lo que la venta quedo debiendo (DA-72).

Relaciones: Dependency → `EstadoFiado`

### `FormaPago` (abstract class)

> Forma de pago de una venta: contado, Nequi o fiado; una venta tiene de una a tres, sin repetir tipo. Polymorphism y Protected Variations (DA-20, DA-63).

Atributos:
- `- id: String` — Identificador unico (UUID) generado en el dispositivo al crear el objeto, para guardarlo, relacionarlo y sincronizarlo sin conexion (RNF-08, RD-12, DA-43).

Operaciones:
- `+ FormaPago(id: String)`
- `+ getId(): String` — Identificador unico del objeto (DA-43).
- `+ calcularMontoCubierto(): Decimal` — Polymorphism e Information Expert: parte del total de la venta que cubre esta forma de pago; cada subclase la calcula con sus propios datos (DA-72).

Relaciones: Aggregation → `Venta` [1] (composición)

### `LineaVenta` (class)

> Entidad de negocio: una linea de la venta en curso (item y cantidad). Las lineas de la venta en curso forman una List que conserva la pantalla. No se guarda; al confirmar cada linea se convierte en una SalidaVenta (DA-27, DA-40, DA-57).

Atributos:
- `- item: ItemInventario`
- `- cantidad: Decimal`

Operaciones:
- `+ LineaVenta(item: ItemInventario, cantidad: Decimal)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ getItem(): ItemInventario` — Item del producto vendido.
- `+ getCantidad(): Decimal` — Cantidad pedida, positiva.
- `+ setCantidad(cantidad: Decimal): void` — Cambia la cantidad antes de confirmar.
- `+ calcularSubtotal(): Decimal` — Information Expert: cantidad x item.getProducto().getPrecioVenta(), con el precio actual porque la venta aun no se confirma (DA-61).

Relaciones: Association → `ItemInventario` [1]

### `MedioPago` (enum)

> Medio con que se recibe un abono: EFECTIVO entra a la caja; NEQUI llega a la cuenta Nequi y no mueve la caja (DA-64).

Valores: `EFECTIVO`, `NEQUI`

### `PagoContado` (class) extends FormaPago

> Pago de contado.

Atributos:
- `- montoRecibido: Decimal`
- `- cambio: Decimal`

Operaciones:
- `+ PagoContado(id: String, montoRecibido: Decimal, cambio: Decimal)`
- `+ calcularMontoCubierto(): Decimal` — Devuelve getMontoRecibido() - getCambio(): lo que queda en caja (DA-72).

### `PagoNequi` (class) extends FormaPago

> Pago por Nequi (transferencia): el dinero llega a la cuenta Nequi de la tienda, no al efectivo de la caja (DA-63).

Atributos:
- `- monto: Decimal`
- `- referencia: String?`

Operaciones:
- `+ PagoNequi(id: String, monto: Decimal, referencia: String?)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ getMonto(): Decimal` — Monto pagado por Nequi.
- `+ getReferencia(): String?` — Numero de la transaccion que muestra Nequi, para cruzarlo con la app; puede quedar vacio.
- `+ calcularMontoCubierto(): Decimal` — Devuelve getMonto() (DA-72).

### `Venta` (class)

> Venta del mostrador con sus formas de pago; se crea al confirmar (DA-27). Sus salidas de inventario son partes de la venta (composicion): no existen sin ella; la navegacion va de la salida a la venta y se guardan con IMovimientoInventarioRepositorio (DA-60). Traza a Venta.

Atributos:
- `- id: String` — Identificador unico (UUID) generado en el dispositivo al crear el objeto, para guardarlo, relacionarlo y sincronizarlo sin conexion (RNF-08, RD-12, DA-43).
- `- fecha: DateTime`
- `- formasPago: List<FormaPago>`
- `- total: Decimal`
- `- anulacion: AnulacionVenta?` — Anulacion de la venta, o null si esta vigente (RNF-15).

Operaciones:
- `+ getTotal(): Decimal` — Total de la venta; lo calcula ServicioVentas.calcularTotal y llega en el constructor.
- `+ Venta(id: String, formasPago: List<FormaPago>, total: Decimal, fecha: DateTime)`
- `+ getId(): String` — Identificador unico del objeto (DA-43).
- `+ anular(anulacion: AnulacionVenta): void` — Information Expert: rechaza si ya esta anulada y guarda la anulacion; la venta no se borra (RNF-15).
- `+ isAnulada(): bool` — Verdadero si tiene anulacion.
- `+ getAnulacion(): AnulacionVenta?` — Anulacion de la venta, o null.

## Interfaces

### `IUnidadTrabajo` (interface)

> Unidad de trabajo: ejecuta varias operaciones de distintos repositorios como una sola transaccion; si una falla, no se guarda ninguna (RNF-04, DA-44). Si ya hay una transaccion abierta, la accion se une a ella: no abre otra ni guarda por separado (DA-53). La Data Layer la implementa (con drift, db.transaction).

Operaciones:
- `+ ejecutar(accion: Function): void` — Ejecuta la accion dentro de una transaccion: todo se guarda o nada se guarda. Si se llama dentro de otra ejecucion (por ejemplo aplicarMovimiento dentro de confirmar), se une a la transaccion de afuera.

## Interfaces/GestionCaja

### `ICajaRepositorio` (interface)

> Indirection, Protected Variations y DIP: contrato de acceso a datos; la Data Layer lo implementa (cache local o servidor, RNF-08).

Operaciones:
- `+ buscarPorFecha(tienda: Tienda, fecha: DateTime): Caja?` — Caja de la jornada con sus movimientos, o null si todavia no se ha abierto.
- `+ crear(tienda: Tienda, caja: Caja): void` — Inserta la caja si su id no existe (dos dispositivos pueden abrir la misma caja sin conexion).
- `+ registrarMovimiento(tienda: Tienda, caja: Caja, movimiento: MovimientoCaja): void` — Inserta solo el movimiento nuevo; nunca reescribe la caja ni los demas movimientos (DA-48, DA-62).
- `+ cerrar(tienda: Tienda, caja: Caja): void` — Guarda solo el cierre: cerrada, efectivoContado, diferencia y fechaCierre (RF-13).
- `+ listarMovimientos(tienda: Tienda, desde: DateTime, hasta: DateTime): List<MovimientoCaja>` — Movimientos de caja del periodo (RF-10).
- `+ buscarPorId(tienda: Tienda, id: String): Caja?` — Caja con sus movimientos, o null.

## Interfaces/GestionInventario

### `IAlertaRepositorio` (interface)

> Indirection, Protected Variations y DIP: contrato de acceso a datos; la Data Layer lo implementa (cache local o servidor, RNF-08).

Operaciones:
- `+ reemplazar(tienda: Tienda, fecha: DateTime, alertas: List<AlertaReabastecimiento>): void` — Guarda las alertas del dia y descarta las anteriores de esa fecha (RD-11).
- `+ listarPorFecha(tienda: Tienda, fecha: DateTime): List<AlertaReabastecimiento>` — Alertas ya calculadas; lectura rapida del panel (RD-09).

### `IImpresionEtiquetas` (interface)

> Protected Variations: genera el PDF de etiquetas y lo envia a imprimir. La implementacion (paquetes pdf, printing y barcode de Flutter) va fuera de la Business Layer.

Operaciones:
- `+ imprimir(etiquetas: List<Etiqueta>): void` — Arma las etiquetas en hojas adhesivas tamano carta y abre la impresion; no requiere hardware especial.

### `IInventarioRepositorio` (interface)

> Indirection, Protected Variations y DIP: contrato de acceso a datos; la Data Layer lo implementa (cache local o servidor, RNF-08).

Operaciones:
- `+ buscarItem(tienda: Tienda, producto: Producto): ItemInventario?` — Item de inventario del producto en la tienda.
- `+ listarItems(tienda: Tienda): List<ItemInventario>` — Items de la tienda con su producto, ordenados por nombre; los usan el panel de existencias, las alertas, la rotacion y la exportacion.
- `+ guardarItem(tienda: Tienda, item: ItemInventario): void` — Crea o actualiza el item.

### `IMovimientoInventarioRepositorio` (interface)

> Indirection, Protected Variations y DIP: contrato de acceso a datos; la Data Layer lo implementa (cache local o servidor, RNF-08).

Operaciones:
- `+ guardar(tienda: Tienda, movimiento: MovimientoInventario): void` — Agrega el movimiento al historial; nunca lo modifica (RF-01 a RF-04).
- `+ listarPorItem(item: ItemInventario, desde: DateTime, hasta: DateTime): List<MovimientoInventario>` — Historial de un item en un periodo, del mas reciente al mas antiguo; lo usan el panel de existencias y recalcularStock.
- `+ listarSalidas(item: ItemInventario, desde: DateTime, hasta: DateTime): List<SalidaVenta>` — Salidas VIGENTES por venta de un item; base del consumo promedio (RF-05). Las de ventas anuladas no cuentan.
- `+ listarSalidasPorVenta(venta: Venta): List<SalidaVenta>` — Salidas de una venta, con su item; las usa la anulacion.
- `+ listarPorTienda(tienda: Tienda, desde: DateTime, hasta: DateTime): List<MovimientoInventario>` — Todos los movimientos de la tienda en el periodo, en cualquier estado; los usa la conciliacion.
- `+ listarSalidasPorTienda(tienda: Tienda, desde: DateTime, hasta: DateTime): List<SalidaVenta>` — Salidas VIGENTES de la tienda en el periodo, con su item, producto, precio y costo; las usan los reportes (RF-08, RF-09, RF-11).
- `+ listarEntradasPorTienda(tienda: Tienda, desde: DateTime, hasta: DateTime): List<EntradaMercancia>` — Entradas VIGENTES de la tienda en el periodo; las usa el reporte diario (RF-09).
- `+ buscarUltimaEntrada(item: ItemInventario): EntradaMercancia?` — Ultima entrada del item; permite comparar el costo (IE-02).
- `+ actualizarEstado(tienda: Tienda, movimiento: MovimientoInventario): void` — Guarda el nuevo estado del movimiento (EN_REVISION, VIGENTE o ANULADO).
- `+ buscarPorIds(tienda: Tienda, ids: List<String>): List<MovimientoInventario>` — Movimientos con esos ids, con su item; los usa la resolucion de conflictos.

### `IProductoRepositorio` (interface)

> Indirection, Protected Variations y DIP: contrato de acceso a datos; la Data Layer lo implementa (cache local o servidor, RNF-08).

Operaciones:
- `+ buscarPorNombre(tienda: Tienda, texto: String): List<Producto>` — Coincidencia parcial sobre el nombre normalizado (sin mayusculas ni tildes) que guarda la base de datos (RF-06, RD-08).
- `+ buscarPorCodigo(tienda: Tienda, codigo: String): Producto?` — Producto por su codigo interno; se usa para validar que no se repita al crearlo.
- `+ buscarPorCodigoProducto(tienda: Tienda, valor: String): Producto?` — Producto que tiene asociado ese codigo (de barras o QR); compara el texto exacto de la lectura.
- `+ listar(tienda: Tienda): List<Producto>` — Catalogo de la tienda ordenado por nombre (RNF-13).
- `+ guardar(tienda: Tienda, producto: Producto): void` — Crea o actualiza el producto, identificado por su id, con sus codigos (de barras o QR).
- `+ listarCodigosRepetidos(tienda: Tienda): List<CodigoProducto>` — Codigos cuyo valor quedo asociado a mas de un producto de la tienda al sincronizar.
- `+ buscarPorId(tienda: Tienda, id: String): Producto?` — Producto con sus codigos, o null.

### `IVentaPerdidaRepositorio` (interface)

> Indirection, Protected Variations y DIP: contrato de acceso a datos; la Data Layer lo implementa (cache local o servidor, RNF-08).

Operaciones:
- `+ buscarPorPeriodo(tienda: Tienda, desde: DateTime, hasta: DateTime): List<VentaPerdida>` — Ventas perdidas de la tienda entre las dos fechas; las muestra el panel de alertas (RF-12).
- `+ listarPorProducto(producto: Producto, desde: DateTime, hasta: DateTime): List<VentaPerdida>` — Ventas perdidas de un producto entre las dos fechas; alimentan el consumo promedio (RF-12).
- `+ guardar(tienda: Tienda, ventaPerdida: VentaPerdida): void` — Inserta la venta perdida con su fecha; nunca modifica las anteriores (DA-48, DA-50).

## Interfaces/InfoTienda

### `IConflictoRepositorio` (interface)

> Indirection, Protected Variations y DIP: contrato de acceso a datos; la Data Layer lo implementa (cache local o servidor, RNF-08).

Operaciones:
- `+ guardar(tienda: Tienda, conflicto: ConflictoSincronizacion): void` — Inserta el conflicto si su id no existe (dos dispositivos pueden detectar el mismo).
- `+ listarPendientes(tienda: Tienda): List<ConflictoSincronizacion>` — Conflictos sin resolver de la tienda.
- `+ marcarResuelto(tienda: Tienda, conflicto: ConflictoSincronizacion): void` — Guarda que el conflicto fue resuelto.

### `IEstadoSincronizacion` (interface)

> Protected Variations: la Business Layer pregunta si quedan datos sin enviar al servidor sin conocer al Sincronizador de la Data Layer, que lo implementa (ERS 3.2.5 c, DA-62).

Operaciones:
- `+ hayPendientes(tienda: Tienda): bool` — Verdadero si hay operaciones de la tienda guardadas en el dispositivo que aun no se han enviado al servidor (ERS 3.2.5 c).

### `IExportador` (interface)

> Protected Variations: genera el archivo CSV o Excel con los datos exportados y lo entrega al usuario para guardarlo o compartirlo (RNF-22). Lo implementa la Data Layer con paquetes de Flutter (csv, excel, share_plus); la Business Layer no sabe como se escribe el archivo (DA-68).

Operaciones:
- `+ exportar(datos: DatosExportacion): String` — Escribe el archivo en el formato de datos.getFormato(): una hoja o archivo para inventario, otro para ventas y otro para fiados; devuelve el nombre del archivo generado.

### `IUsuarioRepositorio` (interface)

> Indirection, Protected Variations y DIP: contrato de acceso a datos; la Data Layer lo implementa (cache local o servidor, RNF-08).

Operaciones:
- `+ listar(tienda: Tienda): List<Usuario>` — Usuarios de la tienda, activos e inactivos.
- `+ buscarPorCedula(tienda: Tienda, cedula: String): Usuario?` — Usuario de la tienda con esa cedula, o null.
- `+ guardar(tienda: Tienda, usuario: Usuario): void` — Crea o actualiza el usuario (nombre, cedula, rol y activo).

## Interfaces/Pagos

### `IClienteRepositorio` (interface)

> Indirection, Protected Variations y DIP: contrato de acceso a datos; la Data Layer lo implementa (cache local o servidor, RNF-08).

Operaciones:
- `+ buscarPorNombre(tienda: Tienda, texto: String): List<Cliente>` — Clientes de la tienda que coinciden con el nombre, cada uno con sus fiados y los abonos de cada fiado, para que cliente.obtenerFiadosPendientes() funcione.
- `+ guardar(tienda: Tienda, cliente: Cliente): void` — Crea o actualiza el cliente (RNF-16).
- `+ eliminar(tienda: Tienda, cliente: Cliente): void` — Elimina el cliente cuando no tiene fiados pendientes.

### `IFiadoRepositorio` (interface)

> Indirection, Protected Variations y DIP: contrato de acceso a datos; la Data Layer lo implementa (cache local o servidor, RNF-08).

Operaciones:
- `+ crear(tienda: Tienda, fiado: Fiado): void` — Inserta el fiado nuevo (sin abonos) cuando se confirma una venta fiada (CUR-07).
- `+ registrarAbono(tienda: Tienda, fiado: Fiado, abono: Abono): void` — Inserta solo el abono nuevo y actualiza solo el saldo y el estado del fiado, en una transaccion (CUR-08, RNF-04, DA-46).
- `+ listar(tienda: Tienda): List<Fiado>` — Todos los fiados de la tienda, pendientes y saldados, del mas reciente al mas antiguo.
- `+ buscarPorNombreCliente(tienda: Tienda, texto: String): List<Fiado>` — Fiados cuyo cliente coincide con el texto: coincidencia parcial, sin distinguir mayusculas ni tildes (RD-08).
- `+ listarAbonos(tienda: Tienda, desde: DateTime, hasta: DateTime): List<Abono>` — Abonos del periodo; los usa el reporte diario.
- `+ listarModificadosDesde(tienda: Tienda, desde: DateTime): List<Fiado>` — Fiados con abonos o cambios recibidos desde esa fecha; los revisa la conciliacion.
- `+ actualizarSaldo(tienda: Tienda, fiado: Fiado): void` — Guarda el saldo y el estado recalculados del fiado.
- `+ buscarPorId(tienda: Tienda, id: String): Fiado?` — Fiado con sus abonos, o null.
- `+ anularAbono(tienda: Tienda, fiado: Fiado, abono: Abono): void` — Guarda solo que el abono quedo anulado (DA-66).

### `IVentaRepositorio` (interface)

> Indirection, Protected Variations y DIP: contrato de acceso a datos; la Data Layer lo implementa (cache local o servidor, RNF-08).

Operaciones:
- `+ guardar(tienda: Tienda, venta: Venta): void` — Guarda la venta con sus formas de pago en la misma transaccion que sus salidas (RNF-04).
- `+ listarPorPeriodo(tienda: Tienda, desde: DateTime, hasta: DateTime): List<Venta>` — Ventas del periodo con sus formas de pago (el fiado con sus abonos) y su anulacion, si la tiene (RF-08, RF-09, RF-11). Lo usan los reportes y la exportacion (RNF-22).
- `+ registrarAnulacion(tienda: Tienda, venta: Venta, anulacion: AnulacionVenta): void` — Inserta la anulacion de la venta; la venta no se modifica (RNF-15, DA-48).

## Componentes/GestionCaja

### `ServicioCaja` (class)

> Pure Fabrication de la caja: abre la caja del dia, crea los movimientos y cierra la caja; las cuentas las hace Caja (Information Expert) (CUR-11, CUR-14, RF-10, RF-13).

Atributos:
- `- cajas: ICajaRepositorio`

Operaciones:
- `+ ServicioCaja(cajas: ICajaRepositorio)` — Constructor: recibe sus dependencias o datos (DIP).
- `- obtenerCajaDelDia(tienda: Tienda, fecha: DateTime): Caja` — Creator: busca la caja con cajas.buscarPorFecha(tienda, fecha); si no existe, crea la Caja con id = tienda + fecha y la guarda con cajas.crear. La usan registrarMovimiento, consultarSaldoEsperado y cerrarCaja.
- `+ registrarMovimiento(tienda: Tienda, tipo: TipoMovimientoCaja, clasificacion: ClasificacionMovimiento, valor: Decimal, descripcion: String): MovimientoCaja` — Valida valor > 0, obtiene la caja con obtenerCajaDelDia(tienda, hoy), crea el MovimientoCaja, llama a caja.registrarMovimiento (rechaza si esta cerrada) y lo guarda con cajas.registrarMovimiento(tienda, caja, movimiento) (RF-10). La llaman registrarMovimientoManual, registrarIngreso y ProcesadorPagoContado.revertir.
- `+ registrarMovimientoManual(tienda: Tienda, tipo: TipoMovimientoCaja, clasificacion: ClasificacionMovimiento, valor: Decimal, descripcion: String): MovimientoCaja` — Movimiento que registra el propietario (CUR-11, RF-10): rechaza la clasificacion ANULACION, que solo usa la anulacion de ventas, y llama a registrarMovimiento.
- `+ registrarIngreso(tienda: Tienda, valor: Decimal, descripcion: String): MovimientoCaja` — Ingreso del NEGOCIO: llama a registrarMovimiento(tienda, INGRESO, NEGOCIO, valor, descripcion). La llaman ProcesadorPagoContado.procesar (venta de contado) y ServicioAbonos.registrarAbono (solo abonos en efectivo).
- `+ consultarSaldoEsperado(tienda: Tienda): Decimal` — Obtiene la caja de hoy con obtenerCajaDelDia y devuelve caja.calcularSaldoEsperado().
- `+ cerrarCaja(tienda: Tienda, efectivoContado: Decimal): Decimal` — Obtiene la caja de hoy con obtenerCajaDelDia, llama a caja.cerrar(efectivoContado), guarda el cierre con cajas.cerrar(tienda, caja) y devuelve el faltante o sobrante (RF-13).

Relaciones: Association → `ICajaRepositorio` [1]; Dependency → `Caja`; Dependency → `MovimientoCaja`

### `ServicioReportes` (class)

> Pure Fabrication: consolida ventas, salidas, entradas, abonos y caja en reportes (CUR-09, CUR-10, CUR-12). No calcula montos por su cuenta: los pide a quien tiene los datos (SalidaVenta.calcularMargen, EntradaMercancia.calcularCostoTotal, FormaPago.calcularMontoCubierto), con el precio y el costo guardados en cada SalidaVenta (DA-61, DA-72).

Atributos:
- `- ventas: IVentaRepositorio`
- `- movimientos: IMovimientoInventarioRepositorio`
- `- cajas: ICajaRepositorio`
- `- fiados: IFiadoRepositorio`
- `- estadoSincronizacion: IEstadoSincronizacion`
- `- items: IInventarioRepositorio`

Operaciones:
- `+ ServicioReportes(ventas: IVentaRepositorio, movimientos: IMovimientoInventarioRepositorio, cajas: ICajaRepositorio, fiados: IFiadoRepositorio, estadoSincronizacion: IEstadoSincronizacion, items: IInventarioRepositorio)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ generarReporteDiario(tienda: Tienda, fecha: DateTime): ReporteDiario` — Creator de ReporteDiario (RF-09, RF-10, IE-08, ERS 3.2.5). Con desde y hasta = inicio y fin de fecha: 1) ventas.listarPorPeriodo(tienda, desde, hasta), sin las que venta.isAnulada(): totalVentas = suma de venta.getTotal(); por cada forma de venta.getFormasPago(), si forma is Fiado suma forma.calcularMontoCubierto() a ventasFiadas y si forma is PagoNequi a ventasNequi. 2) movimientos.listarSalidasPorTienda(tienda, desde, hasta): margen = suma de salida.calcularMargen(); incompleto si alguna devuelve null. 3) movimientos.listarEntradasPorTienda(tienda, desde, hasta): totalEntradas = suma de entrada.calcularCostoTotal(). 4) fiados.listarAbonos(tienda, desde, hasta), sin los que abono.isAnulado(): abonosRecibidos = suma de abono.getMonto(); abonosNequi = la suma de los que abono.getMedio() es NEQUI. 5) cajas.listarMovimientos(tienda, desde, hasta), solo los egresos (mov.esIngreso() falso): gastosNegocio = suma de mov.getValor() de los que mov.esDelNegocio(); retirosPersonales = suma de los que mov.getClasificacion() es PERSONAL; los de ANULACION no suman a ninguno. 6) utilidad = margen - gastosNegocio; parcial = estadoSincronizacion.hayPendientes(tienda). Crea el ReporteDiario con esos valores; quedan en cero si no hubo movimientos (DA-72).
- `+ calcularMargenes(tienda: Tienda, desde: DateTime, hasta: DateTime): Map<Producto, Decimal?>` — Llama a movimientos.listarSalidasPorTienda(tienda, desde, hasta), agrupa las salidas por salida.getItem().getProducto() y suma salida.calcularMargen() (RF-08). Si alguna salida del producto devuelve null, el valor del producto es null: dato incompleto (ERS 3.2.4, DA-61, DA-72).
- `+ clasificarRotacion(tienda: Tienda, desde: DateTime, hasta: DateTime): Map<Producto, Rotacion>` — Llama a items.listarItems(tienda) para tener todos los productos en cero y a movimientos.listarSalidasPorTienda(tienda, desde, hasta); suma salida.calcularUnidades() en el producto de salida.getItem().getProducto(). Ordena de mayor a menor: el tercio que mas vende es ALTA, el del medio MEDIA y el resto BAJA; los que no vendieron quedan en BAJA (RF-11, DA-62, DA-72).

Relaciones: Association → `IVentaRepositorio` [1]; Association → `IMovimientoInventarioRepositorio` [1]; Association → `ICajaRepositorio` [1]; Association → `IFiadoRepositorio` [1]; Dependency → `ReporteDiario`; Dependency → `Rotacion`; Association → `IEstadoSincronizacion` [1]; Association → `IInventarioRepositorio` [1]

## Componentes/GestionInventario

### `ConsumoPromedioSimple` (class) implements EstrategiaConsumo

> Primera estrategia: unidades vendidas mas ventas perdidas, dividido entre los dias con datos.

Operaciones:
- `+ ConsumoPromedioSimple()` — Constructor: recibe sus dependencias o datos (DIP).
- `+ calcularConsumoDiario(salidas: List<SalidaVenta>, perdidas: List<VentaPerdida>, dias: int): Decimal` — Suma las unidades vendidas (valor absoluto de cada salida) mas una unidad por cada venta perdida y divide entre los dias.

### `EstrategiaConsumo` (interface)

> Protected Variations: el calculo del consumo promedio debe poder ajustarse hasta cumplir el 70 % de RNF-01 sin tocar ServicioAlertas.

Operaciones:
- `+ calcularConsumoDiario(salidas: List<SalidaVenta>, perdidas: List<VentaPerdida>, dias: int): Decimal` — Consumo promedio diario; excluye los dias sin sincronizar (ERS 3.2.2 c).

### `InterpreteCodigo` (interface)

> Polymorphism y Protected Variations: cada tipo de codigo se interpreta distinto (RF-06). La lectura llega como texto, venga del lector 2D o de la camara (respaldo); un formato nuevo es una clase nueva (OCP, DA-47).

Operaciones:
- `+ reconoce(lectura: String): bool` — Indica si la lectura tiene el formato que este interprete entiende.
- `+ buscar(tienda: Tienda, lectura: String): Producto?` — Producto asociado a la lectura, o null si no existe.
- `+ formatoDe(lectura: String): FormatoCodigo` — Deduce el formato del texto leido; el lector 2D en modo teclado solo entrega texto (DA-47).

### `InterpreteCodigoBarras` (class) implements InterpreteCodigo

> Codigos EAN-13, EAN-8 y UPC-A: valida el digito de control y busca con buscarPorCodigoProducto.

Atributos:
- `- productos: IProductoRepositorio`

Operaciones:
- `+ InterpreteCodigoBarras(productos: IProductoRepositorio)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ reconoce(lectura: String): bool` — 8, 12 o 13 digitos con digito de control valido.
- `+ buscar(tienda: Tienda, lectura: String): Producto?` — Llama a productos.buscarPorCodigoProducto(tienda, lectura).
- `+ formatoDe(lectura: String): FormatoCodigo` — 13 digitos -> EAN13, 8 -> EAN8, 12 -> UPCA (con digito de control valido).

Relaciones: Association → `IProductoRepositorio` [1]

### `InterpreteCodigoQR` (class) implements InterpreteCodigo

> Codigos QR (del sistema 'GIP:' o de fabrica): busca su texto exacto con buscarPorCodigoProducto (DA-41). Va de ultimo en ServicioCatalogo.interpretes porque reconoce cualquier texto que no sea un EAN o UPC valido.

Atributos:
- `- productos: IProductoRepositorio`

Operaciones:
- `+ InterpreteCodigoQR(productos: IProductoRepositorio)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ reconoce(lectura: String): bool` — La lectura no es un EAN o UPC valido; se trata como texto de QR.
- `+ buscar(tienda: Tienda, lectura: String): Producto?` — Llama a productos.buscarPorCodigoProducto(tienda, lectura), sin quitar prefijos.
- `+ formatoDe(lectura: String): FormatoCodigo` — Devuelve QR.

Relaciones: Association → `IProductoRepositorio` [1]

### `ServicioAlertas` (class)

> Pure Fabrication e Information Expert de la demanda: calcula y guarda las alertas de su tienda una vez al dia dentro de la app (CUR-05, RF-05, RD-11, DA-35) y registra ventas perdidas (CUR-13, RF-12).

Atributos:
- `- items: IInventarioRepositorio`
- `- movimientos: IMovimientoInventarioRepositorio`
- `- ventasPerdidas: IVentaPerdidaRepositorio`
- `- alertas: IAlertaRepositorio`
- `- estrategiaConsumo: EstrategiaConsumo`
- `- umbralDiasCobertura: int`

Operaciones:
- `+ ServicioAlertas(items: IInventarioRepositorio, movimientos: IMovimientoInventarioRepositorio, ventasPerdidas: IVentaPerdidaRepositorio, alertas: IAlertaRepositorio, estrategiaConsumo: EstrategiaConsumo, umbralDiasCobertura: int)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ generarAlertas(tienda: Tienda, fecha: DateTime): List<AlertaReabastecimiento>` — Llama a items.listarItems(tienda); por cada item llama a evaluarItem(item, fecha) y guarda las alertas resultantes con alertas.reemplazar(tienda, fecha, alertas) (RD-11, DA-35). La invoca GenerarAlertasDiariasCoordinator una vez al dia, despues de sincronizar.
- `- evaluarItem(item: ItemInventario, fecha: DateTime): AlertaReabastecimiento?` — Llama a movimientos.listarSalidas(item, fecha - 30 dias, fecha), a ventasPerdidas.listarPorProducto(item.getProducto(), fecha - 30 dias, fecha) y a estrategiaConsumo.calcularConsumoDiario(salidas, perdidas, dias con datos del periodo) (ERS 3.2.2 c). Si el consumo es cero no hay alerta; si no, diasCobertura = stock / consumo y crea la AlertaReabastecimiento cuando es menor que umbralDiasCobertura. Provisional si hay menos de 30 dias de historico (RNF-03); guarda la existencia del momento (RNF-02).
- `+ obtenerAlertas(tienda: Tienda, fecha: DateTime): List<AlertaReabastecimiento>` — Llama a alertas.listarPorFecha(tienda, fecha) (RD-09).
- `+ obtenerVentasPerdidas(tienda: Tienda, desde: DateTime, hasta: DateTime): List<VentaPerdida>` — Ventas perdidas de la tienda en el periodo; delega en ventasPerdidas.buscarPorPeriodo.
- `+ registrarVentaPerdida(tienda: Tienda, producto: Producto): VentaPerdida` — Creator: crea la VentaPerdida con la fecha y hora actual y la inserta con ventasPerdidas.guardar (RF-12); no modifica registros anteriores (DA-50).

Relaciones: Association → `IInventarioRepositorio` [1]; Association → `IMovimientoInventarioRepositorio` [1]; Association → `IVentaPerdidaRepositorio` [1]; Association → `IAlertaRepositorio` [1]; Association → `EstrategiaConsumo` [1]; Dependency → `AlertaReabastecimiento`; Dependency → `VentaPerdida`

### `ServicioCatalogo` (class)

> Pure Fabrication e Information Expert del catalogo: busqueda por nombre o por codigo y creacion de productos (CUR-06, RF-06).

Atributos:
- `- productos: IProductoRepositorio`
- `- interpretes: List<InterpreteCodigo>` — En orden: InterpreteCodigoBarras antes que InterpreteCodigoQR. QR va de ultimo porque reconoce cualquier texto que no sea un EAN o UPC valido.
- `- servicioInventario: ServicioInventario`
- `- impresion: IImpresionEtiquetas`
- `- unidadTrabajo: IUnidadTrabajo`

Operaciones:
- `+ ServicioCatalogo(productos: IProductoRepositorio, interpretes: List<InterpreteCodigo>, servicioInventario: ServicioInventario, impresion: IImpresionEtiquetas, unidadTrabajo: IUnidadTrabajo)` — Constructor: recibe sus dependencias (DIP). La lista interpretes llega en orden: InterpreteCodigoBarras primero e InterpreteCodigoQR de ultimo.
- `+ buscarPorNombre(tienda: Tienda, texto: String): List<Producto>` — Delega en productos.buscarPorNombre; la coincidencia sin tildes ni mayusculas la resuelve el repositorio (RD-08).
- `+ buscarPorLectura(tienda: Tienda, lectura: String): Producto?` — Recorre interpretes en orden; el primero cuyo reconoce(lectura) es verdadero llama a buscar(tienda, lectura) y se devuelve su resultado, o null si no hay producto (Polymorphism, RF-06).
- `+ listarProductos(tienda: Tienda): List<Producto>` — Catalogo completo de la tienda; delega en productos.listar.
- `+ crearProducto(tienda: Tienda, codigo: String, nombre: String, unidad: UnidadMedida, precioCompra: Decimal?, precioVenta: Decimal): Producto` — Creator: valida que el codigo no exista con productos.buscarPorCodigo, nombre no vacio y precioVenta >= 0 y precioCompra >= 0 si viene (puede ser nulo); crea el Producto con id nuevo y, dentro de unidadTrabajo.ejecutar, lo guarda con productos.guardar y llama a servicioInventario.crearItem(tienda, producto) para su item con stock cero (RNF-04).
- `+ editarProducto(tienda: Tienda, producto: Producto, nombre: String, unidad: UnidadMedida, precioCompra: Decimal?, precioVenta: Decimal): void` — Valida nombre no vacio y precioVenta >= 0 y precioCompra >= 0 si viene (puede ser nulo), cambia los datos con los set de Producto, asigna actualizadoEn y guarda con productos.guardar; el codigo interno no se edita (DA-48, DA-50).
- `+ asociarCodigo(tienda: Tienda, producto: Producto, valor: String): CodigoProducto` — Rechaza si productos.buscarPorCodigoProducto(tienda, valor) devuelve otro producto; deduce el formato con formatoDe del primer interprete que reconoce el valor, crea el CodigoProducto, lo asocia con producto.agregarCodigo y guarda con productos.guardar(tienda, producto) (DA-41, DA-47).
- `+ generarEtiquetas(tienda: Tienda, productos: List<Producto>, copias: int): List<Etiqueta>` — Creator: crea una Etiqueta por copia con un codigo del producto. Si el producto no tiene codigos, crea un CodigoProducto QR con 'GIP:' + codigo y lo asocia con producto.agregarCodigo; esos productos se guardan con productos.guardar dentro de unidadTrabajo.ejecutar (DA-41, RNF-04).
- `+ imprimirEtiquetas(tienda: Tienda, productos: List<Producto>, copias: int): void` — Llama a generarEtiquetas(tienda, productos, copias) y envia el resultado a impresion.imprimir(etiquetas).

Relaciones: Association → `IProductoRepositorio` [1]; Association → `InterpreteCodigo` [1..*]; Association → `ServicioInventario` [1]; Dependency → `Producto`; Dependency → `CodigoProducto`; Association → `IImpresionEtiquetas` [1]; Dependency → `Etiqueta`; Association → `IUnidadTrabajo` [1]

### `ServicioInventario` (class)

> Pure Fabrication e Information Expert del stock: crea los movimientos y mantiene el stock con stock nuevo = stock anterior + cantidad con signo (ERS 3.2.1).

Atributos:
- `- items: IInventarioRepositorio`
- `- movimientos: IMovimientoInventarioRepositorio`
- `- umbralRevisionConteo: Decimal`
- `- unidadTrabajo: IUnidadTrabajo`

Operaciones:
- `+ ServicioInventario(items: IInventarioRepositorio, movimientos: IMovimientoInventarioRepositorio, umbralRevisionConteo: Decimal, unidadTrabajo: IUnidadTrabajo)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ crearItem(tienda: Tienda, producto: Producto): ItemInventario` — Creator: crea el ItemInventario con id nuevo y stock cero y lo guarda con items.guardarItem(tienda, item). Lo llama ServicioCatalogo.crearProducto dentro de su transaccion.
- `+ obtenerItem(tienda: Tienda, producto: Producto): ItemInventario` — Llama a items.buscarItem(tienda, producto); rechaza si el producto no tiene item.
- `+ listarExistencias(tienda: Tienda): List<ItemInventario>` — Productos con su stock: delega en items.listarItems; cada item trae su producto (item.getProducto()).
- `+ consultarMovimientos(tienda: Tienda, producto: Producto, desde: DateTime, hasta: DateTime): List<MovimientoInventario>` — Historial del producto: busca su item con items.buscarItem y devuelve movimientos.listarPorItem (entradas, salidas, mermas y ajustes).
- `+ hayExistencia(item: ItemInventario, cantidad: Decimal): bool` — Verdadero si el stock alcanza (RN-01).
- `+ registrarEntrada(tienda: Tienda, producto: Producto, cantidad: Decimal, costoUnitario: Decimal, numeroFactura: String?): EntradaMercancia` — Valida cantidad > 0 y costo >= 0, obtiene el item con obtenerItem, crea la EntradaMercancia con id nuevo, cantidad positiva, costo y factura, y la aplica con aplicarMovimiento(tienda, entrada) (RF-01).
- `+ costoDifiereDelHistorico(tienda: Tienda, producto: Producto, costoUnitario: Decimal): bool` — Obtiene el item con obtenerItem y compara costoUnitario con el de movimientos.buscarUltimaEntrada(item); advertencia que no bloquea (IE-02).
- `+ registrarMerma(tienda: Tienda, producto: Producto, cantidad: Decimal, motivo: MotivoMerma): Merma` — Valida cantidad > 0 y motivo, obtiene el item con obtenerItem, crea la Merma con id nuevo y cantidad negativa, y la aplica con aplicarMovimiento(tienda, merma) (RF-03).
- `+ calcularDiferencia(tienda: Tienda, producto: Producto, cantidadContada: Decimal): Decimal` — Obtiene el item con obtenerItem y devuelve cantidadContada - item.getStockActual() (IE-04). La usan RegistrarConteoCoordinator y registrarConteo.
- `+ requiereRevision(diferencia: Decimal): bool` — Verdadero si el valor absoluto de la diferencia supera umbralRevisionConteo (IE-04 b).
- `+ registrarConteo(tienda: Tienda, producto: Producto, cantidadContada: Decimal): AjusteConteo` — Valida cantidadContada >= 0 (IE-04 b), calcula la diferencia con calcularDiferencia(tienda, producto, cantidadContada), crea el AjusteConteo con la diferencia como cantidad y lo aplica con aplicarMovimiento; prevalece lo contado (RF-04).
- `+ aplicarMovimiento(tienda: Tienda, movimiento: MovimientoInventario): void` — Dentro de unidadTrabajo.ejecutar: guarda el movimiento con movimientos.guardar y el nuevo stock con items.guardarItem; bloquea si el stock queda negativo (ERS 3.2.1 a, RNF-04).
- `+ anularMovimiento(tienda: Tienda, movimiento: MovimientoInventario): void` — Dentro de unidadTrabajo.ejecutar: marca el movimiento ANULADO, devuelve su efecto al stock (stock nuevo = stock actual - cantidad) y guarda con movimientos.actualizarEstado e items.guardarItem; rechaza si el stock queda negativo.
- `+ anularSalidas(tienda: Tienda, venta: Venta): void` — Busca las salidas con movimientos.listarSalidasPorVenta(venta) y llama a anularMovimiento por cada una: el stock vuelve.
- `+ recalcularStock(tienda: Tienda, item: ItemInventario): Decimal` — Suma los movimientos VIGENTES que devuelve movimientos.listarPorItem para todo el historial del item, asigna el resultado con item.setStockActual y lo guarda con items.guardarItem(tienda, item); devuelve el stock. La usa ServicioConciliacion despues de sincronizar (ERS 3.2.1 c, DA-48).

Relaciones: Association → `IInventarioRepositorio` [1]; Association → `IMovimientoInventarioRepositorio` [1]; Dependency → `ItemInventario`; Dependency → `EntradaMercancia`; Dependency → `Merma`; Dependency → `AjusteConteo`; Association → `IUnidadTrabajo` [1]

## Componentes/InfoTienda

### `ResolutorAbonoExcedido` (class) implements ResolutorConflicto

> Resuelve ABONO_EXCEDE_SALDO anulando los abonos que sobran y devolviendo el dinero (DA-66).

Atributos:
- `- fiados: IFiadoRepositorio`
- `- servicioCaja: ServicioCaja`

Operaciones:
- `+ ResolutorAbonoExcedido(fiados: IFiadoRepositorio, servicioCaja: ServicioCaja)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ admite(conflicto: ConflictoSincronizacion): bool` — Verdadero si el tipo es ABONO_EXCEDE_SALDO.
- `+ resolver(tienda: Tienda, conflicto: ConflictoSincronizacion, idsElegidos: List<String>): void` — Busca el fiado con fiados.buscarPorId; por cada abono de idsElegidos llama a abono.anular() y fiados.anularAbono, y si abono.esEfectivo() a servicioCaja.registrarMovimiento(tienda, EGRESO, ANULACION, monto, 'Devolucion abono'); al final fiado.recalcularSaldo() y fiados.actualizarSaldo. Por Nequi la devolucion se hace fuera del sistema.

Relaciones: Association → `IFiadoRepositorio` [1]; Association → `ServicioCaja` [1]

### `ResolutorCajaCerrada` (class) implements ResolutorConflicto

> Resuelve MOVIMIENTO_CAJA_CERRADA: el movimiento se acepta en su caja y se recalcula la diferencia del cierre (DA-66).

Atributos:
- `- cajas: ICajaRepositorio`

Operaciones:
- `+ ResolutorCajaCerrada(cajas: ICajaRepositorio)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ admite(conflicto: ConflictoSincronizacion): bool` — Verdadero si el tipo es MOVIMIENTO_CAJA_CERRADA.
- `+ resolver(tienda: Tienda, conflicto: ConflictoSincronizacion, idsElegidos: List<String>): void` — Busca la caja con cajas.buscarPorId(tienda, primer id del conflicto), llama a caja.recalcularDiferencia() y guarda con cajas.cerrar(tienda, caja). idsElegidos no se usa: el dinero registrado no se pierde.

Relaciones: Association → `ICajaRepositorio` [1]

### `ResolutorCodigoRepetido` (class) implements ResolutorConflicto

> Resuelve CODIGO_REPETIDO: el propietario escoge que productos pierden el codigo repetido (DA-66).

Atributos:
- `- productos: IProductoRepositorio`

Operaciones:
- `+ ResolutorCodigoRepetido(productos: IProductoRepositorio)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ admite(conflicto: ConflictoSincronizacion): bool` — Verdadero si el tipo es CODIGO_REPETIDO.
- `+ resolver(tienda: Tienda, conflicto: ConflictoSincronizacion, idsElegidos: List<String>): void` — Por cada producto de idsElegidos (productos.buscarPorId): si comparte un codigo de barras o QR, llama a producto.quitarCodigo(codigo); si comparte el codigo interno, llama a producto.cambiarCodigoInterno(codigo + '-' + n); guarda con productos.guardar.

Relaciones: Association → `IProductoRepositorio` [1]

### `ResolutorConflicto` (interface)

> Polymorphism y Protected Variations: cada tipo de conflicto se resuelve a su manera. Un tipo nuevo es una clase nueva, sin modificar ServicioConciliacion (OCP, DA-66).

Operaciones:
- `+ admite(conflicto: ConflictoSincronizacion): bool` — Indica si este resolutor atiende ese tipo de conflicto.
- `+ resolver(tienda: Tienda, conflicto: ConflictoSincronizacion, idsElegidos: List<String>): void` — Aplica la decision del propietario; idsElegidos son los registros que el propietario escogio (puede ir vacio).

### `ResolutorMovimientos` (class) implements ResolutorConflicto

> Resuelve POSIBLE_DUPLICADO y STOCK_NEGATIVO anulando movimientos de inventario (DA-66).

Atributos:
- `- movimientos: IMovimientoInventarioRepositorio`
- `- servicioInventario: ServicioInventario`

Operaciones:
- `+ ResolutorMovimientos(movimientos: IMovimientoInventarioRepositorio, servicioInventario: ServicioInventario)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ admite(conflicto: ConflictoSincronizacion): bool` — Verdadero si el tipo es POSIBLE_DUPLICADO o STOCK_NEGATIVO.
- `+ resolver(tienda: Tienda, conflicto: ConflictoSincronizacion, idsElegidos: List<String>): void` — Con movimientos.buscarPorIds(tienda, conflicto.getIdsRegistros()) marca ANULADO los de idsElegidos y VIGENTE los demas (setEstado y movimientos.actualizarEstado), y llama a servicioInventario.recalcularStock(tienda, item) por cada item afectado. Si idsElegidos va vacio no anula nada: el propietario corrige con un conteo (CUR-04).

Relaciones: Association → `IMovimientoInventarioRepositorio` [1]; Association → `ServicioInventario` [1]

### `ServicioAcceso` (class)

> Pure Fabrication: concentra el control de acceso por rol (RNF-12) para que ningun coordinator lo repita (DRY).

Operaciones:
- `+ ServicioAcceso()` — Constructor: no tiene dependencias.
- `- esPropietario(usuario: Usuario): bool` — Verdadero si usuario is Administrador (propietario).
- `+ exigirPropietario(usuario: Usuario): void` — Llama a esPropietario(usuario) y rechaza la operacion si es falso (RNF-12). La usan los coordinadores de los casos del propietario.

### `ServicioConciliacion` (class)

> Pure Fabrication e Information Expert de la conciliacion: despues de sincronizar recalcula stock y saldos de fiados a partir de los registros y detecta los choques que debe decidir el propietario (RNF-08, ERS 3.2.1 c, DA-48). El saldo de caja no se recalcula: Caja lo calcula de sus movimientos (DA-62).

Atributos:
- `- conflictos: IConflictoRepositorio`
- `- movimientos: IMovimientoInventarioRepositorio`
- `- fiados: IFiadoRepositorio`
- `- cajas: ICajaRepositorio`
- `- productos: IProductoRepositorio`
- `- servicioInventario: ServicioInventario`
- `- unidadTrabajo: IUnidadTrabajo`
- `- resolutores: List<ResolutorConflicto>`

Operaciones:
- `+ ServicioConciliacion(conflictos: IConflictoRepositorio, movimientos: IMovimientoInventarioRepositorio, fiados: IFiadoRepositorio, cajas: ICajaRepositorio, productos: IProductoRepositorio, servicioInventario: ServicioInventario, unidadTrabajo: IUnidadTrabajo, resolutores: List<ResolutorConflicto>)` — Constructor: recibe sus dependencias (DIP). resolutores = [ResolutorMovimientos, ResolutorAbonoExcedido, ResolutorCodigoRepetido, ResolutorCajaCerrada].
- `+ conciliar(tienda: Tienda, desde: DateTime): List<ConflictoSincronizacion>` — Dentro de unidadTrabajo.ejecutar llama, en este orden, a detectarPosiblesDuplicados, detectarStockNegativo, detectarAbonosExcedidos, detectarCodigosRepetidos y detectarMovimientosCajaCerrada; guarda cada conflicto con conflictos.guardar (ignora los que ya existen, porque su id es determinista) y devuelve los nuevos (DA-48).
- `+ obtenerConflictos(tienda: Tienda): List<ConflictoSincronizacion>` — Llama a conflictos.listarPendientes(tienda).
- `+ resolverConflicto(tienda: Tienda, conflicto: ConflictoSincronizacion, idsElegidos: List<String>): void` — Dentro de unidadTrabajo.ejecutar llama a resolutorPara(conflicto).resolver(tienda, conflicto, idsElegidos), luego a conflicto.setResuelto(true) y a conflictos.marcarResuelto(tienda, conflicto) (DA-66).
- `- resolutorPara(conflicto: ConflictoSincronizacion): ResolutorConflicto` — Recorre resolutores y devuelve el primero cuyo admite(conflicto) es verdadero; rechaza si ninguno lo admite (Polymorphism).
- `- detectarPosiblesDuplicados(tienda: Tienda, desde: DateTime): List<ConflictoSincronizacion>` — Llama a movimientos.listarPorTienda(tienda, desde, ahora); si dos EntradaMercancia tienen el mismo item, cantidad y numeroFactura, deja la segunda EN_REVISION con movimiento.setEstado y movimientos.actualizarEstado, y crea un conflicto POSIBLE_DUPLICADO con los dos ids.
- `- detectarStockNegativo(tienda: Tienda, desde: DateTime): List<ConflictoSincronizacion>` — Por cada item con movimientos recibidos desde esa fecha (movimientos.listarPorTienda) llama a servicioInventario.recalcularStock(tienda, item) y crea un conflicto STOCK_NEGATIVO por cada uno que quede negativo.
- `- detectarAbonosExcedidos(tienda: Tienda, desde: DateTime): List<ConflictoSincronizacion>` — Llama a fiados.listarModificadosDesde(tienda, desde); por cada fiado llama a fiado.recalcularSaldo() y lo guarda con fiados.actualizarSaldo(tienda, fiado); crea un conflicto ABONO_EXCEDE_SALDO con ids [fiado, abonos] si el saldo queda negativo (DA-48).
- `- detectarCodigosRepetidos(tienda: Tienda): List<ConflictoSincronizacion>` — Llama a productos.listarCodigosRepetidos(tienda) (un codigo de barras o QR en dos productos) y revisa productos.listar(tienda) en busca de codigos internos repetidos; crea un conflicto CODIGO_REPETIDO con los ids de los productos por cada caso (DA-48, DA-59).
- `- detectarMovimientosCajaCerrada(tienda: Tienda, desde: DateTime): List<ConflictoSincronizacion>` — Llama a cajas.listarMovimientos(tienda, desde, ahora) y, por cada movimiento, a cajas.buscarPorFecha(tienda, fecha del movimiento); crea un conflicto MOVIMIENTO_CAJA_CERRADA con ids [caja, movimiento] si la caja tiene fechaCierre anterior a la fecha del movimiento (DA-48).

Relaciones: Association → `IConflictoRepositorio` [1]; Association → `IMovimientoInventarioRepositorio` [1]; Association → `IFiadoRepositorio` [1]; Association → `ICajaRepositorio` [1]; Association → `IProductoRepositorio` [1]; Association → `IUnidadTrabajo` [1]; Association → `ServicioInventario` [1]; Dependency → `ConflictoSincronizacion`; Association → `ResolutorConflicto` [1..*]

### `ServicioExportacion` (class)

> Pure Fabrication y Creator de la exportacion (CUS-16, RNF-22): reune los datos del negocio y se los entrega a IExportador (DA-68).

Atributos:
- `- items: IInventarioRepositorio`
- `- ventas: IVentaRepositorio`
- `- fiados: IFiadoRepositorio`
- `- exportador: IExportador`

Operaciones:
- `+ ServicioExportacion(items: IInventarioRepositorio, ventas: IVentaRepositorio, fiados: IFiadoRepositorio, exportador: IExportador)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ exportar(tienda: Tienda, desde: DateTime, hasta: DateTime, formato: FormatoExportacion): String` — Valida desde <= hasta; crea DatosExportacion con items.listarItems(tienda), ventas.listarPorPeriodo(tienda, desde, hasta) y fiados.listar(tienda), y llama a exportador.exportar(datos). Devuelve el nombre del archivo (RNF-22).

Relaciones: Association → `IInventarioRepositorio` [1]; Association → `IVentaRepositorio` [1]; Association → `IFiadoRepositorio` [1]; Association → `IExportador` [1]; Dependency → `DatosExportacion`

### `ServicioUsuarios` (class)

> Pure Fabrication de los usuarios de la tienda (CUS-15): lista, crea empleados y los desactiva. La cuenta de acceso (correo y contrasena) la maneja Supabase Auth, fuera de la Business Layer (DA-67).

Atributos:
- `- usuarios: IUsuarioRepositorio`

Operaciones:
- `+ ServicioUsuarios(usuarios: IUsuarioRepositorio)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ listar(tienda: Tienda): List<Usuario>` — Llama a usuarios.listar(tienda).
- `+ crearEmpleado(tienda: Tienda, nombre: String, cedula: String): Empleado` — Creator: valida nombre no vacio y que usuarios.buscarPorCedula(tienda, cedula) no devuelva a otro; crea el Empleado con id nuevo y activo, y lo guarda con usuarios.guardar.
- `+ desactivar(tienda: Tienda, usuario: Usuario): void` — Rechaza si usuario is Administrador (el propietario no se desactiva); si no, llama a usuario.desactivar() y guarda con usuarios.guardar. No se borra: sus ventas y anulaciones siguen apuntando a el (RNF-15).

Relaciones: Association → `IUsuarioRepositorio` [1]; Dependency → `Empleado`

## Componentes/Pagos

### `ProcesadorFiado` (class) implements ProcesadorPago

> Pago fiado: deja el saldo pendiente a nombre del cliente (RF-07, CUR-07).

Atributos:
- `- servicioFiados: ServicioFiados`

Operaciones:
- `+ ProcesadorFiado(servicioFiados: ServicioFiados)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ admite(forma: FormaPago): bool` — Verdadero si forma is Fiado.
- `+ procesar(tienda: Tienda, venta: Venta, forma: FormaPago): void` — Llama a servicioFiados.registrarFiado(tienda, forma as Fiado).
- `+ revertir(tienda: Tienda, venta: Venta, forma: FormaPago): void` — Llama a servicioFiados.anularFiado(tienda, forma as Fiado).

Relaciones: Association → `ServicioFiados` [1]; Dependency → `Fiado`

### `ProcesadorNequi` (class) implements ProcesadorPago

> Pago por Nequi: no mueve la caja, porque el dinero no entra al efectivo que se cuenta al cierre; por eso no hace falta otra caja (DA-63).

Operaciones:
- `+ ProcesadorNequi()` — Constructor: no tiene dependencias.
- `+ admite(forma: FormaPago): bool` — Verdadero si forma is PagoNequi.
- `+ procesar(tienda: Tienda, venta: Venta, forma: FormaPago): void` — No registra movimientos de caja: el pago queda guardado con la venta (ventas.guardar) y el reporte diario lo suma en ventasNequi.
- `+ revertir(tienda: Tienda, venta: Venta, forma: FormaPago): void` — No registra movimientos de caja: la devolucion se hace por Nequi, fuera del sistema; la anulacion queda en AnulacionVenta.

Relaciones: Dependency → `PagoNequi`

### `ProcesadorPago` (interface)

> Polymorphism y Protected Variations: cada forma de pago se procesa a su manera. Un pago nuevo (transferencia) es una clase nueva, sin modificar ServicioVentas (OCP).

Operaciones:
- `+ admite(forma: FormaPago): bool` — Indica si este procesador atiende esa forma de pago.
- `+ procesar(tienda: Tienda, venta: Venta, forma: FormaPago): void` — Aplica los efectos de la forma de pago al confirmar la venta. venta es el contexto de la operacion: el procesador de contado la usa para identificar en la caja de que venta viene el movimiento; los que no la necesitan la ignoran. Todas las implementaciones reciben los mismos parametros para que ServicioVentas las llame igual.
- `+ revertir(tienda: Tienda, venta: Venta, forma: FormaPago): void` — Deshace los efectos de la forma de pago al anular la venta. venta es el contexto de la operacion: el procesador de contado la usa para identificar en la caja de que venta viene el movimiento; los que no la necesitan la ignoran. Todas las implementaciones reciben los mismos parametros para que ServicioVentas las llame igual.

### `ProcesadorPagoContado` (class) implements ProcesadorPago

> Pago de contado: el dinero entra a la caja del negocio (RF-02, RF-10).

Atributos:
- `- servicioCaja: ServicioCaja`

Operaciones:
- `+ ProcesadorPagoContado(servicioCaja: ServicioCaja)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ admite(forma: FormaPago): bool` — Verdadero si forma is PagoContado.
- `+ procesar(tienda: Tienda, venta: Venta, forma: FormaPago): void` — Llama a servicioCaja.registrarIngreso(tienda, forma.calcularMontoCubierto(), 'Venta ' + venta.getId()): entra lo recibido menos el cambio.
- `+ revertir(tienda: Tienda, venta: Venta, forma: FormaPago): void` — Llama a servicioCaja.registrarMovimiento(tienda, EGRESO, ANULACION, forma.calcularMontoCubierto(), 'Anulacion venta ' + venta.getId()): el dinero sale de la caja de hoy.

Relaciones: Association → `ServicioCaja` [1]; Dependency → `PagoContado`

### `ServicioAbonos` (class)

> Pure Fabrication de los abonos (CUR-08, RNF-04): registra el pago de un fiado en efectivo o por Nequi y, si es en efectivo, el ingreso en la caja, todo en una transaccion. Es el unico que depende de la caja; solo cambia si cambian los medios de pago o la caja (High Cohesion, SRP, DA-69).

Atributos:
- `- fiados: IFiadoRepositorio`
- `- servicioCaja: ServicioCaja`
- `- unidadTrabajo: IUnidadTrabajo`

Operaciones:
- `+ ServicioAbonos(fiados: IFiadoRepositorio, servicioCaja: ServicioCaja, unidadTrabajo: IUnidadTrabajo)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ registrarAbono(tienda: Tienda, fiado: Fiado, monto: Decimal, medio: MedioPago, referencia: String?): Abono` — Valida monto > 0 y no mayor al saldo (IE-06) y crea el Abono con su medio; dentro de unidadTrabajo.ejecutar llama a fiado.registrarAbono (baja el saldo) y a fiados.registrarAbono(tienda, fiado, abono); si abono.esEfectivo() llama ademas a servicioCaja.registrarIngreso(tienda, monto, 'Abono'). Por Nequi no mueve la caja (RNF-04, DA-64).

Relaciones: Association → `ServicioCaja` [1]; Dependency → `Abono`; Association → `IUnidadTrabajo` [1]; Association → `IFiadoRepositorio` [1]

### `ServicioClientes` (class)

> Pure Fabrication de los clientes del fiado (CUS-19, CUS-21, RNF-16, RNF-26): los busca, los registra y los elimina; el saldo, el historial y si se puede eliminar los calcula Cliente (Information Expert). Solo cambia si cambian las reglas de los datos del cliente (High Cohesion, SRP, DA-69).

Atributos:
- `- clientes: IClienteRepositorio`

Operaciones:
- `+ ServicioClientes(clientes: IClienteRepositorio)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ buscarClientes(tienda: Tienda, nombre: String): List<Cliente>` — Llama a clientes.buscarPorNombre(tienda, nombre).
- `+ registrarCliente(tienda: Tienda, nombre: String, telefono: String): Cliente` — Creator: valida que el nombre no este vacio, crea el Cliente con id nuevo (solo nombre y telefono, RNF-16) y lo guarda con clientes.guardar(tienda, cliente).
- `+ consultarSaldoTotal(cliente: Cliente): Decimal` — Llama a cliente.calcularSaldoPendiente() (CUS-19).
- `+ obtenerHistorial(cliente: Cliente): List<Fiado>` — Llama a cliente.obtenerHistorial() (CUS-19).
- `+ eliminarCliente(tienda: Tienda, cliente: Cliente): void` — Elimina al cliente a solicitud del titular (CUS-21, RNF-16): rechaza si cliente.puedeEliminarse() es falso (tiene fiados pendientes) y, si no, llama a clientes.eliminar(tienda, cliente). Lo puede hacer el empleado, con confirmacion en la pantalla (RNF-26).

Relaciones: Association → `IClienteRepositorio` [1]; Dependency → `Cliente`

### `ServicioFiados` (class)

> Pure Fabrication y Creator del fiado como forma de pago (CUR-07, RF-07, RNF-15): lo crea, lo guarda cuando se confirma la venta, lo anula y lo consulta. No depende de la caja ni de los clientes; solo cambia si cambia el ciclo del credito (High Cohesion, SRP, DA-69).

Atributos:
- `- fiados: IFiadoRepositorio`

Operaciones:
- `+ ServicioFiados(fiados: IFiadoRepositorio)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ crearFiado(cliente: Cliente, monto: Decimal): Fiado` — Creator: valida monto > 0 (IE-06) y crea el Fiado con id nuevo, el monto como saldo y estado PENDIENTE. Queda en memoria hasta que se confirma la venta (CUR-07); se guarda con registrarFiado.
- `+ registrarFiado(tienda: Tienda, fiado: Fiado): void` — Llama a fiado.getCliente().agregarFiado(fiado) y lo inserta con fiados.crear(tienda, fiado). Lo invoca ProcesadorFiado.procesar dentro de la transaccion de ServicioVentas.confirmar.
- `+ anularFiado(tienda: Tienda, fiado: Fiado): void` — Llama a fiado.anular() (rechaza si ya tiene abonos) y guarda con fiados.actualizarSaldo(tienda, fiado). Lo invoca ProcesadorFiado.revertir.
- `+ listarFiados(tienda: Tienda): List<Fiado>` — Todos los fiados de la tienda; delega en fiados.listar.
- `+ buscarFiadosPorCliente(tienda: Tienda, nombre: String): List<Fiado>` — Fiados de los clientes que coinciden con el nombre; delega en fiados.buscarPorNombreCliente.

Relaciones: Association → `IFiadoRepositorio` [1]; Dependency → `Fiado`

### `ServicioVentas` (class)

> Pure Fabrication y Creator de la venta: crea las lineas y los pagos de contado, valida las formas de pago al confirmar, confirma y anula ventas (CUR-02, RF-02, RNF-15). No guarda estado: recibe las lineas de la venta (List) y las formas de pago en cada operacion (DA-54, DA-57).

Atributos:
- `- servicioInventario: ServicioInventario`
- `- procesadores: List<ProcesadorPago>`
- `- ventas: IVentaRepositorio`
- `- unidadTrabajo: IUnidadTrabajo`

Operaciones:
- `+ ServicioVentas(servicioInventario: ServicioInventario, procesadores: List<ProcesadorPago>, ventas: IVentaRepositorio, unidadTrabajo: IUnidadTrabajo)` — Constructor: recibe sus dependencias (DIP). procesadores = [ProcesadorPagoContado, ProcesadorNequi, ProcesadorFiado].
- `+ agregarLinea(tienda: Tienda, lineas: List<LineaVenta>, producto: Producto, cantidad: Decimal): LineaVenta` — Busca en lineas (List) una linea cuyo item sea del producto; si existe, llama a cambiarCantidad(linea, linea.getCantidad() + cantidad) y la devuelve. Si no, obtiene el item con servicioInventario.obtenerItem, verifica servicioInventario.hayExistencia(item, cantidad) (RN-01), crea la LineaVenta y la agrega a lineas.
- `+ cambiarCantidad(linea: LineaVenta, cantidad: Decimal): void` — Valida cantidad > 0 y servicioInventario.hayExistencia(linea.getItem(), cantidad) (RN-01); si alcanza llama a linea.setCantidad(cantidad), si no rechaza.
- `+ calcularTotal(lineas: List<LineaVenta>): Decimal` — Suma linea.calcularSubtotal() de cada LineaVenta de lineas.
- `+ crearPagoContado(montoACubrir: Decimal, montoRecibido: Decimal): PagoContado` — Creator: valida montoRecibido >= montoACubrir, calcula cambio = montoRecibido - montoACubrir y crea el PagoContado con id nuevo. No lo guarda: la pantalla lo entrega en confirmar.
- `+ crearPagoNequi(monto: Decimal, referencia: String?): PagoNequi` — Creator: valida monto > 0 y crea el PagoNequi con id nuevo. No lo guarda: la pantalla lo entrega en confirmar.
- `- validarFormasPago(formas: List<FormaPago>, total: Decimal): void` — De una a tres formas, sin repetir tipo, y la suma de f.calcularMontoCubierto() de cada forma igual al total (DA-20, DA-63, DA-72). La llama confirmar antes de guardar.
- `+ confirmar(tienda: Tienda, lineas: List<LineaVenta>, formas: List<FormaPago>): Venta` — Llama a validarFormasPago(formas, calcularTotal(lineas)) (DA-20); luego, dentro de unidadTrabajo.ejecutar, crea la Venta con formas y calcularTotal(lineas), la guarda con ventas.guardar, crea por cada LineaVenta de lineas una SalidaVenta negativa con el precioVenta y el precioCompra que tiene el producto en ese momento y la aplica con servicioInventario.aplicarMovimiento, y llama a procesadorPara(forma).procesar por cada forma de pago (RNF-04, DA-61).
- `+ listarVentas(tienda: Tienda, desde: DateTime, hasta: DateTime): List<Venta>` — Ventas del periodo con su estado; delega en ventas.listarPorPeriodo.
- `+ anular(tienda: Tienda, venta: Venta, motivo: String, usuario: Usuario): AnulacionVenta` — Creator de AnulacionVenta. Rechaza si venta.isAnulada(); dentro de unidadTrabajo.ejecutar llama a venta.anular(anulacion), ventas.registrarAnulacion(tienda, venta, anulacion), servicioInventario.anularSalidas(tienda, venta) y procesadorPara(forma).revertir(tienda, venta, forma) por cada forma de pago (RNF-15, RNF-04).
- `- procesadorPara(forma: FormaPago): ProcesadorPago` — Recorre procesadores y devuelve el primero cuyo admite(forma) es verdadero; rechaza si ninguno la admite (Polymorphism).

Relaciones: Association → `ServicioInventario` [1]; Association → `ProcesadorPago` [1..*]; Association → `IVentaRepositorio` [1]; Dependency → `Venta`; Dependency → `SalidaVenta`; Dependency → `PagoContado`; Dependency → `LineaVenta`; Association → `IUnidadTrabajo` [1]; Dependency → `AnulacionVenta`; Dependency → `PagoNequi`

## Workflow/GestionCaja

### `ConsultarMargenCoordinator` (class)

> Controller (caso de uso CUR-09): recibe las operaciones del sistema desde la presentacion y delega; no contiene reglas de negocio.

Atributos:
- `- servicioReportes: ServicioReportes`
- `- servicioAcceso: ServicioAcceso`

Operaciones:
- `+ ConsultarMargenCoordinator(servicioReportes: ServicioReportes, servicioAcceso: ServicioAcceso)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ consultarMargen(tienda: Tienda, desde: DateTime, hasta: DateTime, usuario: Usuario): Map<Producto, Decimal?>` — Llama a servicioAcceso.exigirPropietario(usuario) y luego a servicioReportes.calcularMargenes(tienda, desde, hasta); valor nulo = dato incompleto.

Relaciones: Association → `ServicioReportes` [1]; Association → `ServicioAcceso` [1]

### `ConsultarRotacionCoordinator` (class)

> Controller (caso de uso CUR-12): recibe las operaciones del sistema desde la presentacion y delega; no contiene reglas de negocio.

Atributos:
- `- servicioReportes: ServicioReportes`
- `- servicioAcceso: ServicioAcceso`

Operaciones:
- `+ ConsultarRotacionCoordinator(servicioReportes: ServicioReportes, servicioAcceso: ServicioAcceso)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ consultarRotacion(tienda: Tienda, desde: DateTime, hasta: DateTime, usuario: Usuario): Map<Producto, Rotacion>` — Llama a servicioAcceso.exigirPropietario(usuario) y luego a servicioReportes.clasificarRotacion(tienda, desde, hasta).

Relaciones: Association → `ServicioReportes` [1]; Association → `ServicioAcceso` [1]

### `GenerarReporteDiarioCoordinator` (class)

> Controller (caso de uso CUR-10): recibe las operaciones del sistema desde la presentacion y delega; no contiene reglas de negocio.

Atributos:
- `- servicioReportes: ServicioReportes`
- `- servicioAcceso: ServicioAcceso`

Operaciones:
- `+ GenerarReporteDiarioCoordinator(servicioReportes: ServicioReportes, servicioAcceso: ServicioAcceso)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ generarReporte(tienda: Tienda, fecha: DateTime, usuario: Usuario): ReporteDiario` — Llama a servicioAcceso.exigirPropietario(usuario) y luego a servicioReportes.generarReporteDiario(tienda, fecha) (RD-10: 5 s o menos).

Relaciones: Association → `ServicioReportes` [1]; Association → `ServicioAcceso` [1]

### `RegistrarCierreCajaCoordinator` (class)

> Controller (caso de uso CUR-14): recibe las operaciones del sistema desde la presentacion y delega; no contiene reglas de negocio.

Atributos:
- `- servicioCaja: ServicioCaja`
- `- servicioAcceso: ServicioAcceso`

Operaciones:
- `+ RegistrarCierreCajaCoordinator(servicioCaja: ServicioCaja, servicioAcceso: ServicioAcceso)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ consultarSaldoEsperado(tienda: Tienda, usuario: Usuario): Decimal` — Llama a servicioAcceso.exigirPropietario(usuario) y luego a servicioCaja.consultarSaldoEsperado(tienda).
- `+ cerrarCaja(tienda: Tienda, efectivoContado: Decimal, usuario: Usuario): Decimal` — Llama a servicioAcceso.exigirPropietario(usuario) y luego a servicioCaja.cerrarCaja(tienda, efectivoContado): devuelve el faltante o sobrante (RF-13).

Relaciones: Association → `ServicioCaja` [1]; Association → `ServicioAcceso` [1]

### `RegistrarMovimientoCajaCoordinator` (class)

> Controller (caso de uso CUR-11): recibe las operaciones del sistema desde la presentacion y delega; no contiene reglas de negocio.

Atributos:
- `- servicioCaja: ServicioCaja`
- `- servicioAcceso: ServicioAcceso`

Operaciones:
- `+ RegistrarMovimientoCajaCoordinator(servicioCaja: ServicioCaja, servicioAcceso: ServicioAcceso)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ registrarMovimiento(tienda: Tienda, tipo: TipoMovimientoCaja, clasificacion: ClasificacionMovimiento, valor: Decimal, descripcion: String, usuario: Usuario): MovimientoCaja` — Llama a servicioAcceso.exigirPropietario(usuario) y luego a servicioCaja.registrarMovimientoManual(tienda, tipo, clasificacion, valor, descripcion).

Relaciones: Association → `ServicioCaja` [1]; Association → `ServicioAcceso` [1]

## Workflow/GestionInventario

### `BuscarProductoCoordinator` (class)

> Controller (casos de uso CUR-06 y su extension CUS-17 Leer codigo de producto): busca por nombre o por lectura y lista el catalogo; delega en ServicioCatalogo. Lo usan tambien las pantallas de CUS-01, CUS-02, CUS-03 y CUS-04 («include»).

Atributos:
- `- servicioCatalogo: ServicioCatalogo`

Operaciones:
- `+ BuscarProductoCoordinator(servicioCatalogo: ServicioCatalogo)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ buscarPorNombre(tienda: Tienda, texto: String): List<Producto>` — Llama a servicioCatalogo.buscarPorNombre(tienda, texto) (RD-08: 1 s o menos).
- `+ buscarPorLectura(tienda: Tienda, lectura: String): Producto?` — Llama a servicioCatalogo.buscarPorLectura(tienda, lectura); la lectura viene del lector 2D o de la camara.
- `+ listarProductos(tienda: Tienda): List<Producto>` — Llama a servicioCatalogo.listarProductos(tienda).

Relaciones: Association → `ServicioCatalogo` [1]

### `ConsultarAlertasCoordinator` (class)

> Controller (caso de uso CUR-05): recibe las operaciones del sistema desde la presentacion y delega; no contiene reglas de negocio.

Atributos:
- `- servicioAlertas: ServicioAlertas`
- `- servicioAcceso: ServicioAcceso`

Operaciones:
- `+ ConsultarAlertasCoordinator(servicioAlertas: ServicioAlertas, servicioAcceso: ServicioAcceso)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ consultarAlertas(tienda: Tienda, fecha: DateTime, usuario: Usuario): List<AlertaReabastecimiento>` — Llama a servicioAcceso.exigirPropietario(usuario) y luego a servicioAlertas.obtenerAlertas(tienda, fecha) (RNF-02).
- `+ consultarVentasPerdidas(tienda: Tienda, desde: DateTime, hasta: DateTime, usuario: Usuario): List<VentaPerdida>` — Llama a servicioAcceso.exigirPropietario(usuario) y luego a servicioAlertas.obtenerVentasPerdidas(tienda, desde, hasta) (RF-12).

Relaciones: Association → `ServicioAlertas` [1]; Association → `ServicioAcceso` [1]

### `ConsultarExistenciasCoordinator` (class)

> Controller (caso de uso CUS-25 Consultar existencias, actor Empleado): muestra los productos con su stock y el historial de movimientos de cada uno (CUN-03, DA-50).

Atributos:
- `- servicioInventario: ServicioInventario`

Operaciones:
- `+ ConsultarExistenciasCoordinator(servicioInventario: ServicioInventario)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ listarExistencias(tienda: Tienda): List<ItemInventario>` — Llama a servicioInventario.listarExistencias(tienda).
- `+ consultarMovimientos(tienda: Tienda, producto: Producto, desde: DateTime, hasta: DateTime): List<MovimientoInventario>` — Llama a servicioInventario.consultarMovimientos(tienda, producto, desde, hasta).

Relaciones: Association → `ServicioInventario` [1]

### `GenerarAlertasDiariasCoordinator` (class)

> Controller (caso de uso CUS-24 Generar alertas diarias, proceso automatico sin actor): lo dispara la app una vez al dia, despues de sincronizar (RD-11, DA-35, DA-68).

Atributos:
- `- servicioAlertas: ServicioAlertas`

Operaciones:
- `+ GenerarAlertasDiariasCoordinator(servicioAlertas: ServicioAlertas)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ ejecutar(tienda: Tienda, fecha: DateTime): void` — Llama a servicioAlertas.generarAlertas(tienda, fecha). Lo dispara un temporizador o la primera apertura del dia, despues de sincronizar; IAlertaRepositorio.reemplazar evita duplicados si varios dispositivos lo ejecutan.

Relaciones: Association → `ServicioAlertas` [1]

### `GestionarProductoCoordinator` (class)

> Controller (caso de uso CUS-18, extiende a CUS-06): crear, editar, asociar codigos e imprimir etiquetas de un producto; delega en ServicioCatalogo, una llamada por operacion (DA-67).

Atributos:
- `- servicioCatalogo: ServicioCatalogo`

Operaciones:
- `+ GestionarProductoCoordinator(servicioCatalogo: ServicioCatalogo)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ crearProducto(tienda: Tienda, codigo: String, nombre: String, unidad: UnidadMedida, precioCompra: Decimal?, precioVenta: Decimal): Producto` — Llama a servicioCatalogo.crearProducto(tienda, codigo, nombre, unidad, precioCompra, precioVenta) (IE-05 g).
- `+ asociarCodigo(tienda: Tienda, producto: Producto, valor: String): CodigoProducto` — Llama a servicioCatalogo.asociarCodigo(tienda, producto, valor).
- `+ editarProducto(tienda: Tienda, producto: Producto, nombre: String, unidad: UnidadMedida, precioCompra: Decimal?, precioVenta: Decimal): void` — Llama a servicioCatalogo.editarProducto(tienda, producto, nombre, unidad, precioCompra, precioVenta).
- `+ imprimirEtiquetas(tienda: Tienda, productos: List<Producto>, copias: int): void` — Llama a servicioCatalogo.imprimirEtiquetas(tienda, productos, copias).

Relaciones: Association → `ServicioCatalogo` [1]

### `RegistrarConteoCoordinator` (class)

> Controller (caso de uso CUR-04): recibe las operaciones del sistema desde la presentacion y delega; no contiene reglas de negocio.

Atributos:
- `- servicioInventario: ServicioInventario`

Operaciones:
- `+ RegistrarConteoCoordinator(servicioInventario: ServicioInventario)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ listarExistencias(tienda: Tienda): List<ItemInventario>` — Llama a servicioInventario.listarExistencias(tienda): la pantalla muestra cada producto con un campo para la cantidad contada (IE-04 e).
- `+ calcularDiferencia(tienda: Tienda, producto: Producto, cantidadContada: Decimal): Decimal` — Llama a servicioInventario.calcularDiferencia(tienda, producto, cantidadContada) (IE-04).
- `+ requiereRevision(diferencia: Decimal): bool` — Devuelve servicioInventario.requiereRevision(diferencia).
- `+ confirmarAjuste(tienda: Tienda, producto: Producto, cantidadContada: Decimal): AjusteConteo` — Llama a servicioInventario.registrarConteo(tienda, producto, cantidadContada).

Relaciones: Association → `ServicioInventario` [1]

### `RegistrarEntradaMercanciaCoordinator` (class)

> Controller (caso de uso CUR-01): recibe las operaciones del sistema desde la presentacion y delega; no contiene reglas de negocio.

Atributos:
- `- servicioInventario: ServicioInventario`

Operaciones:
- `+ RegistrarEntradaMercanciaCoordinator(servicioInventario: ServicioInventario)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ verificarCosto(tienda: Tienda, producto: Producto, costoUnitario: Decimal): bool` — Llama a servicioInventario.costoDifiereDelHistorico(tienda, producto, costoUnitario).
- `+ registrarEntrada(tienda: Tienda, producto: Producto, cantidad: Decimal, costoUnitario: Decimal, numeroFactura: String?): EntradaMercancia` — Llama a servicioInventario.registrarEntrada(tienda, producto, cantidad, costoUnitario, numeroFactura) y devuelve la entrada; el nuevo stock se lee en entrada.getItem().

Relaciones: Association → `ServicioInventario` [1]

### `RegistrarPerdidaCoordinator` (class)

> Controller (caso de uso CUR-03 Registrar perdida o devolucion al proveedor): registra mermas por vencimiento, dano, devolucion al proveedor u otro motivo (RF-03, IE-03). La devolucion de un cliente no esta en el alcance (DA-67).

Atributos:
- `- servicioInventario: ServicioInventario`

Operaciones:
- `+ RegistrarPerdidaCoordinator(servicioInventario: ServicioInventario)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ registrarPerdida(tienda: Tienda, producto: Producto, cantidad: Decimal, motivo: MotivoMerma): Merma` — Llama a servicioInventario.registrarMerma(tienda, producto, cantidad, motivo).

Relaciones: Association → `ServicioInventario` [1]

### `RegistrarVentaPerdidaCoordinator` (class)

> Controller (caso de uso CUR-13): recibe las operaciones del sistema desde la presentacion y delega; no contiene reglas de negocio.

Atributos:
- `- servicioAlertas: ServicioAlertas`

Operaciones:
- `+ RegistrarVentaPerdidaCoordinator(servicioAlertas: ServicioAlertas)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ registrarVentaPerdida(tienda: Tienda, producto: Producto): VentaPerdida` — Llama a servicioAlertas.registrarVentaPerdida(tienda, producto).

Relaciones: Association → `ServicioAlertas` [1]

## Workflow/InfoTienda

### `ConciliarCoordinator` (class)

> Controller (caso de uso CUS-23 Conciliar datos sincronizados, proceso automatico sin actor): lo dispara la app al terminar cada sincronizacion (DA-48, DA-68).

Atributos:
- `- servicioConciliacion: ServicioConciliacion`

Operaciones:
- `+ ConciliarCoordinator(servicioConciliacion: ServicioConciliacion)` — Constructor: recibe sus dependencias o datos.
- `+ ejecutar(tienda: Tienda, desde: DateTime): List<ConflictoSincronizacion>` — Llama a servicioConciliacion.conciliar(tienda, desde) y devuelve los conflictos nuevos para el indicador de RNF-09. Lo llama la app al terminar cada sincronizacion.

Relaciones: Association → `ServicioConciliacion` [1]

### `ExportarDatosCoordinator` (class)

> Controller (caso de uso CUS-16 Exportar datos del negocio, actor Propietario): exporta inventario, ventas y fiados a CSV o Excel (RNF-22, DA-68).

Atributos:
- `- servicioExportacion: ServicioExportacion`
- `- servicioAcceso: ServicioAcceso`

Operaciones:
- `+ ExportarDatosCoordinator(servicioExportacion: ServicioExportacion, servicioAcceso: ServicioAcceso)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ exportar(tienda: Tienda, desde: DateTime, hasta: DateTime, formato: FormatoExportacion, usuario: Usuario): String` — Llama a servicioAcceso.exigirPropietario(usuario) y luego a servicioExportacion.exportar(tienda, desde, hasta, formato); devuelve el nombre del archivo para que la pantalla lo muestre o lo comparta.

Relaciones: Association → `ServicioExportacion` [1]; Association → `ServicioAcceso` [1]

### `GestionarUsuariosCoordinator` (class)

> Controller (caso de uso CUS-15, actor Propietario): lista, crea y desactiva empleados; delega en ServicioUsuarios (DA-67).

Atributos:
- `- servicioUsuarios: ServicioUsuarios`
- `- servicioAcceso: ServicioAcceso`

Operaciones:
- `+ GestionarUsuariosCoordinator(servicioUsuarios: ServicioUsuarios, servicioAcceso: ServicioAcceso)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ listarUsuarios(tienda: Tienda, usuario: Usuario): List<Usuario>` — Llama a servicioAcceso.exigirPropietario(usuario) y luego a servicioUsuarios.listar(tienda).
- `+ crearEmpleado(tienda: Tienda, nombre: String, cedula: String, usuario: Usuario): Empleado` — Llama a servicioAcceso.exigirPropietario(usuario) y luego a servicioUsuarios.crearEmpleado(tienda, nombre, cedula).
- `+ desactivarUsuario(tienda: Tienda, empleado: Usuario, usuario: Usuario): void` — Llama a servicioAcceso.exigirPropietario(usuario) y luego a servicioUsuarios.desactivar(tienda, empleado).

Relaciones: Association → `ServicioUsuarios` [1]; Association → `ServicioAcceso` [1]

### `RevisarConflictosCoordinator` (class)

> Controller (caso de uso CUS-22 Revisar conflictos de sincronizacion, actor Propietario): muestra los conflictos pendientes y aplica la decision del propietario (DA-48, DA-66).

Atributos:
- `- servicioConciliacion: ServicioConciliacion`
- `- servicioAcceso: ServicioAcceso`

Operaciones:
- `+ RevisarConflictosCoordinator(servicioConciliacion: ServicioConciliacion, servicioAcceso: ServicioAcceso)` — Constructor: recibe sus dependencias o datos.
- `+ consultarConflictos(tienda: Tienda, usuario: Usuario): List<ConflictoSincronizacion>` — Llama a servicioAcceso.exigirPropietario(usuario) y luego a servicioConciliacion.obtenerConflictos(tienda) (RNF-12).
- `+ resolver(tienda: Tienda, conflicto: ConflictoSincronizacion, idsElegidos: List<String>, usuario: Usuario): void` — Llama a servicioAcceso.exigirPropietario(usuario) y luego a servicioConciliacion.resolverConflicto(tienda, conflicto, idsElegidos).

Relaciones: Association → `ServicioConciliacion` [1]; Association → `ServicioAcceso` [1]

## Workflow/Pagos

### `AnularVentaCoordinator` (class)

> Controller (caso de uso CUS-20 Anular venta, actor Propietario; RNF-15, RNF-26, DA-51). La confirmacion explicita la pide la pantalla antes de llamar a anularVenta.

Atributos:
- `- servicioVentas: ServicioVentas`
- `- servicioAcceso: ServicioAcceso`

Operaciones:
- `+ AnularVentaCoordinator(servicioVentas: ServicioVentas, servicioAcceso: ServicioAcceso)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ listarVentas(tienda: Tienda, desde: DateTime, hasta: DateTime, usuario: Usuario): List<Venta>` — Llama a servicioAcceso.exigirPropietario(usuario) y luego a servicioVentas.listarVentas(tienda, desde, hasta).
- `+ anularVenta(tienda: Tienda, venta: Venta, motivo: String, usuario: Usuario): AnulacionVenta` — Llama a servicioAcceso.exigirPropietario(usuario) y luego a servicioVentas.anular(tienda, venta, motivo, usuario) (RNF-15).

Relaciones: Association → `ServicioVentas` [1]; Association → `ServicioAcceso` [1]

### `ConsultarClienteCoordinator` (class)

> Controller (caso de uso CUS-19 y su extension CUS-21 Eliminar datos de un cliente): busca clientes, muestra su saldo y su historial de fiados y abonos, y elimina sus datos cuando ya no debe; delega en ServicioClientes y, para listar o buscar fiados, en ServicioFiados. Lo usan tambien las pantallas de CUS-07 y CUS-08 («include») (DA-67, DA-69).

Atributos:
- `- servicioClientes: ServicioClientes`
- `- servicioFiados: ServicioFiados`

Operaciones:
- `+ ConsultarClienteCoordinator(servicioClientes: ServicioClientes, servicioFiados: ServicioFiados)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ buscarClientes(tienda: Tienda, nombre: String): List<Cliente>` — Llama a servicioClientes.buscarClientes(tienda, nombre).
- `+ consultarSaldoTotal(cliente: Cliente): Decimal` — Llama a servicioClientes.consultarSaldoTotal(cliente).
- `+ listarFiados(tienda: Tienda): List<Fiado>` — Llama a servicioFiados.listarFiados(tienda).
- `+ buscarFiadosPorCliente(tienda: Tienda, nombre: String): List<Fiado>` — Llama a servicioFiados.buscarFiadosPorCliente(tienda, nombre).
- `+ consultarHistorial(cliente: Cliente): List<Fiado>` — Llama a servicioClientes.obtenerHistorial(cliente).
- `+ eliminarCliente(tienda: Tienda, cliente: Cliente): void` — Llama a servicioClientes.eliminarCliente(tienda, cliente) (CUS-21, RNF-16). La confirmacion explicita la pide la pantalla antes de llamar (RNF-26).

Relaciones: Association → `ServicioFiados` [1]; Association → `ServicioClientes` [1]

### `RegistrarAbonoCoordinator` (class)

> Controller (caso de uso CUR-08, incluye CUS-19): registra el abono en efectivo o por Nequi; delega en ServicioAbonos. La busqueda del cliente y de sus fiados la da ConsultarClienteCoordinator (DA-67, DA-69).

Atributos:
- `- servicioAbonos: ServicioAbonos`

Operaciones:
- `+ RegistrarAbonoCoordinator(servicioAbonos: ServicioAbonos)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ registrarAbono(tienda: Tienda, fiado: Fiado, monto: Decimal, medio: MedioPago, referencia: String?): Abono` — Llama a servicioAbonos.registrarAbono(tienda, fiado, monto, medio, referencia) y devuelve el Abono.

Relaciones: Association → `ServicioAbonos` [1]

### `RegistrarFiadoCoordinator` (class)

> Controller (caso de uso CUR-07, extiende a CUR-02 e incluye CUS-19): registra al cliente si no existe (ServicioClientes) y prepara el fiado (ServicioFiados); la busqueda del cliente y su saldo los da ConsultarClienteCoordinator (DA-67, DA-69).

Atributos:
- `- servicioClientes: ServicioClientes`
- `- servicioFiados: ServicioFiados`

Operaciones:
- `+ RegistrarFiadoCoordinator(servicioClientes: ServicioClientes, servicioFiados: ServicioFiados)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ registrarCliente(tienda: Tienda, nombre: String, telefono: String): Cliente` — Llama a servicioClientes.registrarCliente(tienda, nombre, telefono) (extension 2a).
- `+ prepararFiado(cliente: Cliente, monto: Decimal): Fiado` — Llama a servicioFiados.crearFiado(cliente, monto). El fiado queda en memoria; la pantalla lo conserva y lo entrega en RegistrarVentaCoordinator.confirmarVenta, donde se guarda.

Relaciones: Association → `ServicioFiados` [1]; Association → `ServicioClientes` [1]

### `RegistrarVentaCoordinator` (class)

> Controller (caso de uso CUR-02, incluye CUS-06): recibe las operaciones del sistema desde la presentacion y las delega en ServicioVentas, una llamada por operacion. No guarda estado: las lineas de la venta (List) y las formas de pago las conserva la pantalla (DA-54, DA-57).

Atributos:
- `- servicioVentas: ServicioVentas`

Operaciones:
- `+ RegistrarVentaCoordinator(servicioVentas: ServicioVentas)` — Constructor: recibe sus dependencias o datos (DIP).
- `+ agregarProducto(tienda: Tienda, lineas: List<LineaVenta>, producto: Producto, cantidad: Decimal): LineaVenta` — Llama a servicioVentas.agregarLinea(tienda, List&lt;LineaVenta&gt;, producto, cantidad): suma la cantidad si el producto ya esta y bloquea si no hay existencia (RN-01).
- `+ cambiarCantidad(linea: LineaVenta, cantidad: Decimal): void` — Llama a servicioVentas.cambiarCantidad(linea, cantidad), que vuelve a verificar la existencia (RN-01).
- `+ obtenerTotal(lineas: List<LineaVenta>): Decimal` — Llama a servicioVentas.calcularTotal(lineas).
- `+ pagarDeContado(montoACubrir: Decimal, montoRecibido: Decimal): PagoContado` — Llama a servicioVentas.crearPagoContado(montoACubrir, montoRecibido) y devuelve el PagoContado; la pantalla muestra pago.getCambio() y lo conserva hasta confirmar.
- `+ pagarConNequi(monto: Decimal, referencia: String?): PagoNequi` — Llama a servicioVentas.crearPagoNequi(monto, referencia) y devuelve el PagoNequi; la pantalla lo conserva hasta confirmar.
- `+ confirmarVenta(tienda: Tienda, lineas: List<LineaVenta>, formasPago: List<FormaPago>): Venta` — Llama a servicioVentas.confirmar(tienda, lineas, formasPago). formasPago son el PagoContado de pagarDeContado, el PagoNequi de pagarConNequi y/o el Fiado de RegistrarFiadoCoordinator.prepararFiado (RD-07: 2 s o menos).

Relaciones: Association → `ServicioVentas` [1]

