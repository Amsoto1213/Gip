-- CUS-21 Eliminar datos de un cliente (DI-31, RNF-16).
-- La fila no se borra: sus fiados la referencian y se conservan (RNF-15). Al
-- eliminar sus datos, la app la anonimiza (nombre 'Cliente eliminado',
-- nombre_normalizado y telefono vacíos) y marca `eliminado_en`. Sin RLS (DI-05).

alter table public.clientes add column eliminado_en timestamptz;
