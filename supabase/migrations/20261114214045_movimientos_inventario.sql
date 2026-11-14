-- CUS-01 Registrar entrada de mercancía: historial de movimientos de inventario.
-- Sin RLS ni políticas (DI-05). Plantilla: id uuid, tienda_id con índice.

create type public.tipo_movimiento as enum ('ENTRADA', 'MERMA', 'AJUSTE_CONTEO', 'SALIDA_VENTA');
create type public.estado_movimiento as enum ('VIGENTE', 'EN_REVISION', 'ANULADO');

-- MovimientoInventario y sus subclases en una sola tabla con columna `tipo`
-- (DI-03). Solo se agregan filas; lo único que cambia después es `estado`
-- (conciliación o anulación, DA-48, RNF-15), por eso lleva `actualizado_en`.
-- `cantidad` lleva signo: positiva suma, negativa resta (DA-19). Cantidades en
-- numeric(12,3) y dinero en numeric(14,2) (DI-02). El stock no se guarda: cada
-- dispositivo lo recalcula sumando los movimientos VIGENTES (DI-17).
-- Las columnas de MERMA, AJUSTE_CONTEO y SALIDA_VENTA las agrega su caso de
-- uso (DI-20).
create table public.movimientos_inventario (
  id              uuid primary key,
  tienda_id       uuid not null references public.tiendas (id),
  item_id         uuid not null references public.items_inventario (id),
  tipo            public.tipo_movimiento not null,
  cantidad        numeric(12,3) not null,
  fecha           timestamptz not null,
  estado          public.estado_movimiento not null default 'VIGENTE',
  costo_unitario  numeric(14,2) check (costo_unitario >= 0),
  numero_factura  text,
  creado_en       timestamptz not null default now(),
  actualizado_en  timestamptz not null default now(),
  -- Una entrada siempre suma y trae su costo (RF-01, IE-02).
  constraint movimientos_inventario_entrada_chk check (
    tipo <> 'ENTRADA' or (cantidad > 0 and costo_unitario is not null)
  )
);
create index movimientos_inventario_tienda_idx on public.movimientos_inventario (tienda_id);
create index movimientos_inventario_item_tipo_fecha_idx
  on public.movimientos_inventario (item_id, tipo, fecha);
