-- CUS-03 Registrar pérdida o devolución al proveedor: motivo de la MERMA en
-- movimientos_inventario (tabla única con `tipo`, DI-03; DI-22).
-- Sin RLS ni políticas (DI-05). La tabla ya tiene tienda_id con índice,
-- creado_en y actualizado_en.

-- Lista cerrada de MotivoMerma (IE-03 b); mismos nombres que en drift.
create type public.motivo_merma as enum ('VENCIDO', 'DANADO', 'DEVUELTO_PROVEEDOR', 'OTRO');

alter table public.movimientos_inventario
  add column motivo  public.motivo_merma,
  -- Una merma siempre resta y trae su motivo (DA-19, IE-03).
  add constraint movimientos_inventario_merma_chk check (
    tipo <> 'MERMA' or (cantidad < 0 and motivo is not null)
  );
