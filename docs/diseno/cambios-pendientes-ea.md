# Cambios pendientes en el modelo de EA

Lista de lo que hay que cambiar en Enterprise Architect (`docs/modelo-ea/ProyectoUML_XX.qea`) para que el modelo quede igual al código. Sale de las decisiones de implementación (`docs/decisiones.md`) que dicen "pasar a EA" y de una comparación de `docs/diseno/clases.md` con `lib/business` hecha el 2026-11-17, con `main` en `df5999c` (hasta DI-33).

**Cómo usarla:** quien actualice EA marca cada casilla al hacerlo. Al terminar se regenera el texto con `python3 tool/export_qea.py <ruta.qea> docs/diseno` y se borra lo que ya quedó en `clases.md` y en `secuencias/`. Cada DI nueva que diga "pasar a EA" se agrega aquí en el mismo PR.

**Qué no hay que cambiar:** las operaciones y clases de EA que todavía no están en el código (por ejemplo `AnulacionVenta`, `Caja.cerrar`, `ServicioConciliacion` o `listarCodigosRepetidos`) son de casos de uso que faltan (CUS-11, 12, 14, 15, 16, 20, 22 y 23). Se quedan en EA tal como están.

## 1. Clases nuevas

- [ ] **`IAutenticacion`** (interface) en `Interfaces/InfoTienda`. Inicio de sesión con Supabase Auth (DI-05, DI-11).
  - `+ iniciarSesion(correo: String, clave: String): UsuarioActivo`: inicia sesión y devuelve el usuario con su tienda y su rol (la fila de `usuarios` con ese correo).
  - `+ haySesionGuardada(): bool`
  - `+ usuarioSigueActivo(idUsuario: String): bool?`: lo que dice el servidor sobre si el usuario sigue activo; nulo si no se puede saber (DI-44).
  - `+ cerrarSesion(): void`
- [ ] **`ISesionLocal`** (interface) en `Interfaces/InfoTienda`. Guarda el usuario activo en el dispositivo para entrar sin internet (DI-12).
  - `+ guardar(usuarioActivo: UsuarioActivo): void`
  - `+ leer(): UsuarioActivo?`
  - `+ borrar(): void`
- [ ] **`IniciarSesionCoordinator`** (class) en `Workflow/InfoTienda`, con `- servicioAcceso: ServicioAcceso`. Sus operaciones solo delegan en `ServicioAcceso` (DI-11).
  - `+ IniciarSesionCoordinator(servicioAcceso: ServicioAcceso)`
  - `+ iniciarSesion(correo: String, clave: String): UsuarioActivo`
  - `+ sesionGuardada(): UsuarioActivo?`
  - `+ revisarUsuarioActivo(activo: UsuarioActivo): bool` (DI-44)
  - `+ cerrarSesion(): void`
- [ ] **`Sincronizador`** (class, Service Agent en `Data/ServiceAgents`; hoy solo es un participante del diagrama de CUS-23) y la interfaz **`ServidorRemoto`** (DI-47 a, b, c): `+ sincronizar(tienda: Tienda): ResultadoSincronizacion` (una a la vez; nunca lanza). Constructor con `ServidorRemoto` y la función de conciliación (`ConciliarCoordinator.ejecutar`), para que la Data Layer no importe el Workflow. `ServidorRemoto`: `insertarSiNoExiste(tabla, filas)`, `guardar(tabla, filas)`, `borrar(tabla, id)` y `leerDesde(tabla, tienda, desde, limite, desplazamiento)`; lo implementa `ServidorRemotoSupabase`. `ResultadoSincronizacion`: `subidos`, `bajados`, `conflictosNuevos`, `pendientes`, `sinConexion`, `error`. `escrituras: Stream<void>`: avisa cada vez que este equipo anota algo para subir (DI-48). Si se pide sincronizar mientras corre una, devuelve la misma y hace otra vuelta al terminar.
- [ ] **`DisparadorSincronizacion`** (Presentation, `comun`; DI-47 g, DI-48): llama al Sincronizador al tener usuario activo, al volver del segundo plano, al recuperar la conexión, cada 5 minutos (respaldo) y al instante: 1 s después de que este equipo escribe algo (`Sincronizador.escrituras`) o de que otro equipo cambia algo de la tienda (`CambiosRemotosSupabase`, Supabase Realtime).
- [ ] **`ICuentaAcceso`** (interface) en `Interfaces/InfoTienda`. Crea la cuenta con la que se inicia sesión (correo y contraseña); la implementa la Data Layer con Supabase Auth (DI-43).
  - `+ crear(correo: String, clave: String): void`: crea la cuenta sin abrir sesión con ella. Si ya existe una con ese correo y la misma contraseña (un intento anterior que no alcanzó a guardar al empleado) la da por buena; si la contraseña es otra, rechaza con "Ese correo ya tiene una cuenta".
- [ ] **`UsuarioActivo`** en `Entidades/InfoTienda`: tipo de dato (registro) con `usuario: Usuario` y `tienda: Tienda`, sin operaciones. El rol es la subclase de `Usuario` (DI-11). Relaciones (DI-62): **agregación** con el rombo vacío en `UsuarioActivo` hacia `Usuario` y hacia `Tienda` (0..* en `UsuarioActivo`, 1 en `Usuario` y en `Tienda`); Dependency → `UsuarioActivo` desde `IAutenticacion`, `ISesionLocal`, `ServicioAcceso` e `IniciarSesionCoordinator`.
- [ ] Opcional, si el diagrama de componentes muestra la Data Layer: `AutenticacionSupabase` implementa `IAutenticacion` y `SesionLocalPreferencias` implementa `ISesionLocal` (DI-05, DI-12).

