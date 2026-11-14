-- CUS-02 Registrar venta: caja del día, movimientos de caja, ventas, formas de
-- pago y las columnas de SALIDA_VENTA en movimientos_inventario.
-- Sin RLS ni políticas (DI-05). Plantilla: tienda_id con índice. Dinero en
-- numeric(14,2) (DI-02). Todas estas tablas solo se agregan (RNF-15, DA-48).

create type public.tipo_movimiento_caja as enum ('INGRESO', 'EGRESO');
create type public.clasificacion_movimiento as enum ('NEGOCIO', 'PERSONAL', 'ANULACION');
-- FIADO se agrega con CUS-07 (alter type ... add value).
create type public.tipo_forma_pago as enum ('CONTADO', 'NEQUI');

-- Caja del día (clase Caja). El id no es uuid: "<tienda_id>_AAAA-MM-DD", para
-- que dos dispositivos sin conexión abran la misma caja (DA-62, DI-21).
-- `fecha` es el día local de la tienda (date, no instante). El saldo no se
-- guarda: se calcula de los movimientos (DA-48). Las columnas del cierre y
-- `actualizado_en` llegan con CUS-14.
create table public.cajas (
  id         text primary key,
  tienda_id  uuid not null references public.tiendas (id),
  fecha      date not null,
  creado_en  timestamptz not null default now(),
  unique (tienda_id, fecha),
  constraint cajas_id_chk check (id = tienda_id::text || '_' || to_char(fecha, 'YYYY-MM-DD'))
);
create index cajas_tienda_idx on public.cajas (tienda_id);

-- Movimiento de dinero de la caja (clase MovimientoCaja). `valor` siempre
-- positivo; `tipo` dice si entra o sale (RF-10).
create table public.movimientos_caja (
  id             uuid primary key,
  tienda_id      uuid not null references public.tiendas (id),
  caja_id        text not null references public.cajas (id),
  tipo           public.tipo_movimiento_caja not null,
  clasificacion  public.clasificacion_movimiento not null,
  valor          numeric(14,2) not null check (valor > 0),
  descripcion    text not null,
  fecha          timestamptz not null,
  creado_en      timestamptz not null default now()
);
create index movimientos_caja_tienda_idx on public.movimientos_caja (tienda_id);
create index movimientos_caja_caja_idx on public.movimientos_caja (caja_id);

-- Venta confirmada (clase Venta). La anulación será un registro aparte
-- (CUS-20, RNF-15).
create table public.ventas (
  id         uuid primary key,
  tienda_id  uuid not null references public.tiendas (id),
  fecha      timestamptz not null,
  total      numeric(14,2) not null check (total > 0),
  creado_en  timestamptz not null default now()
);
create index ventas_tienda_idx on public.ventas (tienda_id);
create index ventas_tienda_fecha_idx on public.ventas (tienda_id, fecha);

-- Formas de pago (clase FormaPago y subclases) en una sola tabla con `tipo`
-- (DI-21, como DI-03). Una venta no repite tipo (DA-20).
create table public.formas_pago (
  id              uuid primary key,
  tienda_id       uuid not null references public.tiendas (id),
  venta_id        uuid not null references public.ventas (id),
  tipo            public.tipo_forma_pago not null,
  monto_recibido  numeric(14,2),
  cambio          numeric(14,2),
  monto           numeric(14,2),
  referencia      text,
  creado_en       timestamptz not null default now(),
  unique (venta_id, tipo),
  -- Contado: recibido y cambio, y queda algo en caja (DA-72).
  constraint formas_pago_contado_chk check (
    tipo <> 'CONTADO' or (cambio >= 0 and monto_recibido > cambio)
  ),
  -- Nequi: monto positivo (DA-63).
  constraint formas_pago_nequi_chk check (tipo <> 'NEQUI' or monto > 0)
);
create index formas_pago_tienda_idx on public.formas_pago (tienda_id);
create index formas_pago_venta_idx on public.formas_pago (venta_id);

-- Salida por venta (clase SalidaVenta): venta, precio de venta y costo del
-- momento (DA-61). El costo usa la columna `costo_unitario` que ya existe y
-- puede ser nulo (ERS 3.2.4).
alter table public.movimientos_inventario
  add column venta_id         uuid references public.ventas (id),
  add column precio_unitario  numeric(14,2) check (precio_unitario >= 0),
  add constraint movimientos_inventario_salida_venta_chk check (
    tipo <> 'SALIDA_VENTA'
    or (cantidad < 0 and venta_id is not null and precio_unitario is not null)
  );
create index movimientos_inventario_venta_idx on public.movimientos_inventario (venta_id);
