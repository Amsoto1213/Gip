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
