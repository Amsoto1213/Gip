# CUS-16 Exportar datos del negocio

Diagrama de secuencia exportado de EA (3.3.16 CUS-16 Exportar datos del negocio).

## Participantes

- `Propietario` (Actor)
- `VistaExportacion` (Sequence)
- `coordinador` : `ExportarDatosCoordinator`
- `servicioAcceso` : `ServicioAcceso`
- `servicioExportacion` : `ServicioExportacion`
- `items` : `IInventarioRepositorio`
- `ventas` : `IVentaRepositorio`
- `fiados` : `IFiadoRepositorio`
- `exportador` : `IExportador`
- `datos` : `DatosExportacion`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- _Nota: formato : FormatoExportacion (CSV o EXCEL)._
- 1. `Propietario` → `VistaExportacion`: exportar(desde, hasta, formato)
- _Nota: Control de acceso por rol detallado en CUS-05: si el usuario no es propietario, se rechaza (RNF-12)._
- 2. `VistaExportacion` → `coordinador`: exportar(tienda, desde, hasta, formato, usuario)
- 3. `coordinador` → `servicioAcceso`: exigirPropietario(usuario)
- 4. `servicioAcceso` → `coordinador`: retorno
- 5. `coordinador` → `servicioExportacion`: exportar(tienda, desde, hasta, formato)
- **[break Periodo no válido | desde > hasta]**
  - 6. `servicioExportacion` → `coordinador`: error("Periodo no válido")
  - 7. `coordinador` → `VistaExportacion`: error("Periodo no válido")
  - 8. `VistaExportacion` → `Propietario`: mostrar("La fecha inicial no puede ser posterior a la final")
- 9. `servicioExportacion` → `items`: listarItems(tienda)
- 10. `items` → `servicioExportacion`: items
- 11. `servicioExportacion` → `ventas`: listarPorPeriodo(tienda, desde, hasta)
- 12. `ventas` → `servicioExportacion`: ventas
- 13. `servicioExportacion` → `fiados`: listar(tienda)
- _Nota: Inventario con su stock, ventas del periodo con sus formas de pago y anulaciones, y fiados con sus abonos._
- 14. `fiados` → `servicioExportacion`: fiados
- 15. `servicioExportacion` → `datos`: DatosExportacion(ahora, desde, hasta, formato, items, ventas, fiados)
- 16. `servicioExportacion` → `exportador`: exportar(datos)
- _Nota: Protected Variations: la Data Layer escribe el archivo en datos.getFormato(), con una hoja o archivo para inventario, ventas y fiados (paquetes csv, excel y share_plus de Flutter); la Business Layer no sabe cómo se escribe (DA-68)._
- 17. `exportador` → `servicioExportacion`: nombreArchivo
- 18. `servicioExportacion` → `coordinador`: nombreArchivo
- 19. `coordinador` → `VistaExportacion`: nombreArchivo
- 20. `VistaExportacion` → `Propietario`: mostrar("Datos exportados: " + nombreArchivo)
- _Nota: La pantalla permite guardar o compartir el archivo (RNF-22)._
