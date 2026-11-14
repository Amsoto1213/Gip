-- CUS-18 Gestionar producto: catálogo de productos e ítems de inventario.
-- Sin RLS ni políticas (DI-05). Plantilla: id uuid, tienda_id con índice.

create type public.unidad_medida as enum ('UNIDAD', 'KILOGRAMO', 'LIBRA');

-- Producto del catálogo (clase Producto). Dinero en numeric(14,2) (DI-02).
-- `codigo` es el código interno: índice NO único, porque dos dispositivos sin
-- conexión pueden crear el mismo y la conciliación lo reporta (DI-18, DA-59).
-- `actualizado_en` lo pone la app: gana la edición más reciente (DA-48).
create table public.productos (
  id                  uuid primary key,
  tienda_id           uuid not null references public.tiendas (id),
  codigo              text not null,
  nombre              text not null,
  nombre_normalizado  text not null,
  unidad_medida       public.unidad_medida not null,
  precio_compra       numeric(14,2) check (precio_compra >= 0),
  precio_venta        numeric(14,2) not null check (precio_venta >= 0),
  creado_en           timestamptz not null default now(),
  actualizado_en      timestamptz not null
);
create index productos_tienda_idx on public.productos (tienda_id);
create index productos_tienda_codigo_idx on public.productos (tienda_id, codigo);
create index productos_tienda_nombre_idx on public.productos (tienda_id, nombre_normalizado);

-- Ítem de inventario (clase ItemInventario): uno por producto. El stock no se
-- guarda aquí: se recalcula de los movimientos en cada dispositivo (DI-17).
create table public.items_inventario (
  id           uuid primary key,
  tienda_id    uuid not null references public.tiendas (id),
  producto_id  uuid not null references public.productos (id),
  creado_en    timestamptz not null default now(),
  unique (tienda_id, producto_id)
);
create index items_inventario_tienda_idx on public.items_inventario (tienda_id);