## 2. Cambios en clases existentes

### Entidades/InfoTienda

- [ ] **`DatosExportacion`** (DI-62): las asociaciones con `ItemInventario`, `Venta` y `Fiado` pasan a **agregación** con el rombo vacío en `DatosExportacion`, 0..* en los dos extremos. Atributos y operaciones no cambian.
- [ ] **`Tienda`**: atributo `- id: String` (uuid; es el `tienda_id` de todas las tablas, y `codigo` sigue siendo el código visible), operación `+ getId(): String` y constructor `Tienda(id, codigo, nombre, direccion)` (DI-11).
- [ ] **`Usuario`**, **`Empleado`** y **`Administrador`**: el constructor recibe `activo: bool` opcional, por defecto verdadero, para leer el usuario de la base (DI-11).
- [ ] **`Usuario`**: atributo `- correo: String?` (con el que inicia sesión), operación `+ getCorreo(): String?` y el parámetro opcional `correo` en el constructor de `Usuario`, `Empleado` y `Administrador`. Nulo si no se conoce (DI-43).

### Componentes/InfoTienda

- [ ] **`ServicioAcceso`** deja de ser "sin dependencias" (DI-05, DI-11, DI-12):
  - Atributos `- autenticacion: IAutenticacion` y `- sesionLocal: ISesionLocal`; constructor `ServicioAcceso(autenticacion, sesionLocal)`.
  - `+ iniciarSesion(correo: String, clave: String): UsuarioActivo`: valida que lleguen correo y clave, inicia sesión, rechaza al usuario inactivo y guarda el usuario activo con `sesionLocal.guardar`.
  - `+ sesionGuardada(): UsuarioActivo?`: el usuario guardado en el dispositivo, sin usar la red.
  - `+ revisarUsuarioActivo(activo: UsuarioActivo): bool` (DI-44): vuelve a preguntar si el usuario de la sesión guardada sigue activo; devuelve falso y cierra la sesión solo si el servidor dice que está desactivado; sin internet o ante una falla devuelve verdadero.
  - `+ cerrarSesion(): void`: borra primero la sesión local y luego la de Auth, para que un fallo sin internet no deje entrar sola la app.

- [ ] **`ServicioExportacion`** (DI-41 a, e): constructor con `reloj` opcional (la fecha de `DatosExportacion`); descripción de `exportar`: el periodo es `[desde, hasta)`, los fiados salen todos (no solo los del periodo) y con `desde > hasta` lanza "Periodo no válido" sin leer nada.
- [ ] **`IExportador.exportar`**, descripción (DI-41 b, c, d): arma el archivo **y lo entrega** (compartir o descargar) y devuelve el nombre. En Excel es un libro con tres hojas (Inventario, Ventas, Fiados); en CSV son tres archivos y devuelve el nombre base común. Una fila por fiado, con la cantidad de abonos, el total abonado y el saldo; una fila por venta (también las anuladas, marcadas).

- [ ] **`ServicioUsuarios`** (DI-42 b, d; DI-43):
  - Constructor `ServicioUsuarios(usuarios, cuentas: ICuentaAcceso)`.
  - `crearEmpleado(tienda, nombre, cedula, correo: String, clave: String)`: quita los espacios del nombre, la cédula y el correo y pasa el correo a minúsculas; una cédula vacía también es "Datos no válidos"; la cédula repetida cuenta aunque el otro usuario esté inactivo, y la misma cédula en otra tienda se permite. Valida el correo (`algo@dominio.ext`) y que la contraseña tenga al menos 6 caracteres. Revisa todo y la cédula repetida **antes** de llamar a `cuentas.crear(correo, clave)`, y después crea el `Empleado` con ese correo y lo guarda.
  - `desactivar`: si guardar falla el usuario ya quedó inactivo en memoria; quien llama vuelve a leer la lista. La cuenta de acceso no se toca.
- [ ] **`IUsuarioRepositorio`**, descripción (DI-42 b; DI-43): los usuarios viven en el servidor y la pantalla necesita internet. `listar` trae primero al propietario y luego a los empleados, cada grupo por nombre. `buscarPorCedula` encuentra también al inactivo. `guardar` manda el correo solo si el usuario lo tiene: no borra el que ya hay.

### Entidades y componentes de conciliación (CUS-22)

