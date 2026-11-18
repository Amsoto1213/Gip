# Cambios pendientes en el modelo de EA

Lista de lo que hay que cambiar en Enterprise Architect (`docs/modelo-ea/ProyectoUML_XX.qea`) para que el modelo quede igual al código. Sale de las decisiones de implementación (`docs/decisiones.md`) que dicen "pasar a EA" y de una comparación de `docs/diseno/clases.md` con `lib/business` hecha el 2026-11-17, con `main` en `df5999c` (hasta DI-33).

**Cómo usarla:** quien actualice EA marca cada casilla al hacerlo. Al terminar se regenera el texto con `python3 tool/export_qea.py <ruta.qea> docs/diseno` y se borra lo que ya quedó en `clases.md` y en `secuencias/`. Cada DI nueva que diga "pasar a EA" se agrega aquí en el mismo PR.

**Qué no hay que cambiar:** las operaciones y clases de EA que todavía no están en el código (por ejemplo `AnulacionVenta`, `Caja.cerrar`, `ServicioConciliacion` o `listarCodigosRepetidos`) son de casos de uso que faltan (CUS-11, 12, 14, 15, 16, 20, 22 y 23). Se quedan en EA tal como están.

## 1. Clases nuevas

- [ ] **`IAutenticacion`** (interface) en `Interfaces/InfoTienda`. Inicio de sesión con Supabase Auth (DI-05, DI-11).
  - `+ iniciarSesion(correo: String, clave: String): UsuarioActivo`: inicia sesión y devuelve el usuario con su tienda y su rol (la fila de `usuarios` con ese correo).
  - `+ haySesionGuardada(): bool`
  - `+ cerrarSesion(): void`
- [ ] **`ISesionLocal`** (interface) en `Interfaces/InfoTienda`. Guarda el usuario activo en el dispositivo para entrar sin internet (DI-12).
  - `+ guardar(usuarioActivo: UsuarioActivo): void`
  - `+ leer(): UsuarioActivo?`
  - `+ borrar(): void`
- [ ] **`IniciarSesionCoordinator`** (class) en `Workflow/InfoTienda`, con `- servicioAcceso: ServicioAcceso`. Sus operaciones solo delegan en `ServicioAcceso` (DI-11).
  - `+ IniciarSesionCoordinator(servicioAcceso: ServicioAcceso)`
  - `+ iniciarSesion(correo: String, clave: String): UsuarioActivo`
  - `+ sesionGuardada(): UsuarioActivo?`
  - `+ cerrarSesion(): void`
- [ ] **`UsuarioActivo`** en `Entidades/InfoTienda`: tipo de dato (registro) con `usuario: Usuario` y `tienda: Tienda`, sin operaciones. El rol es la subclase de `Usuario` (DI-11).
- [ ] Opcional, si el diagrama de componentes muestra la Data Layer: `AutenticacionSupabase` implementa `IAutenticacion` y `SesionLocalPreferencias` implementa `ISesionLocal` (DI-05, DI-12).

## 2. Cambios en clases existentes

### Entidades/InfoTienda

- [ ] **`Tienda`**: atributo `- id: String` (uuid; es el `tienda_id` de todas las tablas, y `codigo` sigue siendo el código visible), operación `+ getId(): String` y constructor `Tienda(id, codigo, nombre, direccion)` (DI-11).
- [ ] **`Usuario`**, **`Empleado`** y **`Administrador`**: el constructor recibe `activo: bool` opcional, por defecto verdadero, para leer el usuario de la base (DI-11).

### Componentes/InfoTienda

- [ ] **`ServicioAcceso`** deja de ser "sin dependencias" (DI-05, DI-11, DI-12):
  - Atributos `- autenticacion: IAutenticacion` y `- sesionLocal: ISesionLocal`; constructor `ServicioAcceso(autenticacion, sesionLocal)`.
  - `+ iniciarSesion(correo: String, clave: String): UsuarioActivo`: valida que lleguen correo y clave, inicia sesión, rechaza al usuario inactivo y guarda el usuario activo con `sesionLocal.guardar`.
  - `+ sesionGuardada(): UsuarioActivo?`: el usuario guardado en el dispositivo, sin usar la red.
  - `+ cerrarSesion(): void`: borra primero la sesión local y luego la de Auth, para que un fallo sin internet no deje entrar sola la app.

### Entidades/GestionInventario

- [ ] **`ItemInventario`**: `+ setStockActual(stockActual: Decimal): void`. El diagrama de CUS-01 (paso 27) ya la usa (DI-20 a).
- [ ] **`AjusteConteo`**, descripción: `cantidad` es la diferencia con signo (contada − stock) y una diferencia cero también se registra, como constancia del conteo (DI-24 b).

### Interfaces/GestionInventario

- [ ] **`IMovimientoInventarioRepositorio`**:
  - Nueva `+ buscarFechaPrimerMovimiento(item: ItemInventario): DateTime?`: fecha del primer movimiento del ítem, de cualquier tipo y estado; marca el inicio de su historial para el consumo promedio (DI-25 b).
  - Descripción de `buscarUltimaEntrada`: solo la última entrada **VIGENTE**, y filtra por la tienda del ítem (DI-20 b, c).
  - Descripción de `listarSalidas`, `listarSalidasPorTienda`, `listarEntradasPorTienda` y `listarPorItem`: el periodo es `[desde, hasta)`, es decir, `hasta` no se incluye (DI-25 c, DI-28 b, DI-29 b, DI-32 a).
  - Descripción de `listarPorItem`: trae los movimientos en cualquier estado (VIGENTE, EN_REVISION o ANULADO) (DI-32 a).
