# Manual del usuario — GIP

**GIP (Gestor de Inventario Predictivo)** es la app de su tienda para vender, controlar el surtido, anotar fiados, llevar
la caja y ver cómo va el negocio. Le avisa qué productos se le están acabando. Funciona en el **celular Android** y en el
**computador** (navegador), y **sigue funcionando sin internet**: lo que usted anote se guarda en el equipo y se sube solo
cuando vuelve la conexión.

> **Sobre este manual.** Está escrito a partir de las pantallas y los casos de uso de la versión actual (consulte
> `docs/diseno/casos-de-uso.md`). No lleva capturas. Los diseños de cada pantalla están en `docs/ui/mockups/`. Cuando una
> pantalla cambie, hay que actualizar la sección correspondiente.

## Contenido

1. [Antes de empezar](#1-antes-de-empezar)
2. [Iniciar y cerrar sesión](#2-iniciar-y-cerrar-sesión)
3. [Cómo está organizada la app](#3-cómo-está-organizada-la-app)
4. [Vender](#4-vender)
5. [Surtido](#5-surtido)
6. [Fiados](#6-fiados)
7. [Caja](#7-caja-solo-administrador)
8. [Negocio](#8-negocio-solo-administrador)
9. [Trabajar sin internet](#9-trabajar-sin-internet)
10. [Lector de códigos](#10-lector-de-códigos)
11. [Problemas frecuentes](#11-problemas-frecuentes)
12. [Lo que la app todavía no hace](#12-lo-que-la-app-todavía-no-hace)
13. [Glosario](#13-glosario)

---

## 1. Antes de empezar

### Dónde se usa

| Equipo | Qué necesita |
|---|---|
| **Computador** | Las dos últimas versiones de **Chrome, Edge o Firefox** de escritorio. La dirección web se la da el administrador de la tienda. |
| **Celular Android** | Android 8.0 o superior. Se instala el archivo **.apk** que le entrega el administrador. |

No se puede usar en Safari, en iPhone ni en el navegador del celular Android: en el celular se usa la app instalada.
La pantalla del celular debe tener al menos 360 píxeles de ancho (cualquier celular actual); en el computador se ve mejor
desde 1024 píxeles.

### Instalar la app en Android

1. Abra el archivo **.apk** que le entregó el administrador.
2. La primera vez, Android le pide permitir **"Instalar apps desconocidas"** para el navegador o el gestor de archivos.
   Acepte.
3. Toque **Instalar**. Si aparece el aviso de Play Protect, elija **"Instalar de todas formas"**.
4. Cuando salga una versión nueva, se instala encima de la anterior y **sus datos se conservan**. No desinstale la app para
   actualizar: **al desinstalarla se borran los datos que no se hayan subido**.

### Quién puede hacer qué

Hay dos tipos de usuario:

| | **Administrador** (propietario) | **Empleado** |
|---|---|---|
| Vender | Sí | Sí |
| Surtido (existencias, entradas, pérdidas, conteo, productos) | Sí | Sí |
| Fiados y abonos | Sí | Sí |
| Caja (movimientos, cierre, anular ventas) | Sí | No |
| Negocio (alertas, reportes, ganancia, usuarios, exportar) | Sí | No |

En el celular, el empleado ve 3 pestañas (Vender, Surtido, Fiados) y el administrador ve 5.

---

## 2. Iniciar y cerrar sesión

### Iniciar sesión

1. Abra la app. Verá **"Bienvenido de nuevo"** y el formulario **Iniciar sesión**.
2. Escriba el **Correo** y la **Contraseña** de su tienda.
3. Toque **Entrar**.

- **La primera vez necesita internet.** Después de entrar, la app abre directo aunque no haya conexión.
- Si el correo o la contraseña no son correctos, la app se lo dice y puede intentar de nuevo.
- Si el correo no está registrado en ninguna tienda, no podrá entrar: pida al administrador que lo agregue.
- **¿Olvidó la contraseña?** La pantalla dice que le pida al administrador de la tienda que la cambie. Hoy la app no tiene
  una pantalla para eso; vea la [sección 12](#12-lo-que-la-app-todavía-no-hace).

### Cerrar sesión

El administrador toca **Negocio → Cerrar sesión**. La app vuelve a la pantalla de inicio de sesión. Si no cierra sesión,
la siguiente vez la app abre directo con su usuario.

---

## 3. Cómo está organizada la app

La app tiene cinco secciones: **Vender, Surtido, Fiados, Caja y Negocio**.

- **En el celular** están abajo, en una barra de pestañas. Tocar la pestaña en la que ya está lo lleva a su pantalla
  principal.
- **En el computador** (pantalla de 1024 píxeles o más) están en un **menú lateral** a la izquierda, con sus subsecciones
  debajo. Arriba se ve su nombre y si es **Administrador** o **Empleado**.

| Sección | Qué hay dentro |
|---|---|
| **Vender** | Venta actual, buscar producto, cobrar, fiar |
| **Surtido** | Existencias · Entrada de mercancía · Pérdida o devolución · Conteo físico · Producto nuevo |
| **Fiados** | Clientes con lo que deben, abonos |
| **Caja** | Movimientos · Ventas de hoy · Cierre de caja |
| **Negocio** | Alertas de surtido · Reporte del día · Ganancia por producto · Rotación · Usuarios · Revisar sincronización · Exportar datos · Cerrar sesión |

Los mensajes de la app están en el lenguaje de la tienda, por ejemplo: **"No hay suficiente existencia del producto"**.

---

## 4. Vender

Es la pantalla principal. Arriba dice **"Hola, \<su nombre\>"**.

### Hacer una venta

1. Toque **Buscar producto…** y escriba el nombre, o lea el código del producto con el lector (ver
   [sección 10](#10-lector-de-códigos)).
2. Toque el producto en los resultados.
3. Si el producto se vende por peso, la app pregunta **"¿Cuántos kilos de …?"** o **"¿Cuántas libras de …?"**. Escriba la
   cantidad (por ejemplo `3,4`) y toque **Aceptar**. Si se vende por unidad, pregunta **"¿Cuántas unidades?"**.
4. El producto aparece en **Venta actual**. Repita para los demás productos.
5. En cada producto de la venta puede tocar **Agregar uno** o **Quitar uno**. **Vaciar** deja la venta en blanco.
6. Cuando termine, toque **Cobrar**.

### Cobrar

La pantalla **Cobrar** muestra el **Total a pagar** y **¿Cómo paga?**. Puede **combinar hasta 3** formas de pago:

| Forma de pago | Qué hacer |
|---|---|
| **Efectivo** | Escriba el **Efectivo recibido**. La app calcula el **Cambio a devolver**. |
| **Nequi** | Escriba el **Monto por Nequi** y, si quiere, la **Referencia de Nequi** (opcional, por ejemplo `4471`). |
| **Fiado** | Fíe todo o lo que falta a un cliente. Toque **Elegir cliente y monto** (ver abajo). |

Mientras los pagos no cubren el total, la app muestra **"Falta $ …"**. Cuando están completos dice **"Pago completo"** (con el
cambio, si lo hay). Si los pagos pasan el total, se lo avisa.

Cuando todo cuadre, toque **Confirmar venta**. En un solo paso la venta **se descuenta del surtido y entra a la caja**, y
la app vuelve a Vender.

### Fiar una venta

Desde Cobrar, en **Fiado**, se abre **Fiar parte de la venta**:

1. **¿A quién le fía?** Busque al cliente por nombre. Si no existe, elija **Cliente nuevo** y escriba su **nombre** y su
   **teléfono** (opcional); toque **Registrar cliente**. *Los clientes se crean al fiar.*
2. **¿Cuánto queda fiado?** Escriba un valor mayor que cero.
3. Toque **Agregar fiado al pago**.

El fiado **solo se guarda cuando usted confirma la venta**. Con **Cambiar fiado** o **Quitar** puede corregirlo antes. Si
el cliente ya tiene fiados, la app le muestra cuántos fiados pendientes tiene.

### Si el producto no tiene existencia

Si intenta vender más de lo que hay, la app dice **"No hay suficiente existencia del producto"** y aparece el botón
**Anotar que se fue sin él**. Tóquelo para dejar registrado que un cliente quiso comprar ese producto y no había. Esa
información sale después en **Alertas de surtido → Ventas perdidas** y ayuda a decidir qué comprar.

---

## 5. Surtido

**Surtido** es el inventario de la tienda. Arriba dice cuántos productos hay (**"N productos"**).

### Ver las existencias

La lista muestra cada producto con lo que hay. Los que se están acabando salen marcados **Poco** y los que no tienen salen
**Agotado**. Use **Buscar en el surtido…** para encontrar uno. La lista se actualiza sola al volver de una acción o de
otra pestaña (por ejemplo, después de una venta).

### Buscar un producto

**Buscar producto** encuentra productos por **nombre** o por **código** (leído con el lector). Si no lo encuentra, toque
**Crear producto** (o **Crear producto con este código** si leyó un código): **"Créelo y quedará en el catálogo"**.

### Producto nuevo o editar un producto

Toque **Producto nuevo**, o un producto de la lista para editarlo. El mismo formulario sirve para las dos cosas.

| Campo | Qué escribir |
|---|---|
| **Código interno** | Un código propio para ese producto. Es obligatorio al crear, **no se puede repetir** en la tienda y **no se cambia** después. |
| **Nombre** | Cómo lo reconoce usted. |
| **Se vende por** | **Unidad**, **Kilo** o **Libra**. |
| **Precio de venta** | Lo que cobra al cliente. |
| **Costo (opcional)** | Lo que le costó. Cada entrada de mercancía lo actualiza con su costo. |

Toque **Guardar producto**.

**Códigos del producto.** Asocie el código de barras o QR del empaque para encontrarlo leyéndolo: toque **Asociar código**,
dispare el lector o escriba el código (en Android también puede **Leer con la cámara**), y toque **Asociar**. Puede asociar
varios con **Asociar otro código**.

**Etiquetas QR.** Con el producto ya guardado, el panel **Etiquetas QR** permite elegir el número de **Copias** y tocar
**Imprimir etiquetas**.

### Entrada de mercancía

Use esta pantalla cuando **llega mercancía del proveedor**. Suma al surtido lo que llegó.

1. **Producto y cantidad:** elija **¿Qué producto llegó?** (la búsqueda se abre sola) y escriba **¿Cuántas unidades
   llegaron?**
2. **Costo y factura:** escriba el **Costo por unidad** y, si quiere, el **N.º de factura** (por ejemplo `FV-10231`).
3. Toque **Registrar entrada**. En la web, a la derecha ve el resumen con el **Total de la compra**.

### Pérdida o devolución

Use esta pantalla para sacar del surtido lo que **se venció, se dañó o se le devolvió al proveedor**.

1. **Producto y cantidad:** elija **¿Qué producto sale?** (la app muestra **"Hay …"**) y **¿Cuántas salen del surtido?**.
   **Todas** deja la cantidad en lo que hay. Verá cómo queda la **Existencia**.
2. **Motivo (obligatorio).** Elija uno: **Pasó la fecha de vencimiento**, **Roto, mojado o abierto**, **Se lo lleva el
   proveedor** o **Cualquier otra razón**. Sin motivo no se puede confirmar.
3. Toque **Registrar pérdida**.

El motivo queda guardado y aparece en el reporte de pérdidas del mes.

### Conteo físico

Use el conteo para comparar lo que hay en el estante con lo que dice el sistema y **corregir la existencia**.

1. Busque cada producto (o use los filtros **Todos**, **Contados**, **Sin contar**, **Con diferencia**).
2. Escriba cuánto hay en el campo **Contado**. La app muestra la **Diferencia** y el **Estado** de la fila:
   **Cuadra**, **Se ajusta**, **Diferencia grande** o **Sin contar**. Si se equivocó, corrija el número en el mismo campo.
3. Arriba ve el avance (**"N de M contados"**) y una tarjeta roja con las diferencias grandes, para revisarlas con calma.
4. Toque **Confirmar ajuste de N productos**.

**Los productos sin contar no cambian.** Solo se ajustan los que usted contó.

---

## 6. Fiados

**Fiados** muestra los clientes a los que se les fió y **cuánto le deben en total** (**"Le deben $ …"**). Los clientes se crean al
fiar una venta; no hay un botón aparte para crearlos.

- **Buscar cliente por nombre** filtra la lista. Los clientes que no deben nada salen **"Al día"**.
- En el computador, la lista queda a la izquierda y, al elegir un cliente, a la derecha ve sus fiados y el formulario de
  abono. En el celular, tocar un cliente abre su pantalla.

### Registrar un abono

Cuando el cliente paga una parte de lo que debe:

1. Elija al cliente y toque **Registrar abono**.
2. **¿A cuál fiado abona?** Elija el fiado.
3. Escriba **cuánto** abona y el medio: **Efectivo** o **Nequi** (con **Referencia Nequi** opcional).
4. Toque el botón **Registrar abono de $ …**.

La app confirma con **"Abono registrado. Nuevo saldo: $ …"**. **El efectivo entra a la caja de hoy; Nequi no mueve la
caja.**

### Eliminar los datos de un cliente

Si el cliente lo pide, en su pantalla toque **Eliminar datos del cliente**. La app le pide confirmar
(**"¿Confirma que desea eliminar los datos del cliente?"**). Si el cliente **todavía debe**, no se puede:
**"No se pueden eliminar los datos: el cliente aún debe"**. Si no debe, aparece **"Datos del cliente eliminados"**.

---

## 7. Caja (solo administrador)

### Caja de hoy

Muestra, para el día:

- **Abrió con $ …**: el efectivo con el que empezó el día.
- **Debe haber en caja**: lo que tiene que haber en efectivo en este momento.
- **Entró hoy**, **Gastos del negocio** y **Personal** (lo que se sacó para la casa, aparte de la ganancia).
- La lista de **movimientos de hoy**.

**Anotar un movimiento** (un gasto o un ingreso que no es una venta):

1. Elija **Sale dinero** o **Entra dinero**.
2. Elija si es **Del negocio** o **Personal** (para la casa). Lo personal se cuenta aparte para que no se confunda con lo que
   gana el negocio.
3. Escriba **¿En qué?** (por ejemplo, "Hielo") y el valor.
4. Toque **Anotar**.

Las **anulaciones de ventas se anotan solas**; no se escriben aquí.

### Ventas de hoy y anular una venta

**Caja → Ventas de hoy** lista las ventas con su hora, productos, forma de pago y total. Con **Fechas** puede ver otro día o
un periodo.

Para anular una venta:

1. Toque **Anular** en esa venta.
2. La app pregunta **"¿Anular la venta de las …?"**. Elija el **Motivo** (**Error al cobrar**, **Cliente devolvió** u otro, que
   debe escribir). El motivo es obligatorio.
3. Antes de confirmar la app le explica qué va a pasar: **los productos vuelven al surtido**, **sale el dinero de la
   caja de hoy**, **el fiado queda anulado**, y si pagaron por Nequi, **debe devolver ese dinero por Nequi** (no sale de la
   caja).
4. Confirme con **Sí, anular venta**, o toque **No, dejarla como está**.

**Anular no se puede deshacer.** La venta se queda en la lista, tachada y con la etiqueta **Anulada**, y queda anotado que
usted la anuló.

### Cierre de caja

Al terminar el día:

1. Toque **Cerrar caja** (en Caja, o en **Caja → Cierre de caja**).
2. La app muestra **Lo que debe haber**: con cuánto abrió, lo que entró y lo que salió, y el total.
3. Cuente el efectivo y escríbalo en **¿Cuánto efectivo contó?**. La app muestra la **diferencia** con lo esperado.
4. Si se equivocó al contar, use **Volver a contar**.
5. Toque **Cerrar caja**.

**Después de cerrar no se pueden anotar más movimientos de hoy.** La app avisa **"Caja cerrada. Ya no se pueden anotar más
movimientos de hoy."** y puede volver a **Caja**.

---

## 8. Negocio (solo administrador)

La pantalla **Negocio** reúne todo lo que ayuda a decidir.

### Alertas de surtido

Le dice **qué conviene comprar**. Son **sugerencias: usted decide qué comprar.** Se calculan **una vez al día**, la primera
vez que se abre la app ese día.

- Pestaña **Por surtir**: cada producto con **Hay**, **Vende al día**, **Se fueron sin comprar** (clientes que no lo
  encontraron) y **Alcanza para** (para cuántos días le dura lo que hay). Las advertencias van en rojo. Una alerta marcada
  **Provisional** es de un producto que lleva **menos de 30 días de ventas**: el cálculo puede cambiar. La sección **Cómo
  leerlas** explica cada dato.
- Pestaña **Ventas perdidas**: lo que los clientes quisieron comprar en los **últimos 30 días** y no había. Si no hubo,
  dice **"No hubo ventas perdidas en los últimos 30 días"**.

### Reporte del día

Cuánto **vendió, gastó y ganó** el negocio en un día. Use **Día anterior** y **Día siguiente** para cambiar de fecha.

Muestra: **Vendió**, **Gastos del negocio**, **Ganancia del negocio**, lo que **sacó para la casa** (aparte), el **Dinero por
Nequi**, la **Mercancía que entró** (total de compras) y los **Fiados del día** (cuánto se fió y cuánto abonaron).

- **"Falta el costo de algún producto vendido"**: la ganancia sale **incompleta** porque no cuenta lo vendido sin costo.
  Regístrelo en la próxima entrada de mercancía.
- Si dice que hay cambios de este equipo **sin subir al servidor**, el reporte es **parcial**: se completa cuando se
  sincronice.

### Ganancia por producto

Cuánto deja cada producto: **precio menos costo de lo vendido**, sin contar las ventas anuladas. Elija el periodo
(**Hoy**, **Semana**, **Mes** o **Fechas**). Muestra la **Ganancia del periodo** y los **Productos con ventas**. Los productos **Sin costo
registrado** salen **incompletos**, en rojo.

### Rotación

Reparte los productos en tres grupos según las unidades que vendieron: **Se vende mucho** (tercio de arriba), **Se vende
regular** (tercio del medio) y **Se vende poco** (tercio de abajo). Elija **Últimos 30 días**, **Este mes** o **Fechas**.
Los productos que no vendieron nada también aparecen, en el grupo **Baja**. En el celular se ve un grupo a la vez; en el
computador, los tres.

### Usuarios

Quién puede entrar a la tienda. La lista muestra el **Nombre**, **Correo** y **Estado** (**Activo** o **Inactivo**), y si es
**Propietario** o **Empleado**.

**Esta pantalla necesita internet**, tanto para ver los usuarios como para agregar o desactivar. Sin conexión la app dice
**"Necesitas internet para ver y cambiar los usuarios"**; vuelva a intentarlo cuando tenga conexión.

**Agregar un empleado:**

1. En **Agregar empleado** escriba el **Nombre completo**, la **Cédula** (solo números), el **Correo** y una
   **Contraseña** (mínimo 6 caracteres).
2. Toque **Agregar empleado**.

La app crea también su cuenta: **con ese correo y esa contraseña el empleado entra a GIP**, a la misma tienda del
administrador. Entréguele el correo y la contraseña. Un empleado puede vender, surtir y fiar; **no ve la caja, la ganancia ni
los reportes**.

- El **correo no se puede repetir** (ni en otra tienda) y la **cédula no se puede repetir en la tienda**.
- **Desactivar** a alguien pide confirmación (**"¿Desactivar a …?"**): ya no podrá iniciar sesión, pero **sus ventas y
  registros se conservan**. **El propietario no se puede desactivar.**

### Revisar sincronización

Cuando varios equipos registran cosas **sin internet** y luego se unen, a veces **algo no cuadra**. La app no adivina: le
muestra una tarjeta por cada caso y usted decide. Si no hay nada, dice **"No hay nada por revisar. Lo registrado en todos
los equipos cuadra."**

Mientras hay casos pendientes, un aviso en la app dice **"Hay N conflictos por revisar"** (con el botón **Revisar**). Las
entradas de mercancía en revisión **no suman a la existencia** hasta que usted decida.

| Qué pasó | Qué puede hacer |
|---|---|
| **Posible registro repetido** | Marque los registros que **sí ocurrieron** (los demás se descartan) y toque **Guardar decisión**, o elija **Son registros distintos**. |
| **Existencia negativa** | Cuente el producto para corregirlo (**Ir al conteo**) o **Aceptar así**. |
| **Abono mayor que el saldo** | Marque los abonos que se anulan y toque **Anular abonos marcados**. El dinero se devuelve en caja. |
| **Código repetido** | Marque el producto que pierde el código y toque **Quitar el código**. |
| **Movimiento en caja cerrada** | **Aceptar y recalcular**: se acepta el movimiento y se recalcula la diferencia del cierre. |

### Exportar datos

Para llevar su información a otro lado cuando quiera.

1. Elija el **periodo** de las ventas.
2. Elija el **Formato**: **Excel** o **CSV**.
3. Toque **Exportar**.

El archivo trae el **inventario con su existencia**, las **ventas del periodo y sus formas de pago**, y los **fiados y abonos**.
Si el periodo no es válido (por ejemplo, "hasta" antes de "desde"), la app se lo dice.

---

## 9. Trabajar sin internet

- **Vender, registrar entradas, fiar y consultar existencias no esperan a la red.** Todo se guarda en el equipo.
- **Lo único que sí necesita internet** es entrar por primera vez y la pantalla **Usuarios** (ver, agregar o desactivar).
- Cuando vuelve la conexión, la app **sincroniza sola** con el servidor. No tiene que hacer nada.
- Si la sincronización falla, la app muestra **"No se pudo sincronizar: …"** y lo vuelve a intentar.
- Cada equipo (celular o computador) tiene su propia copia, y todas se unen al sincronizar. Si dos equipos anotaron cosas
  que chocan, aparece en **Negocio → Revisar sincronización** (ver sección 8).
- **El stock y los saldos se recalculan** a partir de los movimientos; por eso no se editan a mano.
- **Las ventas, entradas, abonos y movimientos de caja no se borran ni se editan**: se **anulan** con un registro nuevo.

> **Cuidado.** Si **desinstala la app** o **borra los datos del navegador** antes de que se haya sincronizado, puede perder lo
> que aún no se subió. Conéctese a internet de vez en cuando para que todo quede respaldado.

---

## 10. Lector de códigos

- **En el computador:** use un **lector 2D (USB) en modo teclado**. Haga clic en **Buscar producto**, dispare el lector y la
  app busca el producto por su código. **En la web no se usa la cámara.**
- **En el celular Android:** use un **lector Bluetooth en modo teclado (HID)**, que se empareja desde los ajustes de
  Bluetooth, o use la **cámara**: el botón del lector en **Vender**, **Surtido** y **Buscar producto** abre la cámara
  (la primera vez Android pide permiso).
- Si la lectura falla (lector desconectado, sin permiso de cámara o código ilegible), la app avisa y puede **seguir
  buscando por nombre**.
- Para que un código encuentre un producto, primero hay que **asociarlo** en la pantalla del producto
  (sección **Códigos del producto**, ver [sección 5](#5-surtido)).

---

## 11. Problemas frecuentes

| Qué ve | Qué significa y qué hacer |
|---|---|
| No puedo entrar | Revise el correo y la contraseña. La primera vez necesita internet. Si el correo no está registrado, pida al administrador que lo agregue. |
| **"No hay suficiente existencia del producto"** | Hay menos de lo que quiere vender. Corrija la cantidad, o toque **Anotar que se fue sin él**. Si cree que sí hay, haga un **Conteo físico**. |
| **Falta $ …** al cobrar | Los pagos no cubren el total. Complete el efectivo, el Nequi o fíe lo que falta. |
| No se puede confirmar una **pérdida** | Falta elegir el **motivo**. |
| **"No se pueden eliminar los datos: el cliente aún debe"** | El cliente tiene saldo pendiente. Primero registre su abono. |
| El reporte o la ganancia dicen **incompleto** | Hay productos vendidos sin costo. Escriba el costo en la próxima **Entrada de mercancía** o al editar el producto. |
| El reporte dice **parcial** | Hay cambios de este equipo que aún no se suben. Se completa al sincronizar. |
| **"No se pudo sincronizar"** | No hay conexión o el servidor no respondió. Siga trabajando; se reintenta solo. |
| **"Hay N conflictos por revisar"** | Entre a **Negocio → Revisar sincronización** y decida cada caso. |
| **"Necesitas internet para ver y cambiar los usuarios"** | Agregar, ver o desactivar usuarios necesita conexión. Intente de nuevo cuando tenga internet. |
| El empleado no ve Caja ni Negocio | Es lo normal: esas secciones son solo del administrador. |
| No puedo anotar más movimientos en la caja | La caja de hoy ya se **cerró**. |

---

## 12. Lo que la app todavía no hace

Para que no lo busque, esto **no está** en la versión actual:

- **Cambiar o recuperar la contraseña desde la app.** Hoy el administrador del sistema la cambia en el servidor.
- **PIN, cierre de sesión por inactividad o verificación del correo.** Se entra solo con correo y contraseña.
- **Usar la cámara en la web.** En el computador solo se usa el lector 2D.
- **Safari, iPhone, o el navegador del celular Android.** Use el computador (Chrome, Edge o Firefox) o la app Android.
- **Imprimir el reporte del día**, **descargar Excel** desde cada reporte o **armar la lista de pedido** desde las alertas.
  Para sacar sus datos use **Negocio → Exportar datos**.
- Mostrar en los reportes **quién vendió** o **qué equipo hizo cada registro**: la app no lo guarda.

---

## 13. Glosario

| Palabra | Qué quiere decir |
|---|---|
| **Surtido** | Los productos que tiene la tienda y cuántos hay de cada uno (el inventario). |
| **Existencia** | Cuántas unidades (o kilos, o libras) hay de un producto. |
| **Fiado** | Venta que el cliente se lleva y paga después. |
| **Abono** | Pago parcial que hace un cliente sobre lo que debe. |
| **Saldo** | Lo que un cliente todavía debe. |
| **Entrada** | Mercancía que llega del proveedor y se suma al surtido. |
| **Pérdida** | Mercancía que sale del surtido sin venderse (vencida, dañada o devuelta). |
| **Conteo físico** | Contar lo que hay en el estante y corregir la existencia en el sistema. |
| **Venta perdida** | Un cliente quiso un producto que no había y se fue sin comprarlo. |
| **Cierre de caja** | Contar el efectivo al final del día y compararlo con lo que debe haber. |
| **Anular** | Dejar sin efecto una venta. No se borra: queda marcada como anulada. |
| **Sincronizar** | Unir lo que se anotó en cada equipo con el servidor, para que todos vean lo mismo. |
| **Conflicto** | Dos equipos anotaron cosas que no cuadran al unirse; usted decide cuál vale. |
| **Rotación** | Qué tan rápido se vende un producto (mucho, regular o poco). |
| **Ganancia** | Precio de venta menos el costo de lo vendido. |
