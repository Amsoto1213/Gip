-- CUS-23 Sincronizador (DI-47): lo que el servidor necesita para que los
-- equipos suban y bajen datos sin pisarse. Sin RLS ni políticas (DI-05).
--
-- 1. `sincronizado_en`: la fecha en que el SERVIDOR recibió o cambió cada fila.
--    Es el cursor con el que cada equipo pide "lo nuevo desde la última vez"; no
--    depende de que los relojes de los equipos coincidan. La pone un
--    disparador, no la app.
-- 2. Reglas de choque (DA-48) en el servidor, para que dos equipos que suben a
--    la vez no se pisen:
--    - productos y clientes: gana la edición más reciente (`actualizado_en`);
--    - movimientos_inventario y fiados: ANULADO no se revierte;
--    - abonos: un abono anulado sigue anulado;
--    - conflictos_sincronizacion: un conflicto resuelto sigue resuelto;
--    - cajas: una caja cerrada no vuelve a abierta.
-- 3. `registros_eliminados`: lo único que la app borra de verdad es un código de
--    producto (CUS-22). Sin esta tabla, los demás equipos nunca sabrían que se
--    quitó. Un disparador anota cada borrado.
--
-- No se sincronizan `tiendas` y `usuarios` (se administran en el servidor),
-- `alertas_reabastecimiento` (cada equipo las calcula, DI-25) ni el stock
-- (se recalcula, DI-17).

create function public.marcar_sincronizado() returns trigger
language plpgsql as $$
begin
  new.sincronizado_en := clock_timestamp();
  return new;
end;
$$;

-- productos y clientes: si llega una edición más vieja que la guardada, se
-- ignora (devolver NULL salta la actualización).
create function public.conservar_edicion_mas_reciente() returns trigger
language plpgsql as $$
begin
  if new.actualizado_en < old.actualizado_en then
    return null;
  end if;
  return new;
end;
$$;

-- movimientos_inventario y fiados: lo anulado no se revierte (RNF-15).
create function public.conservar_estado_anulado() returns trigger
language plpgsql as $$
begin
  if old.estado::text = 'ANULADO' then
    new.estado := old.estado;
  end if;
  return new;
end;
$$;

create function public.conservar_abono_anulado() returns trigger
language plpgsql as $$
begin
  new.anulado := old.anulado or new.anulado;
  return new;
end;
$$;

create function public.conservar_conflicto_resuelto() returns trigger
language plpgsql as $$
begin
  new.resuelto := old.resuelto or new.resuelto;
  return new;
end;
$$;

-- Una caja cerrada no vuelve a abierta; sí puede cambiar su diferencia cuando
-- el propietario acepta un movimiento que llegó tarde (CUS-22).
create function public.conservar_caja_cerrada() returns trigger
language plpgsql as $$
begin
  if old.cerrada and not new.cerrada then
    return old;
  end if;
  return new;
end;
$$;

-- Tombstones de lo que se borra de verdad.
create table public.registros_eliminados (
  id              uuid primary key default gen_random_uuid(),
  tienda_id       uuid not null references public.tiendas (id),
  tabla           text not null,
  registro_id     uuid not null,
  sincronizado_en timestamptz not null default clock_timestamp(),
  unique (tabla, registro_id)
);
create index registros_eliminados_tienda_idx
  on public.registros_eliminados (tienda_id, sincronizado_en);

create function public.anotar_eliminado() returns trigger
language plpgsql as $$
begin
  insert into public.registros_eliminados (tienda_id, tabla, registro_id)
  values (old.tienda_id, tg_table_name, old.id)
  on conflict (tabla, registro_id) do nothing;
  return old;
end;
$$;

create trigger codigos_producto_eliminado
  after delete on public.codigos_producto
  for each row execute function public.anotar_eliminado();

-- `sincronizado_en` e índice del cursor en cada tabla que se sincroniza. Los
-- disparadores de regla (`_1_`) corren antes que el de `sincronizado_en`
-- (`_2_`): PostgreSQL los ejecuta en orden alfabético.
do $$
declare
  t text;
begin
  foreach t in array array[
    'productos', 'items_inventario', 'clientes', 'ventas', 'formas_pago',
    'fiados', 'abonos', 'cajas', 'movimientos_caja', 'movimientos_inventario',
    'codigos_producto', 'anulaciones_venta', 'ventas_perdidas',
    'conflictos_sincronizacion'
  ] loop
    execute format(
      'alter table public.%I add column sincronizado_en timestamptz not null default clock_timestamp()',
      t);
    execute format(
      'create index %I on public.%I (tienda_id, sincronizado_en)',
      t || '_sincronizado_idx', t);
    execute format(
      'create trigger %I before insert or update on public.%I for each row execute function public.marcar_sincronizado()',
      t || '_2_sincronizado', t);
  end loop;
end;
$$;

create trigger productos_1_regla before update on public.productos
  for each row execute function public.conservar_edicion_mas_reciente();
create trigger clientes_1_regla before update on public.clientes
  for each row execute function public.conservar_edicion_mas_reciente();
create trigger movimientos_inventario_1_regla
  before update on public.movimientos_inventario
  for each row execute function public.conservar_estado_anulado();
create trigger fiados_1_regla before update on public.fiados
  for each row execute function public.conservar_estado_anulado();
create trigger abonos_1_regla before update on public.abonos
  for each row execute function public.conservar_abono_anulado();
create trigger conflictos_sincronizacion_1_regla
  before update on public.conflictos_sincronizacion
  for each row execute function public.conservar_conflicto_resuelto();
create trigger cajas_1_regla before update on public.cajas
  for each row execute function public.conservar_caja_cerrada();

-- Al unir los abonos de dos equipos, el saldo de un fiado puede quedar
-- NEGATIVO: es justo el conflicto ABONO_EXCEDE_SALDO que decide el propietario
-- (CUS-22). El servidor no puede rechazar ese saldo, o el equipo nunca lo
-- subiría. Se quita `saldo_pendiente >= 0` y se deja `<= monto_inicial`.
-- PostgreSQL guarda esa restricción como `saldo_pendiente >= (0)::numeric`, por
-- eso se busca con una expresión regular. Si esta migración ya se aplicó sin
-- quitarla, `20261121110000_fiados_saldo_negativo.sql` lo arregla.
do $$
declare
  c record;
begin
  for c in
    select conname
    from pg_constraint
    where conrelid = 'public.fiados'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ~ 'saldo_pendiente >= \(?0'
  loop
    execute format('alter table public.fiados drop constraint %I', c.conname);
  end loop;
end;
$$;
alter table public.fiados
  add constraint fiados_saldo_pendiente_max_chk
  check (saldo_pendiente <= monto_inicial);
