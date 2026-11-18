-- CUS-17 Leer código de producto y CUS-18 "Asociar código" (DI-34).
-- Códigos de barras o QR asociados a un producto (clase CodigoProducto).
-- Sin RLS ni políticas (DI-05). Plantilla: id uuid, tienda_id con índice.

create type public.formato_codigo as enum ('EAN13', 'EAN8', 'UPCA', 'QR');

-- `valor` es el texto exacto de la lectura (DA-41). El índice de
-- (tienda_id, valor) NO es único: dos dispositivos sin conexión pueden asociar
-- el mismo valor a productos distintos y la conciliación lo reporta como
-- CODIGO_REPETIDO (CUS-22, DA-66). La app valida que no se repita al asociar.
-- Solo se agregan; quitar un código llega con CUS-22.
create table public.codigos_producto (
  id           uuid primary key,
  tienda_id    uuid not null references public.tiendas (id),
  producto_id  uuid not null references public.productos (id),
  formato      public.formato_codigo not null,
  valor        text not null check (length(valor) > 0),
  creado_en    timestamptz not null default now()
);
create index codigos_producto_tienda_idx on public.codigos_producto (tienda_id);
create index codigos_producto_tienda_valor_idx on public.codigos_producto (tienda_id, valor);
create index codigos_producto_producto_idx on public.codigos_producto (producto_id);
