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
| radios | tarjeta 22, tarjeta de acción 20, caja de ícono 14–16, chip 999 | |

## Componentes comunes (en `lib/presentation/comun/`)

1. **TarjetaGip**: la tarjeta base (fondo, borde, radio, sombra).
2. **SeccionNumerada**: tarjeta con encabezado "círculo verde con número + título" y línea divisoria.
3. **BotonPrimario** y **BotonSecundario** (contorno, texto verde).
4. **CampoGip**: campo con etiqueta arriba, ícono y estado de foco; variante contraseña con botón de ojo.
   Variante resaltada (borde `alerta`, para un valor por revisar) y cifras alineadas a la derecha.
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
13. **SelectorFiltro**: filtros de una lista en píldoras de 44 px ("Todos", "Contados"…); la elegida
    rellena en `navFondo` con texto blanco y las demás con contorno. No es una acción: no va en verde.

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
- **Conteo físico:** según `mConteo` y `Conteo`: avance "N de M contados" con barra, BarraBusqueda como
  campo y SelectorFiltro (Todos, Contados, Sin contar, Con diferencia · N). Web: tabla (Producto, Código,
  Según el sistema, Contado, Diferencia, Estado) y franja `navFondo` con la nota y "Confirmar ajuste de N
  productos". Móvil: filas en una TarjetaGip y el botón fijo abajo. La fila que supera el umbral va en
  `alertaFondo` con el campo resaltado, el aviso del diagrama y "Volver a contar" (DI-24).
- **Producto, Buscar producto, Vender y Cobrar:** aplicar los mismos componentes (tarjetas, campos, botones,
  chips), sin cambiar su funcionamiento.
