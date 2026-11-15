# Rediseño visual del GIP

Propuesta aprobada el 14 de noviembre de 2026. Mantiene la estructura de los mockups de `docs/ui/mockups/`
(qué hay en cada pantalla) y cambia el aspecto: más jerarquía, tarjetas con sombra suave, íconos y mejor
organización. Los colores base y las fuentes son los de `docs/ui/tokens.md`.

Los archivos `.html` de esta carpeta son la fuente exacta del diseño (colores, medidas, radios, sombras y
textos). Son prototipos en HTML: la sintaxis `{{ }}`, `<sc-for>` y `<sc-if>` es del editor de diseño y se
ignora; lo que importa son los estilos y la estructura.

| Archivo | Pantalla |
|---|---|
| `login-web.html` | Inicio de sesión, web |
| `login-movil.html` | Inicio de sesión, móvil |
| `surtido-web.html` | Surtido, web (con el menú lateral nuevo) |
| `surtido-movil.html` | Surtido, móvil (con la barra inferior nueva) |
| `perdida-web.html` | Pérdida o devolución, web: patrón para todos los formularios de movimiento |
| `conteo-web.html` | Conteo físico, web: tabla con estado por fila |
| `conteo-movil.html` | Conteo físico, móvil |

## Reglas generales

- **Las acciones van solo en verde** (`primario` y `primarioSuave`). El amarillo (`alerta*`) y el rojo
  (`error*`) se usan solo para estados: "Poco", "Agotado", errores y lo que se resta.
- **Tarjetas:** fondo `superficie`, borde 1 px `borde`, radio 22 px, sombra `tarjeta`.
- **Botón principal:** 56–58 px de alto, radio 16 px, `primario`, texto blanco 17 px peso 700, ícono a la
  derecha o a la izquierda, sombra `botonPrimario`. Hover y presionado con `primarioOscuro`.
- **Campos:** 52–54 px de alto, radio 14 px, borde 1,5 px `bordeFuerte`, ícono a la izquierda en
  `textoSecundario`. Con foco: borde `primario` y halo `rgba(11,107,75,0.14)` de 4 px.
- **Títulos de pantalla:** Archivo 800, 34 px web / 30 px móvil, interletrado −0,02 em, con una línea de
  contexto debajo en `textoSecundario`.
- **Números importantes** (existencias, cantidades, totales): Archivo 800 y cifras tabulares.
- Toda la interfaz en español y sin funcionalidad nueva: el rediseño cambia el aspecto, no lo que hace la app.

## Tokens nuevos (agregar al tema)

| Token | Valor | Uso |
|---|---|---|
| `sombraTarjeta` | `0 1px 2px rgba(19,32,27,0.04), 0 8px 24px rgba(19,32,27,0.05)` | tarjetas normales |
| `sombraElevada` | `0 1px 2px rgba(19,32,27,0.04), 0 22px 56px rgba(19,32,27,0.10)` | tarjeta del login, resumen |
| `sombraBotonPrimario` | `0 6px 16px rgba(11,107,75,0.28)` | botón principal |
| `superficieSuave` | `#F7F9F7` | encabezados de tabla, filas al pasar el mouse, caja del producto |
| `pasoFondo` | `#EEF3F0` | botones − y + |
| `navFondo` | `#13201B` | menú lateral web y caja oscura del resumen |
| `navTexto` / `navTextoSecundario` | `#C9D3CE` / `#9FB0A8` | textos del menú lateral |
| `verdeCirculoClaro` / `verdeCirculoOscuro` | `#0E7A56` / `#095C40` | círculos decorativos del login |
| `errorFondoSuave` | `#FFF5F4` | fila con diferencia grande o con error (conteo) |
| `errorBorde` / `errorTexto` | `#F3C1BC` / `#8C1D18` | tarjeta de aviso en rojo |
| `sombraPestana` | `0 1px 3px rgba(19,32,27,0.12)` | pestaña de filtro elegida |
| radios | tarjeta 22 (18 en listas del móvil), tarjeta de acción 20, caja de ícono 14–16 (12 en tabla), chip 999, pestañas 14 / 11 | |

## Componentes comunes (en `lib/presentation/comun/`)

1. **TarjetaGip**: la tarjeta base (fondo, borde, radio, sombra).
2. **SeccionNumerada**: tarjeta con encabezado "círculo verde con número + título" y línea divisoria.
3. **BotonPrimario** y **BotonSecundario** (contorno, texto verde).
4. **CampoGip**: campo con etiqueta arriba, ícono y estado de foco; variante contraseña con botón de ojo.
   Variante resaltada (borde `error`, para un valor por revisar o no válido, con el mensaje fuera del
   campo), cifras alineadas a la derecha y letra propia (`estiloTexto`, Archivo 800 en cantidades).
5. **BarraBusqueda**: campo grande de búsqueda (58 px web / 52 px móvil) con el botón oscuro del lector al
   lado. Mientras no exista CUS-17, el botón del lector no se muestra.