- [ ] **`IProductoRepositorio.quitarCodigo(tienda: Tienda, producto: Producto, codigo: CodigoProducto): void`** (DI-45 c): borra la fila del código y anota ELIMINAR en la cola; no hace nada si el código no estaba. La usa `ResolutorCodigoRepetido` (CUS-22); `guardar` no borra códigos.
- [ ] **`ConflictoSincronizacion`** (DI-45 d): atributo `- etiquetasRegistros: List<String>` (uno por cada id de `idsRegistros`, mismo orden; por defecto "Registro N"), `+ getEtiquetasRegistros(): List<String>`, `+ getEtiquetaDe(id: String): String`, `+ isResuelto(): bool` y el constructor con `etiquetasRegistros` opcional. El `id` es texto determinista (tipo y registros), no UUID.
- [ ] **`ServicioConciliacion`** (DI-45 a): constructor `ServicioConciliacion(conflictos, unidadTrabajo, resolutores: List<ResolutorConflicto>)` hasta CUS-23; después se completa con `movimientos`, `fiados`, `cajas`, `productos` y `servicioInventario`. `resolverConflicto` rechaza el conflicto ya resuelto (`ExcepcionConflictoYaResuelto`) o sin resolutor (`ExcepcionConflictoSinResolutor`) y, si la transacción falla, deja `setResuelto(false)`.
- [ ] **`ResolutorMovimientos.resolver`**, descripción (DI-45 e): pasan a VIGENTE solo los movimientos que estaban EN_REVISION; el que ya estaba ANULADO y no se eligió sigue anulado. Si falta algún movimiento del conflicto lanza `ExcepcionRegistrosDelConflictoNoEncontrados`.
- [ ] **`ResolutorAbonoExcedido.resolver`**, descripción (DI-45 f): antes de escribir comprueba que el saldo no quede negativo (`ExcepcionAbonoSigueExcedido`); no devuelve dos veces un abono ya anulado; el egreso de caja ("Devolución abono") solo se registra si el abono fue en efectivo.
- [ ] **`ResolutorCodigoRepetido.resolver`**, descripción (DI-45 f): sin ningún producto elegido lanza `ExcepcionDecisionIncompleta`; el código interno nuevo es `codigo-n`, con el primer `n` desde 2 que ningún producto tenga; llama a `productos.quitarCodigo` para los códigos de barras y QR.
- [ ] **`ResolutorCajaCerrada.resolver`**, descripción (DI-45 f): no cambia el efectivo contado ni la fecha del cierre.
- [ ] **`IConflictoRepositorio.guardar`** (DI-46 c): `+ guardar(tienda, conflicto): bool`, verdadero si lo insertó y falso si ya existía (resuelto o no).
- [ ] **`IMovimientoInventarioRepositorio.listarPorTienda(tienda, desde, hasta)`** (DI-46 d): los cuatro tipos y los tres estados, `[desde, hasta)`, del más antiguo al más reciente, con ítem y producto.
- [ ] **`IFiadoRepositorio.listarModificadosDesde(tienda, desde)`** (DI-46 d): fiados que empezaron o recibieron un abono (anulado o no) desde esa fecha, con cliente y abonos.
- [ ] **`ServicioConciliacion`** (DI-46 b, e, f): constructor con `reloj` opcional. `conciliar` en una sola transacción. Ids de conflicto: UUID v5 del tipo y de las claves (duplicado: las dos entradas; stock negativo: el ítem; abono: fiado y abonos no anulados; código: clase, valor y productos; caja: caja y movimiento). `detectarPosiblesDuplicados`: solo entradas VIGENTES con número de factura, pareja hasta 1 día antes de `desde`, EN_REVISION solo si el conflicto es nuevo. `detectarAbonosExcedidos`: ignora los fiados anulados y guarda el saldo solo si cambió. `detectarCodigosRepetidos`: agrupa `productos.listar` por código interno y por valor (no usa `listarCodigosRepetidos`). `detectarMovimientosCajaCerrada`: solo movimientos posteriores al cierre, con el día en hora local.
- [ ] **`ServicioInventario.recalcularStock`**, descripción (DI-46 f): no escribe el ítem si el stock no cambió.
- [ ] **`ConciliarCoordinator.ejecutar`**, descripción (DI-46 b): no llama a `exigirPropietario`; lo corre la app.
- [ ] **`EtiquetasConflicto`** (DI-46 h): clase de apoyo en `Componentes/InfoTienda` con `hora`, `diaYHora`, `pesos`, `cantidad`, `movimiento` y `abono`; escribe las etiquetas de los registros de un conflicto.

### Entidades/GestionInventario

