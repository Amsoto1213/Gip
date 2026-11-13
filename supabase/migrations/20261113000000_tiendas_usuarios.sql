-- Migración inicial: tiendas y usuarios.
-- Inicio de sesión con Supabase Auth (correo y contraseña). Sin RLS ni políticas:
-- el resto de la seguridad está fuera del alcance del curso (ver CLAUDE.md y DI-05).
-- Plantilla para las demás tablas: id uuid, tienda_id con índice, creado_en y actualizado_en.

create table public.tiendas (
  id              uuid primary key,
  codigo          text not null unique,
  nombre          text not null,
  direccion       text,
  creado_en       timestamptz not null default now(),
  actualizado_en  timestamptz not null default now()
);

create type public.rol_usuario as enum ('ADMINISTRADOR', 'EMPLEADO');

-- Usuario del GIP (clase Usuario y subclases Administrador / Empleado).
-- `correo` es el mismo con el que la persona inicia sesión en Supabase Auth.
create table public.usuarios (
  id              uuid primary key,
  tienda_id       uuid not null references public.tiendas (id),
  nombre          text not null,
  cedula          text not null,
  correo          text not null unique,
  rol             public.rol_usuario not null,
  activo          boolean not null default true,
  creado_en       timestamptz not null default now(),
  actualizado_en  timestamptz not null default now(),
  unique (tienda_id, cedula)
);
create index usuarios_tienda_idx on public.usuarios (tienda_id);
