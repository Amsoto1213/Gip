-- CUS-23 (DI-47): arregla `20261121090000_sincronizacion.sql`, que no quitó la
-- restricción `saldo_pendiente >= 0` de `fiados`.
--
-- Al unir los abonos de dos equipos el saldo puede quedar NEGATIVO: es justo el
-- conflicto ABONO_EXCEDE_SALDO que decide el propietario (CUS-22). Con la
-- restricción, el servidor rechazaba el saldo (error 23514), la subida del
-- fiado se quedaba en la cola del equipo y Supabase seguía con el saldo de
-- antes. La migración anterior la buscaba como `saldo_pendiente >= 0`, pero
-- PostgreSQL la guarda como `saldo_pendiente >= (0)::numeric` y no la encontró.
--
-- Es segura de repetir: quita la restricción solo si existe. La de
-- `monto_inicial > 0` y la de `saldo_pendiente <= monto_inicial` se quedan.

alter table public.fiados drop constraint if exists fiados_saldo_pendiente_check;

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

-- La que pone un tope al saldo ya la agregó la migración anterior; si no
-- estuviera, se agrega aquí.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.fiados'::regclass
      and conname = 'fiados_saldo_pendiente_max_chk'
  ) then
    alter table public.fiados
      add constraint fiados_saldo_pendiente_max_chk
      check (saldo_pendiente <= monto_inicial);
  end if;
end;
$$;