- [ ] **`ItemInventario`**: `+ setStockActual(stockActual: Decimal): void`. El diagrama de CUS-01 (paso 27) ya la usa (DI-20 a).
- [ ] **`AjusteConteo`**, descripción: `cantidad` es la diferencia con signo (contada − stock) y una diferencia cero también se registra, como constancia del conteo (DI-24 b).
- [ ] **`SalidaVenta`** (DI-56): atributo `- ventaId: String` en lugar de `- venta: Venta`; constructor `SalidaVenta(id: String, item: ItemInventario, cantidad: Decimal, fecha: DateTime, ventaId: String, precioUnitario: Decimal, costoUnitario: Decimal?)`; `+ getVentaId(): String` en lugar de `getVenta(): Venta`. Se quita la composición `Venta` ◆ `SalidaVenta` y la descripción de `Venta` deja de decir que sus salidas son partes de ella: la salida se crea con la venta en la misma transacción (`ServicioVentas.confirmar`) y guarda solo su id.
- [ ] **Relaciones de inventario** (DI-56): `Producto` ◆ `CodigoProducto` vuelve a **composición** (1 a 0..*), en lugar de la agregación de DI-54 (a); `ItemInventario` ◆ `MovimientoInventario` pasa de asociación a **composición** (1 a 0..*), con el rombo en `ItemInventario`. Las subclases (`EntradaMercancia`, `Merma`, `AjusteConteo`, `SalidaVenta`) la heredan.
- [ ] **`AlertaReabastecimiento`** (DI-57, DI-60): atributos `- itemId: String`, `- productoId: String` y `- nombreProducto: String` en lugar de `- item: ItemInventario`; operaciones `+ getItemId(): String`, `+ getProductoId(): String` y `+ getNombreProducto(): String` en lugar de `getItem()`. Constructor `AlertaReabastecimiento(id: String, itemId: String, productoId: String, nombreProducto: String, fecha: DateTime, existencia: Decimal, consumoPromedioDiario: Decimal, diasCobertura: Decimal, provisional: bool)`. Se quita la relación con `ItemInventario`; `ServicioAlertas.evaluarItem` le pasa los datos del ítem (ya tiene Dependency → `AlertaReabastecimiento`).
- [ ] **`VentaPerdida`** (DI-58, DI-60): atributos `- productoId: String` y `- nombreProducto: String` en lugar de `- producto: Producto`; operaciones `+ getProductoId(): String` y `+ getNombreProducto(): String`. Constructor `VentaPerdida(id: String, productoId: String, nombreProducto: String, fecha: DateTime)`. Se quita la relación con `Producto`; `ServicioAlertas.registrarVentaPerdida` le pasa los datos del producto (ya tiene Dependency → `VentaPerdida`).
- [ ] **`Etiqueta`** (DI-55, DI-60): atributos `- nombre: String`, `- precioVenta: Decimal`, `- valorCodigo: String` y `- formato: FormatoCodigo` en lugar de `- producto: Producto` y `- codigo: CodigoProducto`; operaciones `+ getNombre(): String`, `+ getPrecioVenta(): Decimal`, `+ getValorCodigo(): String` y `+ getFormato(): FormatoCodigo` en lugar de `getProducto()` y `getCodigo()`. Constructor `Etiqueta(nombre: String, precioVenta: Decimal, valorCodigo: String, formato: FormatoCodigo)`. Se quitan las relaciones con `Producto` y `CodigoProducto` (queda Dependency → `FormatoCodigo`); `ServicioCatalogo.generarEtiquetas` le pasa los datos (ya tiene Dependency → `Etiqueta`).

### Interfaces/GestionInventario

- [ ] **`IMovimientoInventarioRepositorio`**:
  - Nueva `+ buscarFechaPrimerMovimiento(item: ItemInventario): DateTime?`: fecha del primer movimiento del ítem, de cualquier tipo y estado; marca el inicio de su historial para el consumo promedio (DI-25 b).
  - Descripción de `buscarUltimaEntrada`: solo la última entrada **VIGENTE**, y filtra por la tienda del ítem (DI-20 b, c).
  - Descripción de `listarSalidas`, `listarSalidasPorTienda`, `listarEntradasPorTienda` y `listarPorItem`: el periodo es `[desde, hasta)`, es decir, `hasta` no se incluye (DI-25 c, DI-28 b, DI-29 b, DI-32 a).
  - Descripción de `listarPorItem`: trae los movimientos en cualquier estado (VIGENTE, EN_REVISION o ANULADO) (DI-32 a).
- [ ] **`IVentaPerdidaRepositorio.listarPorProducto`**, descripción: no recibe la tienda; filtra por el producto y la tienda del producto (DI-25 c).

### Componentes/GestionInventario

- [ ] **`ServicioInventario`** (DI-63): `anularSalidas(tienda: Tienda, ventaId: String): void` y `listarSalidasDeVentas(tienda: Tienda, idsVentas: List<String>): Map<String, List<SalidaVenta>>`, con el id de la venta en lugar de `Venta`.
- [ ] **`ServicioInventario`** (DI-33, DI-22, DI-24, DI-32):
  - Atributo nuevo `- productos: IProductoRepositorio` y constructor `ServicioInventario(items, movimientos, umbralRevisionConteo, unidadTrabajo, productos)`.
  - Descripción de `registrarEntrada`: en la misma transacción que la entrada y el stock, el costo de la entrada pasa a ser el precio de compra del producto (`setPrecioCompra`, `setActualizadoEn` y `productos.guardar`). Una entrada con costo cero (bonificación) o con el mismo costo no lo cambia. Si algo falla no se guarda nada y el producto vuelve a su precio anterior.
  - `registrarMerma(tienda, producto, cantidad, motivo: MotivoMerma?)`: el motivo puede ser nulo ("no eligió motivo") y se rechaza con "Datos no válidos". Antes de abrir la transacción revisa la existencia y rechaza con "La cantidad supera la existencia".
  - Descripción de `consultarMovimientos`: si el producto no tiene ítem devuelve una lista vacía, sin error.
  - Nota en `umbralRevisionConteo`: vale 5 y está fijo en la configuración, porque no hay dónde guardar una configuración que el tendero cambie (DI-24 a).
- [ ] **`ServicioAlertas`**, nota en `umbralDiasCobertura`: vale 7 y está fijo en la configuración; hay alerta si la cobertura es menor que 7. **Falta que el equipo confirme el 7** (DI-25 a).
- [ ] **`ServicioAlertas`**, descripción de `evaluarItem` (DI-25 b):
  - el periodo es `[día − 30 días, día)`: los 30 días completos anteriores, sin el día en curso;
  - los días con datos van del primer registro del ítem (`buscarFechaPrimerMovimiento` o su primera venta perdida) al día, con tope de 30; con menos de 30 la alerta es provisional;
  - si el consumo es 0 no hay alerta; con existencia cero o negativa la cobertura es 0; la cobertura se redondea a 2 decimales.
