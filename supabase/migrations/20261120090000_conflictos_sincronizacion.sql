-- CUS-22 Revisar conflictos de sincronización (DI-45, DA-48).
-- Choque detectado al sincronizar que solo el propietario puede decidir (clase
-- ConflictoSincronizacion). Sin RLS ni políticas (DI-05).
--
-- `id` es text, NO uuid: es determinista (tipo y registros) para que dos
-- dispositivos que detectan el mismo choque no creen dos conflictos (DA-48).
-- Por eso se rompe aquí la plantilla "id uuid" de las demás tablas.
-- `ids_registros` y `etiquetas_registros` son listas de texto: una etiqueta por
-- id, en el mismo orden; la etiqueta la escribe quien detecta el conflicto y
-- con ella la pantalla muestra cada registro sin buscarlo (DI-45).

create type public.tipo_conflicto as enum (
  'STOCK_NEGATIVO',
  'ABONO_EXCEDE_SALDO',
  'CODIGO_REPETIDO',
  'POSIBLE_DUPLICADO',
  'MOVIMIENTO_CAJA_CERRADA'
);

create table public.conflictos_sincronizacion (
  id                   text primary key,
  tienda_id            uuid not null references public.tiendas (id),
  tipo                 public.tipo_conflicto not null,
  descripcion          text not null,
  ids_registros        jsonb not null default '[]'::jsonb,
  etiquetas_registros  jsonb not null default '[]'::jsonb,
  fecha                timestamptz not null default now(),
  resuelto             boolean not null default false,
  actualizado_en       timestamptz not null default now(),
  check (jsonb_typeof(ids_registros) = 'array'),
  check (jsonb_typeof(etiquetas_registros) = 'array'),
  check (jsonb_array_length(ids_registros) = jsonb_array_length(etiquetas_registros))
);
create index conflictos_sincronizacion_tienda_idx
  on public.conflictos_sincronizacion (tienda_id);
