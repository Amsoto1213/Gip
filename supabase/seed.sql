-- Datos de prueba para `supabase db reset`. Solo datos ficticios: las tablas no tienen RLS.
-- Las cuentas de inicio de sesión se crean aparte, con el mismo correo, en Supabase Studio
-- (http://127.0.0.1:55323 → Authentication → Add user) o desde la app con CUS-15.
insert into public.tiendas (id, codigo, nombre, direccion) values
  ('11111111-1111-4111-8111-111111111111', 'T001', 'Granero El Porvenir', 'Arjona, Bolívar');

insert into public.usuarios (id, tienda_id, nombre, cedula, correo, rol) values
  ('22222222-2222-4222-8222-222222222222', '11111111-1111-4111-8111-111111111111', 'Carmen', '1000000001', 'carmen@gip.test', 'ADMINISTRADOR'),
  ('33333333-3333-4333-8333-333333333333', '11111111-1111-4111-8111-111111111111', 'Luis',   '1000000002', 'luis@gip.test',   'EMPLEADO');