- [ ] **`InterpreteCodigoBarras`**: `+ esCodigoBarrasValido(lectura: String): bool` (estática): 8, 12 o 13 dígitos con dígito de control GS1 válido. La usan `reconoce` y también `InterpreteCodigoQR.reconoce`, que reconoce lo que no es un EAN ni un UPC (DI-34 a).
- [ ] **`ServicioCatalogo`** (DI-34 b):
  - Descripción de `buscarPorLectura`: quita los espacios del inicio y del final de la lectura; una lectura vacía devuelve null sin buscar.
  - Descripción de `asociarCodigo`: quita los espacios; rechaza el valor vacío ("Escriba o lea el código"); si el código ya es de este mismo producto lo devuelve sin repetirlo; si el guardado falla, quita el código del producto en memoria.
- [ ] **`IProductoRepositorio.guardar`**, descripción: agrega los códigos nuevos del producto y nunca borra los que ya están guardados; quitar un código llega con CUS-22 (DI-34 c).
- [ ] **`ConsumoPromedioSimple`**, descripción de `calcularConsumoDiario(salidas, perdidas, dias)`: unidades vendidas más una por venta perdida, divididas entre `dias`; con `dias` en 0 devuelve 0, y el resultado se redondea a 4 decimales (DI-25 b).

### Workflow/GestionInventario

- [ ] **`RegistrarPerdidaCoordinator`** (DI-22 a, b):
  - Nueva `+ consultarExistencia(tienda: Tienda, producto: Producto): Decimal`: llama a `servicioInventario.obtenerItem` y devuelve su stock; la pantalla la usa al elegir el producto.
  - `registrarPerdida(tienda, producto, cantidad, motivo: MotivoMerma?)`: motivo nulo, como en `registrarMerma`.

### Entidades/GestionCaja y Componentes/GestionCaja

- [ ] **Relaciones de los componentes de caja** (DI-64): las asociaciones pasan a **dependencia** «use»: `ServicioCaja` ⇢ `ICajaRepositorio`; `ServicioReportes` ⇢ `IVentaRepositorio`, `IMovimientoInventarioRepositorio`, `ICajaRepositorio`, `IFiadoRepositorio`, `IEstadoSincronizacion` e `IInventarioRepositorio`. Las dependencias hacia lo que crean pasan a «create»: `ServicioCaja` ⇢ `Caja` y `MovimientoCaja`, `ServicioReportes` ⇢ `ReporteDiario`. Se agregan, porque faltan en el diagrama: `ServicioReportes` ⇢ `Producto` «use» (llave de los mapas de `calcularMargenes` y `clasificarRotacion`) y `ServicioReportes` ⇢ `Fiado`, `PagoNequi` y `MedioPago` «use» (separa ventas fiadas y por Nequi y abonos por Nequi). `Caja` ◆ `MovimientoCaja` sigue como composición, 1 a 0..*.
- [ ] **`DesgloseCaja`** (DI-38, DI-64): clase nueva en `Entidades/GestionCaja`, sin relaciones con otras entidades: `baseApertura`, `ingresosNegocio`, `ingresosPersonales`, `egresosNegocio`, `cantidadEgresosNegocio`, `egresosPersonales`, `devolucionesPorAnulacion` y `saldoEsperado` (todos `Decimal` salvo `cantidadEgresosNegocio: int`). `Caja` gana `+ calcularDesglose(): DesgloseCaja` y `Caja` ⇢ `DesgloseCaja` «create».
- [ ] **`ServicioCaja`** (DI-21 b):
  - `+ idCaja(tienda: Tienda, dia: DateTime): String` (estática): id de la caja del día, `<tienda_id>_AAAA-MM-DD`; no es uuid.
  - `+ diaLocal(momento: DateTime): DateTime` (estática): día local del dispositivo, sin hora.
- [ ] **`Caja`**, descripción de `fecha`: es el día local, sin hora (un día calendario, no un instante) (DI-21 b).
- [ ] **`ServicioReportes`**, descripción de `generarReporteDiario`: la fecha es un día local, de su 00:00 a la 00:00 del día siguiente sin incluirla (DI-29 a).
- [ ] **`ServicioReportes.clasificarRotacion`**, descripción (DI-40 b, c): el periodo es `[desde, hasta)`. Con `n` productos ordenados de mayor a menor venta (empate por nombre), los primeros `ceil(n/3)` son ALTA, hasta `ceil(2n/3)` MEDIA y el resto BAJA; quien no vendió nada es BAJA aunque su lugar caiga en otro tercio. Las unidades se suman por id de producto. El `Map` que devuelve conserva el orden de venta.

### Entidades/Pagos

- [ ] **`Fiado`** (DI-26 c, DI-27 a):
  - Segundo constructor `+ Fiado.guardado(id, montoInicial, fechaInicio, cliente, saldoPendiente, estado, abonos)`, para leerlo de la base con su saldo, estado y abonos.
  - `+ getAbonos(): List<Abono>`.
  - Descripción de `registrarAbono`: rechaza un monto no positivo, mayor que el saldo, o un fiado que no esté PENDIENTE.
  - En el constructor `Fiado(id, montoInicial, fecha, cliente)`, renombrar el parámetro `fecha` a `fechaInicio`, como el atributo (en el código ya se llama así).
