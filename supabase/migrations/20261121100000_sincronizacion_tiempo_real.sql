-- CUS-23 (DI-48): que los equipos se enteren al instante de lo que cambia otro.
-- La app escucha Supabase Realtime en estas tablas y, al recibir un cambio,
-- sincroniza (el evento solo es la señal; los datos los trae la sincronización,
-- con sus reglas de choque). Sin RLS ni políticas (DI-05): Realtime entrega los
-- cambios con la llave anon y el filtro por `tienda_id` lo pone la app.
--
-- No incluye `alertas_reabastecimiento`, `tiendas` ni `usuarios`: no se
-- sincronizan.

do $$
declare
  t text;
begin
  foreach t in array array[
    'productos', 'items_inventario', 'clientes', 'ventas', 'formas_pago',
    'fiados', 'abonos', 'cajas', 'movimientos_caja', 'movimientos_inventario',
    'codigos_producto', 'anulaciones_venta', 'ventas_perdidas',
    'conflictos_sincronizacion', 'registros_eliminados'
  ] loop
    -- Si ya estaba en la publicación, no se repite (`add table` falla).
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end;
$$;
