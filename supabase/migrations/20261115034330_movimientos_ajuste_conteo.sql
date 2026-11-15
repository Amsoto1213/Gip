-- CUS-04 Registrar conteo físico: lo contado en un AJUSTE_CONTEO de
-- movimientos_inventario (tabla única con `tipo`, DI-03; DI-24). `cantidad` es
-- la diferencia con el stock (contada - stock) y puede ser negativa, positiva o
-- cero: un conteo que cuadra también queda registrado.
-- Sin RLS ni políticas (DI-05). La tabla ya tiene tienda_id con índice,
-- creado_en y actualizado_en.

alter table public.movimientos_inventario
  add column cantidad_contada  numeric(12,3),
  -- Un ajuste de conteo siempre trae lo contado y no es negativo (IE-04 b).
  add constraint movimientos_inventario_ajuste_conteo_chk check (
    tipo <> 'AJUSTE_CONTEO' or (cantidad_contada is not null and cantidad_contada >= 0)
  );