- [ ] **`Abono`**: `+ getMonto(): Decimal` y `+ getFecha(): DateTime` (en UTC); el constructor recibe `anulado` opcional, por defecto falso, para leerlo de la base (DI-27 a).
- [ ] **`Cliente`**, descripción (DI-26 b, DI-31 a, b):
  - `telefono` vacío significa que el cliente no lo dio; el teléfono es opcional.
  - Eliminar los datos **anonimiza** al cliente y no borra la fila: queda con el nombre "Cliente eliminado" y el teléfono vacío, y deja de salir en las búsquedas. Sus fiados, abonos y ventas no cambian.

- [ ] **`AnulacionVenta`** (DI-61): atributos `- usuarioId: String` y `- usuarioNombre: String` en lugar de `- usuario: Usuario`; operaciones `+ getUsuarioId(): String` y `+ getUsuarioNombre(): String` en lugar de `getUsuario()`. Constructor `AnulacionVenta(id: String, usuarioId: String, usuarioNombre: String, fecha: DateTime, motivo: String)`. Se quita la asociación con `Usuario`; `ServicioVentas.anular` le pasa el id y el nombre del usuario.
- [ ] **`Venta` ◆ `AnulacionVenta`** (DI-61): composición con el rombo lleno en `Venta`, 1 en `Venta` y 0..1 en `AnulacionVenta`.
- [ ] **`Cliente` — `Fiado`** (DI-61): la asociación pasa a **agregación** con el rombo vacío en `Cliente`, 1 en `Cliente` y 0..* en `Fiado`, navegable en los dos sentidos. Atributos y operaciones no cambian.
- [ ] **`LineaVenta` — `ItemInventario`** (DI-59): la asociación pasa a **agregación** con el rombo vacío en `LineaVenta`, 0..* en `LineaVenta` y 1 en `ItemInventario`. Atributos y operaciones no cambian.

### Componentes/Pagos

- [ ] **Relaciones de los componentes de pagos** (DI-63): las asociaciones pasan a **dependencia** («use»): `ServicioVentas` ⇢ `ServicioInventario`, `ProcesadorPago` (antes [1..*]), `IVentaRepositorio` e `IUnidadTrabajo`; `ServicioAbonos` ⇢ `ServicioCaja`, `IUnidadTrabajo` e `IFiadoRepositorio`; `ServicioClientes` ⇢ `IClienteRepositorio`; `ServicioFiados` ⇢ `IFiadoRepositorio`; `ProcesadorFiado` ⇢ `ServicioFiados`; `ProcesadorPagoContado` ⇢ `ServicioCaja`. Las dependencias hacia las entidades que crean no cambian. `ServicioVentas` llama a `servicioInventario.anularSalidas(tienda, venta.getId())`.
- [ ] **`ServicioVentas`**, descripción de `confirmar`: dentro de la transacción vuelve a leer el ítem de cada línea con `servicioInventario.obtenerItem` antes de crear la `SalidaVenta`. El ítem de la línea trae el stock del momento en que se agregó, y una entrada registrada con la venta abierta se perdería (DI-21 a).

### Interfaces/Pagos

- [ ] **`IFiadoRepositorio.listar`**, descripción: trae los fiados pendientes, saldados y anulados, con su cliente (el eliminado, anonimizado) y sus abonos, también los anulados (DI-41 a).

### Workflow/InfoTienda

- [ ] **`GestionarUsuariosCoordinator.crearEmpleado`**: `crearEmpleado(tienda, nombre, cedula, correo: String, clave: String, usuario: Usuario): Empleado`, que llama a `servicioUsuarios.crearEmpleado(tienda, nombre, cedula, correo, clave)` (DI-43).

### Workflow/Pagos

- [ ] **`RegistrarFiadoCoordinator`**: `+ buscarClientes(tienda: Tienda, nombre: String): List<Cliente>`, que llama a `servicioClientes.buscarClientes`. En EA la búsqueda la da `ConsultarClienteCoordinator`, pero cada pantalla llama a un solo coordinador (DI-26 a).

## 3. Diagramas de secuencia

- [ ] **Iniciar sesión** (nuevo, sin CUS; el nombre de la vista es una propuesta): `VistaInicioSesion` → `IniciarSesionCoordinator.iniciarSesion` → `ServicioAcceso.iniciarSesion` → `IAutenticacion.iniciarSesion` → `ISesionLocal.guardar`. Breaks: faltan datos, credenciales no válidas, usuario no registrado en `usuarios`, usuario inactivo y sin conexión (DI-05, DI-11, DI-12). Recomendado: es el único flujo programado sin diagrama.
- [ ] **CUS-01**:
  - Dentro de `unidadTrabajo.ejecutar`, antes de `aplicarMovimiento`, un `opt` "costo > 0 y distinto al precio de compra" con `producto.setPrecioCompra(costo)`, `producto.setActualizadoEn(ahora)` y `productos.guardar(tienda, producto)` (DI-33).
  - Break de `obtenerItem` sin ítem: "El producto no tiene inventario en esta tienda" (DI-20 e).
