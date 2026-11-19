-- CUS-20 Anular venta (DI-39, RNF-15).
-- Anulación de una venta (clase AnulacionVenta): quién, cuándo y por qué. Es un
-- registro aparte: la venta no se borra ni cambia sus datos, y esta tabla solo
-- se agrega (DA-48, DA-51). Sin RLS ni políticas (DI-05). Plantilla: id uuid,
-- tienda_id con índice.
--
-- El índice de venta_id NO es único: dos dispositivos sin conexión pueden
-- anular la misma venta y se resuelve al conciliar; al leer vale la más
-- antigua. `usuario_nombre` guarda el nombre de quien anuló en ese momento.
-- La anulación también cambia, en otras tablas que ya existen, el estado de
-- las salidas de la venta (movimientos_inventario.estado = 'ANULADO') y el del
-- fiado (fiados.estado = 'ANULADO', saldo 0).

create table public.anulaciones_venta (
  id              uuid primary key,
  tienda_id       uuid not null references public.tiendas (id),
  venta_id        uuid not null references public.ventas (id),
  usuario_id      uuid not null references public.usuarios (id),
  usuario_nombre  text not null,
  fecha           timestamptz not null default now(),
  motivo          text not null check (length(btrim(motivo)) > 0)
);
create index anulaciones_venta_tienda_idx on public.anulaciones_venta (tienda_id);
create index anulaciones_venta_venta_idx on public.anulaciones_venta (venta_id);