6. **TarjetaAccion**: caja de ícono `primarioSuave` con el ícono en `primario`, título 17 px peso 700 y una
   línea de descripción. En móvil, versión vertical (ícono arriba, título abajo).
7. **ChipEstado**: "Poco" (alerta) y "Agotado" (error), en forma de píldora.
8. **OpcionConIcono**: opción seleccionable (motivo) con caja de ícono, título, descripción y círculo de
   verificación. Elegida: borde 2 px `primario` y fondo `primarioSuave`.
9. **ResumenMovimiento**: caja superior oscura (`navFondo`) con "Hay ahora N → Quedará en N" (el segundo
   número en una píldora `primario` con texto blanco) y una barra: lo que queda en `primario` y lo que se
   quita en blanco. Debajo, filas de detalle y el botón principal.
10. **MenuLateral** (web): bloque de la tienda (logo, nombre y ciudad), secciones con ícono, subsecciones de
    la sección activa, y al final el usuario (iniciales, nombre y rol). La sección activa con fondo
    `primario`; la subsección activa con fondo blanco al 8 %.
11. **BarraInferior** (móvil): 5 secciones; la activa con el ícono dentro de una píldora `primarioSuave`.
12. **LogoGip**: cuadro redondeado con el ícono de paquete (inventory_2 o equivalente) y "GIP" en Archivo
    800. Fondo blanco con el ícono en `primario` sobre fondos verdes; al revés sobre fondos claros.
13. **SelectorFiltro**: filtros de una lista ("Todos", "Contados"…), de 44 px de alto y sin tomar el foco.
    En píldoras (móvil, 13 px): la elegida rellena en `navFondo` con texto blanco y las demás con
    contorno. En pestañas (web, encima de una tabla): grupo en `fondo` con radio 14 y la elegida en
    blanco con `sombraPestana`. No es una acción: no va en verde.
14. **PildoraEstado**: estado de una fila (13 px, peso 700): verde (`primarioSuave`, "Cuadra"), gris
    (`fondo`, "Se ajusta"), rojo (`errorFondo`, "Diferencia grande"), blanco con borde punteado
    (`bordeFuerte`, "Sin contar") o azul (`info` con `infoTexto`, "Provisional").
15. **TarjetaAviso**: aviso en rojo: fondo `errorFondo`, borde `errorBorde`, caja blanca de 44 px con el
    ícono en `error`, título y texto en `errorTexto`. El texto es opcional (solo el título, centrado con
    el ícono).
16. **NotaInfo**: nota que explica cómo leer un dato (mockups `Alertas` y `wAlertas`): fondo `info`,
    ícono de información y texto 15 px en `infoTexto`, con una parte destacada en negrilla al comienzo
    ("**Provisional =** lleva menos de 30 días…"). No es una acción ni un error.
17. **TarjetaCifra**: cifra pequeña en una tarjeta blanca (radio 18) con etiqueta 14 px, valor 19 px con
    cifras tabulares y detalle (mockups `mFiar` y `wFiar`: "Total", "Ya pagó", "Falta"). Lo que falta o
    se resta va en `errorTexto`.
18. **OpcionRadio**: fila de una lista de opción única (los clientes al fiar): círculo de radio, título en
    negrilla, subtítulo y un valor a la derecha (en `errorTexto` si es una deuda). Elegida: fondo
    `primarioSuave` y radio `primario`. Sin borde propio: va dentro de una TarjetaGip con separadores;
    56 px de alto mínimo.

## Pantallas

- **Inicio de sesión:** web en dos mitades. A la izquierda el panel `primario` con punteado blanco al 10 %,
  dos círculos decorativos, el logo grande (104 px), "GIP" 64 px, "Gestor de Inventario Predictivo" y
  "Bienvenido de nuevo". A la derecha, el formulario en una tarjeta con `sombraElevada`. En móvil, el panel
  verde va arriba (330 px, esquinas inferiores de 32 px) con el logo y el nombre, y el formulario se monta
  encima. Debajo del botón, los dos avisos: abre sin internet y la contraseña la cambia el administrador.
- **Surtido:** título con la línea de contexto, botón "Producto nuevo" arriba a la derecha (en móvil, botón
  cuadrado con +), la BarraBusqueda (abre Buscar producto) y las TarjetaAccion de Entrada, Pérdida y
  Conteo físico. La tabla de existencias con filtros y ChipEstado llega con CUS-25: no mostrar
  datos inventados mientras tanto.
- **Pérdida o devolución:** sección 1 "Producto y cantidad" (producto a la izquierda, cantidad a la derecha,
  separados por una línea; solo el atajo "Todas (N)"); sección 2 "Motivo" con OpcionConIcono en 2×2 y las
  descripciones "Pasó la fecha de vencimiento", "Roto, mojado o abierto", "Se lo lleva el proveedor" y
  "Cualquier otra razón"; a la derecha el ResumenMovimiento.
- **Entrada de mercancía:** el mismo patrón que Pérdida: sección 1 "Producto y cantidad", sección 2 "Costo y
  factura" y el ResumenMovimiento (sin barra de lo que se quita: aquí el stock sube).
