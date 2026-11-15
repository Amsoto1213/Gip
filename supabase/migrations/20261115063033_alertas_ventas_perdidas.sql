-- CUS-24 Generar alertas de reabastecimiento y CUS-05 Consultar alertas:
-- alertas del día y ventas perdidas (solo lectura hasta CUS-13), DI-25.
-- Sin RLS ni políticas (DI-05). Plantilla: tienda_id con índice. Cantidades en
-- numeric(12,3) (DI-02).

-- Alertas de reabastecimiento (clase AlertaReabastecimiento). `fecha` es el
-- día local de la tienda (date, como cajas, DI-21). No se editan: cada cálculo
-- borra las del día y escribe las nuevas (reemplazar, RD-11, DA-35), por eso
-- la cola local sube ELIMINAR e INSERTAR.
create table public.alertas_reabastecimiento (
  id                       uuid primary key,
  tienda_id                uuid not null references public.tiendas (id),
  item_id                  uuid not null references public.items_inventario (id),
  fecha                    date not null,
  existencia               numeric(12,3) not null,
  consumo_promedio_diario  numeric(12,4) not null check (consumo_promedio_diario > 0),
  dias_cobertura           numeric(12,2) not null check (dias_cobertura >= 0),
  provisional              boolean not null,
  creado_en                timestamptz not null default now()
);
create index alertas_reabastecimiento_tienda_idx on public.alertas_reabastecimiento (tienda_id);
create index alertas_reabastecimiento_tienda_fecha_idx on public.alertas_reabastecimiento (tienda_id, fecha);

-- Ventas perdidas por producto agotado (clase VentaPerdida, RF-12). Solo se
-- agregan (DA-48, DA-50): las registra CUS-13.
create table public.ventas_perdidas (
  id           uuid primary key,
  tienda_id    uuid not null references public.tiendas (id),
  producto_id  uuid not null references public.productos (id),
  fecha        timestamptz not null,
  creado_en    timestamptz not null default now()
);
create index ventas_perdidas_tienda_idx on public.ventas_perdidas (tienda_id);
create index ventas_perdidas_tienda_fecha_idx on public.ventas_perdidas (tienda_id, fecha);
create index ventas_perdidas_producto_fecha_idx on public.ventas_perdidas (producto_id, fecha);
