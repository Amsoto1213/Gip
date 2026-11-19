-- CUS-14 Registrar cierre de caja: base de apertura (DI-38).
-- La caja abre con el efectivo que había al terminar el día anterior: lo que
-- se contó al cerrarla o, si no se cerró, su saldo esperado. La app lo calcula
-- al crear la caja y no cambia después. Las cajas que ya existían quedan en 0.
-- El saldo esperado sigue sin guardarse: es la base más los movimientos
-- (DA-48). Sin RLS ni políticas (DI-05).

alter table public.cajas
  add column base_apertura numeric(14,2) not null default 0 check (base_apertura >= 0);
