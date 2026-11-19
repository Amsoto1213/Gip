-- CUS-15 Gestionar usuarios de la tienda (DI-42).
-- La app crea al empleado con nombre y cédula; el correo con el que inicia
-- sesión lo pone después quien crea su cuenta en Supabase Auth (DA-67). Hasta
-- entonces la fila no tiene correo. `unique` sigue valiendo: Postgres permite
-- varias filas con correo nulo, pero no dos con el mismo correo.
alter table public.usuarios alter column correo drop not null;