- [ ] **CUS-02**: en `confirmar`, por cada línea, `servicioInventario.obtenerItem(tienda, producto)` antes de crear la `SalidaVenta` (DI-21 a).
- [ ] **CUS-03** (DI-22):
  - Al elegir el producto, `VistaPerdida → coordinador.consultarExistencia(tienda, producto)`.
  - El break de "motivo sin elegir" es un motivo nulo.
  - Nuevo break "La cantidad supera la existencia" (`hayExistencia`) antes de abrir la transacción.
- [ ] **CUS-04** (DI-24 a, b, d):
  - Cada producto del loop de confirmación es su propia transacción, no el lote.
  - Una diferencia cero también se registra.
  - El umbral es 5.
- [ ] **CUS-07** (DI-26 a, d):
  - `VistaFiado` busca clientes con `RegistrarFiadoCoordinator.buscarClientes`, no con `ConsultarClienteCoordinator`.
  - El cliente nuevo se guarda en su propia transacción: queda aunque la venta no se confirme.
- [ ] **CUS-10**: nota de que el periodo es el día local `[00:00, 00:00 del día siguiente)` (DI-29 a).
- [ ] **CUS-12**: nota de que el periodo es `[desde, hasta)` y de que `rotacion` es un `Map` ordenado de mayor a menor venta, sin las unidades de cada producto (DI-40 b, c, e).
- [ ] **CUS-13**: nota de que `VistaVenta` usa dos coordinadores (`RegistrarVentaCoordinator` y `RegistrarVentaPerdidaCoordinator`), única excepción a "una vista, un coordinador" (DI-30 c).
- [ ] **CUS-14** (DI-37 a, c, d; DI-38):
  - `Caja`: el constructor acepta, como opcionales, la base de apertura, los movimientos y los datos del cierre para armar una caja guardada. Atributo nuevo `baseApertura`; `calcularSaldoEsperado` suma la base; operación nueva `calcularDesglose(): DesgloseCaja` y la clase `DesgloseCaja`.
  - `ServicioCaja.obtenerCajaDelDia` (y el opt "Abrir caja" de CUS-11 y el paso 6 de CUS-14): al crear la caja, su base es lo contado en la caja anterior, o el saldo esperado de esa si no se cerró, o cero. `ICajaRepositorio`: `buscarUltimaAnterior(tienda, fecha)`.
  - `ServicioCaja.consultarCajaDelDia(tienda)` y la misma operación, con `usuario`, en `RegistrarMovimientoCajaCoordinator` y en `RegistrarCierreCajaCoordinator`. Las pantallas Caja y Cierre de caja usan la caja completa en vez de `consultarSaldoEsperado` (pasos 2 a 11).
  - Entre los pasos 12 y 13, la vista muestra la diferencia que quedaría con el efectivo escrito (solo para mostrar).
  - Break "Efectivo no válido" ("Escribe cuánto efectivo contó") para un efectivo vacío, no numérico o negativo.
  - Nota: la diferencia cero se muestra como "La caja cuadra".
- [ ] **CUS-17** (DI-34 b, d): nota de que `buscarPorLectura` quita los espacios y que una lectura vacía devuelve null sin buscar; en el alt "Lectura fallida", el lector desconectado no se puede detectar en modo teclado. Si el código no está registrado y hay resultados por nombre (se escribió un nombre y se oprimió Enter), quedan esos resultados.
- [ ] **CUS-18**, opt "Asociar código" (DI-34 b, f): break "Código vacío" ("Escriba o lea el código") antes del paso 21; si `otro` es el mismo producto, devuelve el código que ya tiene sin crear otro; en un producto nuevo el código se asocia después de `crearProducto`.
- [ ] **CUS-18**, opt "Etiquetas" (DI-35 a, b):
  - Break "Copias no válidas" ("Las copias deben estar entre 1 y 100") antes de generar las etiquetas.
  - Dice de qué código es la etiqueta: el QR del producto o, si no tiene, el primero que tenga.
  - Si falla el guardado del código nuevo, se quita del producto antes de relanzar el error.
- [ ] **CUS-15** (DI-42 b, d; DI-43): `ingresarEmpleado(nombre, cedula, correo, clave)` y `crearEmpleado(tienda, nombre, cedula, correo, clave, usuario)`. En `ServicioUsuarios.crearEmpleado`, antes de crear al empleado: `breaks` "Correo no válido" ("Escribe un correo válido") y "Contraseña corta" ("La contraseña debe tener al menos 6 caracteres"), y un `ICuentaAcceso.crear(correo, clave)` (con su `break` "Ese correo ya tiene una cuenta") entre la revisión de la cédula y `Empleado(id, nombre, cedula, correo)`. El break "Datos no válidos" incluye la cédula vacía. Tras cada intento de agregar o desactivar, `VistaUsuarios` vuelve a llamar a `listarUsuarios`.
- [ ] **CUS-16** (DI-41 b, c, e): el exportador entrega el archivo y `VistaExportacion` solo muestra "Datos exportados: " + nombre (sin tamaño ni botón de volver a compartir); en CSV son tres archivos y el nombre es el nombre base. Nota: el periodo es `[desde, hasta)`.
- [ ] **CUS-20** (DI-39 a, b, d, e):
  - `Venta`: el constructor acepta, como opcional, la anulación para armar una venta guardada. `Fiado.restaurar(saldo, estado)`.
  - `ServicioVentas.anular`: `venta.anular(anulacion)` se llama después de la transacción, cuando todo se guardó, y no dentro. Break "Motivo obligatorio" ("Escribe el motivo de la anulación") antes de abrir la transacción.
  - `IMovimientoInventarioRepositorio.listarSalidasPorVenta(venta)` pasa a `listarSalidasPorVentas(tienda, idsVentas: List<String>)` (con la tienda y los ids de varias ventas juntas; DI-63). `ServicioInventario.listarSalidasDeVentas`, `ServicioVentas.listarSalidas` y `AnularVentaCoordinator.listarProductos`, para mostrar los productos de cada venta.
  - `IVentaRepositorio.listarPorPeriodo` trae también las ventas anuladas (los reportes las excluyen con `isAnulada`).
