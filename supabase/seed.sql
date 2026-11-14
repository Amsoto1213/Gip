-- Datos de prueba para `supabase db reset`. Solo datos ficticios: las tablas no tienen RLS.
insert into public.tiendas (id, codigo, nombre, direccion) values
  ('11111111-1111-4111-8111-111111111111', 'T001', 'Granero El Porvenir', 'Arjona, Bolívar');

insert into public.usuarios (id, tienda_id, nombre, cedula, correo, rol) values
  ('22222222-2222-4222-8222-222222222222', '11111111-1111-4111-8111-111111111111', 'Carmen', '1000000001', 'carmen@gip.test', 'ADMINISTRADOR'),
  ('33333333-3333-4333-8333-333333333333', '11111111-1111-4111-8111-111111111111', 'Luis',   '1000000002', 'luis@gip.test',   'EMPLEADO');

-- Cuentas de inicio de sesión en Supabase Auth (DI-05), contraseña de prueba `gip12345`.
-- Usan el mismo id que su fila en `usuarios`; la app las une por `correo`.
-- Los tokens van en '' (no NULL): GoTrue falla al leer NULL en esas columnas.
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
)
select
  '00000000-0000-0000-0000-000000000000', u.id, 'authenticated', 'authenticated', u.correo,
  extensions.crypt('gip12345', extensions.gen_salt('bf')), now(),
  '{"provider":"email","providers":["email"]}', '{}', now(), now(),
  '', '', '', ''
from public.usuarios u
where u.correo in ('carmen@gip.test', 'luis@gip.test');

insert into auth.identities (
  id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
)
select
  gen_random_uuid(), u.id, u.id::text,
  jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', true),
  'email', now(), now(), now()
from auth.users u
where u.email in ('carmen@gip.test', 'luis@gip.test');
