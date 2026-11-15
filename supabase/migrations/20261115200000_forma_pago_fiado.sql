-- CUS-07 Registrar fiado: FIADO como tercera forma de pago (DI-26).
-- Va sola en su migración: Postgres no deja usar un valor nuevo de un enum en
-- la misma transacción que lo agrega; lo usa 20261115200100_clientes_fiados.
alter type public.tipo_forma_pago add value 'FIADO';