- [ ] **CUS-21**: eliminar es anonimizar (nombre "Cliente eliminado", teléfono vacío), y la escritura se anota como ACTUALIZAR en la cola (DI-31 a, b).
- [ ] **CUS-22** (DI-45 g, h): `idsElegidos` depende del tipo: en POSIBLE_DUPLICADO son los registros que se **anulan** (los que el propietario no marcó como ocurridos); en ABONO_EXCEDE_SALDO, los abonos que se anulan; en CODIGO_REPETIDO, los productos que pierden el código; en STOCK_NEGATIVO y MOVIMIENTO_CAJA_CERRADA va vacío. La vista también ofrece "Ir al conteo" (abre CUS-04, no resuelve) y, tras cada intento, vuelve a pedir `consultarConflictos`. Una tarjeta puede juntar varios conflictos (una entrada repetida varias veces, DI-51): en ese caso la vista llama a `resolver` una vez por cada conflicto del grupo, con las entradas que no están marcadas.
- [ ] **CUS-23** (DI-46 f, g): `desde` es la fecha del registro más antiguo que llegó al sincronizar; los detectores buscan la pareja de un duplicado hasta 1 día antes de `desde`. En el paso 6, la segunda entrada solo queda EN_REVISION si `conflictos.guardar` devuelve verdadero (paso 14 antes del efecto). Los pasos 8 a 9 no escriben el ítem si el stock no cambió.
- [ ] **CUS-23**, pasos 1 a 3 (DI-47 b, c, f): `Sincronizador.sincronizar(tienda)` primero sube la cola de pendientes (por tabla, en lotes, padres antes que hijos; lo rechazado queda con un intento más), luego baja lo que cambió en el servidor desde el cursor de cada tabla (aplicado con las reglas de choque y sin anotarlo en la cola) y solo entonces llama a `coordinador.ejecutar(tienda, desde)`, con `desde` = fecha del registro más antiguo que llegó; si nada cambió, no concilia. Si la conciliación escribió algo, vuelve a subir.
- [ ] **CUS-24** (DI-25 b, e):
  - El consumo usa `movimientos.buscarFechaPrimerMovimiento(item)` para los días con datos.
  - Disparo: mientras no exista el Sincronizador (CUS-23), lo lanza `DisparadorAlertasDiarias` en cuanto hay usuario activo, una vez por tienda y día en cada arranque de la app, sin bloquear la pantalla.
- [ ] **CUS-25**: si el producto no tiene ítem, `consultarMovimientos` devuelve una lista vacía (DI-32 a).

## 4. Para decidir en el equipo

- [ ] **Operaciones asíncronas.** En Dart, toda operación que lee o escribe la base o la red devuelve `Future` (por ejemplo `IEstadoSincronizacion.hayPendientes` devuelve `Future<bool>`, DI-29 c). En EA aparecen con el tipo directo (`bool`, `List<X>`). Propuesta: dejar los tipos como están y agregar una nota general en el paquete `Interfaces` que lo diga, en vez de cambiar más de cien firmas.

## 5. Lo que no va en EA

- **Esquema de la base de datos.** El `.qea` no tiene tablas. El esquema está en `supabase/migrations/` (fuente de verdad) y en las tablas drift de `lib/data/local/tablas/`. Por ejemplo, la columna `clientes.eliminado_en` de DI-31 y la tabla `codigos_producto` de DI-34 ya están en las dos.
- **Saldo de `fiados` sin mínimo.** `fiados.saldo_pendiente` puede ser negativo en el servidor (DI-52); en el modelo, `Fiado.recalcularSaldo` ya lo dice ("saldo negativo → ABONO_EXCEDE_SALDO").
- **Esquema local nuevo.** `cursores_sincronizacion` (drift versión 16, DI-47): hasta dónde bajó cada tabla; solo existe en la base local y nunca se sube.
- **Mockups.** Varias DI piden cambios en el canvas de mockups, no en EA: DI-14, DI-21 (e), DI-24 (f), DI-25 (h), DI-26 (g, h), DI-27 (f), DI-28 (e), DI-29 (f) y DI-34 (e, f), DI-45 (h), DI-50 (aviso de conflictos por revisar en Surtido) y DI-51 (tarjeta única para una entrada repetida varias veces) y DI-53 (Vender: unidad en la línea y cantidad con decimales para kilos y libras).
- **Un detalle que se corrige en el código.** `ServicioAlertas.diaLocal` es pública, no está en EA y nadie la usa fuera de la clase: se vuelve privada.
