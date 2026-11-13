---
description: Crea o cambia una tabla en drift (local) y en Supabase (servidor) de forma consistente
argument-hint: descripción del cambio
---

Cambio de esquema: $ARGUMENTS

1. Ubica el módulo y la tabla en `lib/data/local/tablas/<modulo>.dart`.
2. Toda tabla sincronizable lleva: `id` (UUID texto), `tienda_id`, `creado_en`, `actualizado_en` (UTC); las de solo-agregar no se editan.
3. Cambia la tabla drift, sube `schemaVersion` y agrega el paso en `migration` de `BaseLocalDrift`. Corre `dart run build_runner build --delete-conflicting-outputs`.
4. Crea la migración del servidor con `npx supabase migration new <nombre>` con la tabla equivalente en PostgreSQL (`uuid`, `numeric`, `timestamptz`), índice por `tienda_id`. Sin RLS ni políticas: la seguridad está fuera del alcance (CLAUDE.md).
5. Corre `npx supabase db reset` para validar y agrega datos de prueba en `supabase/seed.sql` si sirven.
6. Muéstrame el diff de ambos lados antes de terminar.
