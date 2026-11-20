# Probar la sincronización (CUS-23, DI-47)

Las pruebas automáticas cubren el algoritmo con dos bases locales y un servidor falso. **No cubren Supabase de verdad**: eso se prueba aquí, con dos equipos y el proyecto de pruebas. Toma unos 20 minutos.

## Antes de empezar

1. **Aplicar las migraciones al proyecto de pruebas**, en especial `20261121090000_sincronizacion.sql` y `20261121100000_sincronizacion_tiempo_real.sql` (esta última hace que los cambios lleguen al instante) (la hace quien administra el proyecto: `npx supabase db push`, o pegar el archivo en el SQL Editor). Si falla, copiar el error: casi seguro es un nombre de restricción o un disparador.
2. En el proyecto de pruebas: *Authentication → Providers → Email → Confirm email* **desactivado** (ya lo pide DI-43) y una tienda con su propietario en `tiendas` y `usuarios`.
3. **Dos equipos con la misma tienda**: el APK (`docs/probar-en-telefono.md`) y Chrome (`flutter run -d chrome --dart-define-from-file=.env.json`) o dos teléfonos. Iniciar sesión en los dos con el mismo usuario (o con el propietario en uno y un empleado en otro).
4. Ver lo que pasa: en la terminal de `flutter run` aparece `Sincronización: Sincronizacion(subidos: …, bajados: …)`; en Supabase, *Table Editor*.

La app sincroniza sola: al entrar, al volver del segundo plano, al recuperar internet y cada 5 minutos. Para forzarlo, cerrar la app y volver a abrirla, o salir y entrar del modo avión.

## Recorrido

Marcar cada paso. **A** y **B** son los dos equipos.

| # | En | Hacer | Debe pasar |
|---|---|---|---|
| 1 | A | Crear un producto "Huevo AA" y registrar una entrada de 24 con factura `FV-1`. Mirar la terminal: en 1 a 2 segundos debe salir `Sincronización: … subidos: N` | En Supabase: filas en `productos`, `items_inventario` y `movimientos_inventario` (con `sincronizado_en` lleno). `precio_venta` como número |
| 2 | B | Tener la app abierta, con internet. **No hacer nada** | En 2 a 3 segundos la terminal de B muestra `bajados: N`. Los datos ya están en la base de B; **la pantalla que tengas abierta se refresca sola** (Surtido, Fiados, Caja, Ventas de hoy, Cierre de caja, Alertas, Ganancia, Rotación, Reporte del día y Revisar sincronización). Vender, Cobrar y los formularios (entrada, pérdida, conteo, producto) **no** se refrescan para no borrar lo que estás escribiendo: se ven al volver a abrirlos. Si B estaba cerrada, aparecen al abrirla. La existencia de Huevo AA es 24. B no debe quedar con pendientes: Negocio → Reporte del día no dice "sin sincronizar" |
| 3 | A | Modo avión. Vender 2 huevos y fiar a "María Pérez". Quitar el modo avión | La venta, la forma de pago y el fiado suben. B los ve al sincronizar. La existencia baja en B |
| 4 | A y B | Los dos en modo avión: cada uno registra **una entrada de 24 huevos con la misma factura `FV-2`** (una factura que **no** sea la del paso 1: si repites `FV-1`, el sistema ve tres entradas iguales y las muestra en **una sola tarjeta** con las tres entradas). Anotar la existencia de huevos antes. Quitar el modo avión de los dos | Negocio → Revisar sincronización (propietario): **un solo** conflicto "Posible registro repetido" con las dos entradas de `FV-2`. La más antigua queda vigente y la otra "En revisión" (no suma). La existencia en los dos equipos es la de antes **+ 24**, no + 48 |
| 5 | A y B | Resolver el conflicto de 4 en A: marcar las entradas que sí ocurrieron y "Guardar decisión" (la que dejes sin marcar se anula). Sincronizar B. Repetir los pasos 4 y 5 con otra factura (`FV-3`) para probar la otra opción | **Si marcas las dos** (o pulsas "Son registros distintos"): la entrada en revisión pasa a vigente y **suma**: la existencia queda en la de antes + 48 (79 si eran 31). **Si dejas sin marcar la segunda**: queda "Anulado" y la existencia sigue en la de antes + 24 (55). En los dos casos el conflicto y el aviso de Surtido desaparecen en los dos equipos |
| 6 | A y B | Los dos, sin internet, abonan al fiado de María lo que sobre (por ejemplo, el fiado es de $ 10.000 y cada uno abona $ 8.000). Reconectar | Conflicto "Abono mayor que el saldo" en los dos, con el mismo detalle. En `fiados` el `saldo_pendiente` queda **negativo** (por ejemplo, fiado de 18.000 y dos abonos de 10.000: -2.000, no 8.000). Si se queda en 8.000, el servidor rechazó el saldo: revisar las restricciones de `fiados` (consulta abajo) y aplicar la migración `20261121110000` |
| 7 | A y Supabase | Asociar un código de barras al producto en A y sincronizar; en B comprobar que aparece. Luego, en Supabase, `delete from public.codigos_producto where id = '<id>';` (la app no tiene pantalla para quitar un código, salvo al resolver un conflicto de código repetido) | En `registros_eliminados` aparece el borrado (lo pone el disparador) y A y B quitan el código en su siguiente sincronización |
| 8 | A y B | Sin internet, cambiar el precio del mismo producto: primero en A y **después** en B. Reconectar los dos | Gana el de B (el más reciente), en `productos` y en los dos equipos, sin importar quién sincronizó primero |
| 9 | A | Anular una venta; sincronizar. En B ver la venta anulada | Anulada en los dos; el stock vuelve |
| 10 | A | Cerrar sesión y volver a entrar | No se pierde nada; la cola sigue vacía |

## Qué mirar en Supabase

```sql
-- Lo que sigue sin subir no está aquí: está en cola_pendientes del equipo.
select tabla, count(*) from public.registros_eliminados group by tabla;
select id, estado, sincronizado_en from public.movimientos_inventario order by sincronizado_en desc limit 10;
select id, saldo_pendiente, estado from public.fiados;
select tipo, resuelto, ids_registros from public.conflictos_sincronizacion;
```

Restricciones de `fiados` (no debe haber ninguna `saldo_pendiente >= 0`):

```sql
select conname, pg_get_constraintdef(oid) from pg_constraint
where conrelid = 'public.fiados'::regclass and contype = 'c';
```

Probar los disparadores a mano (cambiar los ids por los reales):

```sql
-- Una edición más vieja no pisa a la nueva (debe quedar con el nombre anterior):
update public.productos set nombre = 'prueba', actualizado_en = '2020-01-01' where id = '<id>';
-- Lo anulado no se revierte (debe seguir ANULADO):
update public.movimientos_inventario set estado = 'VIGENTE' where id = '<id de un movimiento anulado>';
```

## Si algo falla

- **"sin conexión" en la terminal pero hay internet**: casi siempre es `SUPABASE_URL` o la llave de `.env.json`, o la sesión vencida. Cerrar sesión y entrar de nuevo.
- **Un registro no sube**: queda en `cola_pendientes` con `intentos` mayor que 0 (se ve con el inspector de la base del navegador o con `adb`). Copiar el error del servidor; lo más común es una llave foránea (falta un padre) o una regla de la tabla.
- **Quedó algo a medias**: anotar el paso de la tabla de arriba, qué dice cada equipo y la salida de las consultas SQL.
- Lo que baja un equipo **nunca** se vuelve a subir (no se anota en la cola): si ves que un registro "rebota" entre equipos, es un error.