- [ ] **`IVentaPerdidaRepositorio.listarPorProducto`**, descripción: no recibe la tienda; filtra por el producto y la tienda del producto (DI-25 c).

### Componentes/GestionInventario

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

- [ ] **`ServicioCaja`** (DI-21 b):
  - `+ idCaja(tienda: Tienda, dia: DateTime): String` (estática): id de la caja del día, `<tienda_id>_AAAA-MM-DD`; no es uuid.
  - `+ diaLocal(momento: DateTime): DateTime` (estática): día local del dispositivo, sin hora.
- [ ] **`Caja`**, descripción de `fecha`: es el día local, sin hora (un día calendario, no un instante) (DI-21 b).
- [ ] **`ServicioReportes`**, descripción de `generarReporteDiario`: la fecha es un día local, de su 00:00 a la 00:00 del día siguiente sin incluirla (DI-29 a).

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

### Componentes/Pagos

- [ ] **`ServicioVentas`**, descripción de `confirmar`: dentro de la transacción vuelve a leer el ítem de cada línea con `servicioInventario.obtenerItem` antes de crear la `SalidaVenta`. El ítem de la línea trae el stock del momento en que se agregó, y una entrada registrada con la venta abierta se perdería (DI-21 a).

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
- [ ] **CUS-13**: nota de que `VistaVenta` usa dos coordinadores (`RegistrarVentaCoordinator` y `RegistrarVentaPerdidaCoordinator`), única excepción a "una vista, un coordinador" (DI-30 c).
- [ ] **CUS-14** (DI-37 a, c, d):
  - `Caja`: el constructor acepta, como opcionales, los movimientos y los datos del cierre para armar una caja guardada.
  - Entre los pasos 12 y 13, la vista muestra la diferencia que quedaría con el efectivo escrito (solo para mostrar).
  - Break "Efectivo no válido" ("Escribe cuánto efectivo contó") para un efectivo vacío, no numérico o negativo.
  - Nota: la diferencia cero se muestra como "La caja cuadra".
- [ ] **CUS-17** (DI-34 b, d): nota de que `buscarPorLectura` quita los espacios y que una lectura vacía devuelve null sin buscar; en el alt "Lectura fallida", el lector desconectado no se puede detectar en modo teclado. Si el código no está registrado y hay resultados por nombre (se escribió un nombre y se oprimió Enter), quedan esos resultados.
- [ ] **CUS-18**, opt "Asociar código" (DI-34 b, f): break "Código vacío" ("Escriba o lea el código") antes del paso 21; si `otro` es el mismo producto, devuelve el código que ya tiene sin crear otro; en un producto nuevo el código se asocia después de `crearProducto`.
- [ ] **CUS-18**, opt "Etiquetas" (DI-35 a, b):
  - Break "Copias no válidas" ("Las copias deben estar entre 1 y 100") antes de generar las etiquetas.
  - Dice de qué código es la etiqueta: el QR del producto o, si no tiene, el primero que tenga.
  - Si falla el guardado del código nuevo, se quita del producto antes de relanzar el error.
- [ ] **CUS-21**: eliminar es anonimizar (nombre "Cliente eliminado", teléfono vacío), y la escritura se anota como ACTUALIZAR en la cola (DI-31 a, b).
- [ ] **CUS-24** (DI-25 b, e):
  - El consumo usa `movimientos.buscarFechaPrimerMovimiento(item)` para los días con datos.
  - Disparo: mientras no exista el Sincronizador (CUS-23), lo lanza `DisparadorAlertasDiarias` en cuanto hay usuario activo, una vez por tienda y día en cada arranque de la app, sin bloquear la pantalla.
- [ ] **CUS-25**: si el producto no tiene ítem, `consultarMovimientos` devuelve una lista vacía (DI-32 a).

## 4. Para decidir en el equipo

- [ ] **Operaciones asíncronas.** En Dart, toda operación que lee o escribe la base o la red devuelve `Future` (por ejemplo `IEstadoSincronizacion.hayPendientes` devuelve `Future<bool>`, DI-29 c). En EA aparecen con el tipo directo (`bool`, `List<X>`). Propuesta: dejar los tipos como están y agregar una nota general en el paquete `Interfaces` que lo diga, en vez de cambiar más de cien firmas.

## 5. Lo que no va en EA

- **Esquema de la base de datos.** El `.qea` no tiene tablas. El esquema está en `supabase/migrations/` (fuente de verdad) y en las tablas drift de `lib/data/local/tablas/`. Por ejemplo, la columna `clientes.eliminado_en` de DI-31 y la tabla `codigos_producto` de DI-34 ya están en las dos.
- **Mockups.** Varias DI piden cambios en el canvas de mockups, no en EA: DI-14, DI-21 (e), DI-24 (f), DI-25 (h), DI-26 (g, h), DI-27 (f), DI-28 (e), DI-29 (f) y DI-34 (e, f).
- **Un detalle que se corrige en el código.** `ServicioAlertas.diaLocal` es pública, no está en EA y nadie la usa fuera de la clase: se vuelve privada.
