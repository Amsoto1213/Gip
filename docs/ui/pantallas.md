# Mapa de pantallas → casos de uso

Mockups: https://claude.ai/artifact/LLuERSdfBGT8jr3QEvS8fJ (canvas "GIP — Mockups app móvil y web").
Exporten cada tablero como PNG a `docs/ui/mockups/` con el nombre de la columna "Archivo" para que Claude Code los pueda ver.

| Sección | Pantalla | Móvil | Web | CUS |
|---|---|---|---|---|
| Acceso | Inicio de sesión (correo y contraseña) | sin mockup | sin mockup | DI-05 |
| Paridad | Matriz de paridad móvil–web | — | `Paridad` | todos |
| Vender | Vender | `Main` | `Vender` | CUS-02 |
| Vender | Buscar producto | `mBuscar` | `Vender` | CUS-06, CUS-13 |
| Vender | Leer código (lector 2D o cámara) | `Escanear` | `Vender` (solo lector 2D) | CUS-17 |
| Vender | Cobrar | `Cobro` | `Vender` | CUS-02 |
| Vender | Fiar | `mFiar` | `wFiar` | CUS-07 |
| Surtido | Existencias | `mExistencias` | `wExistencias` | CUS-25 |
| Surtido | Entrada de mercancía | `Entrada` | `wEntrada` | CUS-01 |
| Surtido | Pérdida o devolución | `mPerdida` | `wPerdida` | CUS-03 |
| Surtido | Conteo físico | `mConteo` | `Conteo` | CUS-04 |
| Surtido | Producto | `mProducto` | `wProducto` | CUS-18 |
| Fiados | Clientes con fiado | `mClientes` | `wClientes` | CUS-19 |
| Fiados | Cliente | `Cliente` | `wClientes` | CUS-19, CUS-21 |
| Fiados | Abono | `mAbono` | `wClientes` | CUS-08 |
| Caja | Caja del día | `mCaja` | `wCaja` | CUS-11 |
| Caja | Cierre de caja | `mCierre` | `wCierre` | CUS-14 |
| Caja | Anular venta | `Anular` | `wAnular` | CUS-20 |
| Negocio | Resumen | `mNegocio` | `Panel` | — |
| Negocio | Alertas | `Alertas` | `wAlertas` | CUS-05 |
| Negocio | Reporte del día | `mReporte` | `Reporte` | CUS-10 |
| Negocio | Ganancia | `mMargen` | `wMargen` | CUS-09 |
| Negocio | Rotación | `mRotacion` | `wRotacion` | CUS-12 |
| Negocio | Usuarios | `mUsuarios` | `wUsuarios` | CUS-15 |
| Negocio | Exportar | `mExportar` | `wExportar` | CUS-16 |
| Negocio | Sincronización | `mConflictos` | `wConflictos` | CUS-22 |

CUS-17: según el diagrama, la cámara se usa solo en la app Android (`mobile_scanner`); en la web se lee con el lector 2D. Si la lectura falla (lector desconectado, permiso de cámara negado o código ilegible) se muestra el mensaje y se sigue con la búsqueda por nombre (CUS-06).

La pantalla de inicio de sesión no está en los mockups: hacerla simple con los tokens de `tokens.md` (logo o nombre, dos campos, botón primario verde).

Sin pantalla (procesos en segundo plano): CUS-23 Conciliar datos sincronizados, CUS-24 Generar alertas de reabastecimiento.
