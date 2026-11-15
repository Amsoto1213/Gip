-- CUS-07 Registrar fiado: clientes y fiados (DI-26).
-- Sin RLS ni políticas (DI-05). Plantilla: id uuid, tienda_id con índice.
-- Dinero en numeric(14,2) (DI-02).

create type public.estado_fiado as enum ('PENDIENTE', 'SALDADO', 'ANULADO');

-- Cliente del fiado (clase Cliente): solo nombre y teléfono (RNF-16).
-- `telefono` vacío si no lo dio (DI-26). `actualizado_en` lo pone la app: gana
-- la edición más reciente (DA-48).
create table public.clientes (
  id                  uuid primary key,
  tienda_id           uuid not null references public.tiendas (id),
  nombre              text not null check (btrim(nombre) <> ''),
  nombre_normalizado  text not null,
  telefono            text not null default '',
  creado_en           timestamptz not null default now(),
  actualizado_en      timestamptz not null
);
create index clientes_tienda_idx on public.clientes (tienda_id);
create index clientes_tienda_nombre_idx on public.clientes (tienda_id, nombre_normalizado);

-- Fiado (clase Fiado). Es una forma de pago: `id` es el de su fila FIADO en
-- formas_pago, que lo une a la venta. Guarda el saldo y el estado que
-- actualizan los abonos (CUS-08) y la anulación (CUS-20).
create table public.fiados (
  id               uuid primary key references public.formas_pago (id),
  tienda_id        uuid not null references public.tiendas (id),
  cliente_id       uuid not null references public.clientes (id),
  monto_inicial    numeric(14,2) not null check (monto_inicial > 0),
  saldo_pendiente  numeric(14,2) not null
                   check (saldo_pendiente >= 0 and saldo_pendiente <= monto_inicial),
  estado           public.estado_fiado not null,
  fecha_inicio     timestamptz not null,
  creado_en        timestamptz not null default now()
);
create index fiados_tienda_idx on public.fiados (tienda_id);
create index fiados_cliente_idx on public.fiados (cliente_id);

-- Fiado en formas_pago: monto positivo (IE-06).
alter table public.formas_pago
  add constraint formas_pago_fiado_chk check (tipo <> 'FIADO' or monto > 0);
