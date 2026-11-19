-- CUS-14 Registrar cierre de caja (DI-37, RF-13).
-- La caja del día se cierra una vez: el cierre guarda lo que se contó, la
-- diferencia con el saldo esperado (positivo = sobrante, negativo = faltante)
-- y el instante del cierre. El saldo esperado no se guarda: se calcula de los
-- movimientos (DA-48). Abierta: cerrada = false y las otras tres columnas
-- nulas; cerrada: las tres con valor. Sin RLS ni políticas (DI-05).

alter table public.cajas
  add column cerrada          boolean not null default false,
  add column efectivo_contado numeric(14,2) check (efectivo_contado >= 0),
  add column diferencia       numeric(14,2),
  add column fecha_cierre     timestamptz,
  add constraint cajas_cierre_chk check (
    (cerrada and efectivo_contado is not null and diferencia is not null and fecha_cierre is not null)
    or (not cerrada and efectivo_contado is null and diferencia is null and fecha_cierre is null)
  );