- **Conteo físico** (`conteo-web.html`, `conteo-movil.html`, DI-24):
  - **Web:** arriba, la tarjeta "Avance del conteo" con "N de M contados" (número en Archivo 800, 30 px)
    y la barra (`primario` sobre `separador`, 10 px) y "Los productos sin contar no cambian."; a su lado,
    solo si hay, la TarjetaAviso "N diferencias grandes" con el mensaje del diagrama ("La diferencia
    supera el umbral. Revise el conteo antes de confirmar"), sin el número del umbral. Debajo, una
    tarjeta con la BarraBusqueda como campo y el SelectorFiltro en pestañas (Todos · N, Contados · N,
    Sin contar · N, Con diferencia · N) y la tabla: encabezado en mayúsculas sobre `superficieSuave` y
    columnas Producto (caja de ícono, nombre y unidad), Según el sistema, Contado (campo de 120 px),
    Diferencia (Archivo 800, 18 px) y Estado. Por debajo de 780 px la tabla se desplaza de lado. Al
    final, una tarjeta blanca solo con "Confirmar ajuste de N productos" a la derecha.
  - **Móvil:** tarjeta de avance (radio 18) con la PildoraEstado roja "N por revisar"; BarraBusqueda;
    SelectorFiltro en píldoras (Todos, Sin contar · N, Diferencia · N); las filas en una TarjetaGip con
    nombre, "Según el sistema: N", el campo de 92 px y la diferencia, y el mensaje en rojo debajo cuando
    hay. Barra blanca fija abajo solo con "Confirmar ajuste de N".
  - **Estados de la fila:**

    | Estado | Fila | Campo | Diferencia | Estado (web) / mensaje (móvil) |
    |---|---|---|---|---|
    | Sin contar | `superficie` | normal, "—" | "—" gris | píldora punteada "Sin contar" |
    | Cuadra | `superficie` | normal | "0" en `primario` | píldora verde "Cuadra" |
    | Se ajusta | `superficie` | normal | "+2" / "−1" en `texto` | píldora gris "Se ajusta" |
    | Diferencia grande | `errorFondoSuave` | borde `error` | en `error` | píldora roja "Diferencia grande" / el mensaje del diagrama |
    | Error (negativa, decimales en unidades) | `errorFondoSuave` | borde `error` | "—" en `error` | el mensaje en `error` ("La cantidad contada no puede ser negativa") |

  - Las advertencias van en rojo, no en amarillo. No hay "Volver a contar" ni "Pausar": el número se
    corrige en el mismo campo. Confirmar queda desactivado mientras una fila tenga error.
- **Alertas de surtido** (mockups `Alertas` y `wAlertas`, CUS-05, DI-25): título con "Calculadas hoy. Son
  sugerencias: usted decide qué comprar."; SelectorFiltro en pestañas "Por surtir · N" y "Ventas perdidas · N".
  - **Web:** tabla en una TarjetaGip (encabezado en mayúsculas sobre `superficieSuave`): Producto (con la
    PildoraEstado azul "Provisional"), Hay, Vende al día, Se fueron sin comprar y Alcanza para ("N días" en
    `error`, Archivo 800). A la derecha (desde 1100 px; debajo si no cabe) la tarjeta "Cómo leerlas" con la
    NotaInfo de Provisional.
  - **Móvil:** una TarjetaGip (radio 18) por alerta: a la izquierda el bloque `errorFondo` de 84 px con el
    número de días en `error`; a la derecha el nombre, "Provisional" y Hay · Vende/día · No hubo N veces.
    La NotaInfo va debajo si hay alguna provisional.
  - Las advertencias van en rojo, no en amarillo. Sin "Urgente"/"Pronto", hora del cálculo, "Datos de N
    días", barra de "Alcanza para" ni "Armar lista de pedido". Sin alertas: "No hay productos por agotarse".
    Al empleado: TarjetaAviso "Esta consulta es solo para el propietario".
- **Fiar** (mockups `mFiar` y `wFiar`, CUS-07, DI-26): en el móvil, pantalla hija de Cobrar con
  EncabezadoPantalla ("Cobrar" / "Fiar parte de la venta") y el botón fijo abajo; en la web, diálogo sobre
  Cobrar (radio 22, ancho 720) con la X, "Cancelar" y "Agregar fiado al pago". Tres TarjetaCifra (Total,
  Ya pagó, Falta en rojo), BarraBusqueda como campo, la lista de clientes con OpcionRadio ("debe $ N" en
  rojo o "$ 0") y "+ Cliente nuevo (nombre y teléfono)", que abre ahí mismo los dos CampoGip. Debajo, el
  monto con su ayuda y la frase "X quedará debiendo $ N en total.". Las advertencias van en rojo.
- **Producto, Buscar producto, Vender y Cobrar:** aplicar los mismos componentes (tarjetas, campos, botones,
  chips), sin cambiar su funcionamiento.
