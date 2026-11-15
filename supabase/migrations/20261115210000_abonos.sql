-- CUS-08 Registrar abono: abonos de los fiados (DI-27).
-- Sin RLS ni políticas (DI-05). Plantilla: id uuid, tienda_id con índice.
-- Dinero en numeric(14,2) (DI-02). Solo se agregan (RNF-15): un abono se anula
-- con `anulado`, no se borra.

create type public.medio_pago as enum ('EFECTIVO', 'NEQUI');

-- Abono (clase Abono). `referencia` es el número de la transacción de Nequi:
-- solo va con NEQUI (DA-64). El saldo y el estado del fiado se recalculan de
-- los abonos (DA-30); `fiados.saldo_pendiente` es una copia local.
create table public.abonos (
  id          uuid primary key,
  tienda_id   uuid not null references public.tiendas (id),
  fiado_id    uuid not null references public.fiados (id),
  monto       numeric(14,2) not null check (monto > 0),
  fecha       timestamptz not null,
  medio       public.medio_pago not null,
  referencia  text,
  anulado     boolean not null default false,
  creado_en   timestamptz not null default now(),
  constraint abonos_referencia_chk check (referencia is null or medio = 'NEQUI')
);
create index abonos_tienda_idx on public.abonos (tienda_id);
create index abonos_fiado_idx on public.abonos (fiado_id);
