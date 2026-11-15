# Tokens de interfaz (tomados de los mockups "GIP — Mockups app móvil y web")

Implementar en `lib/presentation/comun/tema/` (`ColorScheme` + `TextTheme` de Material 3). No usar colores sueltos en los widgets.

## Color

| Token | Hex | Uso |
|---|---|---|
| primario | `#0B6B4B` | botones principales (Cobrar), navegación activa, enlaces |
| primarioOscuro | `#08523A` | hover / presionado |
| primarioSuave | `#E3F1EA` | fondos de chips y botones secundarios verdes |
| fondo | `#F3F5F2` | fondo de pantalla |
| superficie | `#FFFFFF` | tarjetas, barra de navegación, hojas |
| texto | `#13201B` | texto principal |
| textoSecundario | `#4A5852` | etiquetas, precios unitarios, íconos inactivos |
| borde | `#DCE2DE` | bordes de tarjetas |
| bordeFuerte | `#C7D0CB` | bordes de campos y botones contorno |
| separador | `#EEF1EF` | líneas entre filas |
| alerta | `#F2A500` | insignia de alertas |
| alertaFondo / alertaBorde / alertaTexto | `#FFF4D6` / `#F2C14E` / `#6B4200` | producto con poca existencia |
| info / infoTexto | `#E4EDF9` / `#1E3F73` | indicador "Sin internet · N por subir" (RNF-09) |
| error / errorFondo | `#B3261E` / `#FCE8E6` | acciones destructivas (Anular venta), errores |
| errorFondoSuave | `#FFF5F4` | fila de una lista con un valor por revisar o con error (conteo) |
| errorBorde / errorTexto | `#F3C1BC` / `#8C1D18` | tarjeta de aviso en rojo ("N diferencias grandes") |
| velo | `rgba(12,21,18,0.55)` | fondo detrás de hojas modales |

## Tipografía

- Títulos: **Archivo** 800 (título de pantalla 30 px móvil; 23 px en pantallas internas; secciones 19–22 px).
- Texto: **Inter** 400–700, base 16 px; secundario 14–15 px.
- Montos con cifras tabulares (`FontFeature.tabularFigures()`), formato `$ 13.400` (COP, punto de miles, sin decimales).
- Fuentes empaquetadas en `assets/fonts/` (funcionan sin internet; no depender de descargarlas en tiempo de ejecución).

## Forma y tamaño

- Radios: 14 px campos y botones, 16 px botón principal, 20 px tarjeta "Venta actual", 26 px hoja inferior, 999 px chips.
- Áreas táctiles ≥ 44 px; botón principal 56–60 px de alto.
- Navegación móvil inferior de 72 px con 5 secciones: **Vender, Surtido, Fiados, Caja, Negocio** (insignia en Negocio con el número de alertas).
- Web: mismas 5 secciones; ancho de diseño 1280–1440 px, adaptable (RNF-20). Mismas acciones en móvil y web (ver tablero "Matriz de paridad").
- Íconos de trazo (estilo Lucide). Sin emoji.

## Rediseño visual (14 nov 2026)

Detalle en `docs/ui/rediseno/README.md` y en sus prototipos HTML. En código: colores en `ColoresGip`/`ColoresExtraGip` (`tema/colores_gip.dart`), radios y sombras en `FormaGip` (`tema/forma_gip.dart`).

| Token | Valor | Uso |
|---|---|---|
| superficieSuave | `#F7F9F7` | encabezados de tabla, filas al pasar el mouse, caja del producto |
| pasoFondo / pasoFondoActivo | `#EEF3F0` / `#DCE7E1` | botones − y + (normal / mouse encima) |
| navFondo | `#13201B` | menú lateral web y caja oscura del resumen |
| navTexto / navTextoSecundario | `#C9D3CE` / `#9FB0A8` | textos del menú lateral |
| verdeCirculoClaro / verdeCirculoOscuro | `#0E7A56` / `#095C40` | círculos decorativos del login |
| sombraTarjeta | `0 1px 2px rgba(19,32,27,.04), 0 8px 24px rgba(19,32,27,.05)` | tarjetas normales |
| sombraElevada | `0 1px 2px rgba(19,32,27,.04), 0 22px 56px rgba(19,32,27,.10)` | tarjeta del login, resumen |
| sombraBotonPrimario | `0 6px 16px rgba(11,107,75,.28)` | botón principal |
| haloFoco | `0 0 0 4px rgba(11,107,75,.14)` | campo con foco |
| sombraPestana | `0 1px 3px rgba(19,32,27,.12)` | pestaña de filtro elegida |

- Radios: tarjeta 22, tarjeta de acción 20, caja de ícono 14–16, campos 14, botón principal 16, chip 999, grupo de pestañas 14 y pestaña 11.
- Campos: 52–54 px de alto, borde 1,5 px `bordeFuerte`; con foco, borde `primario` y halo.
- Botón principal: 56–58 px, texto 17 px peso 700; hover y presionado en `primarioOscuro`.
- Títulos de pantalla: Archivo 800, 34 px web / 30 px móvil (23 px en pantallas internas del móvil), interletrado −0,02 em.
- Las acciones van solo en verde; amarillo y rojo solo para estados ("Poco", "Agotado", errores, lo que se resta).
