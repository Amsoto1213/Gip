---
description: Revisa los cambios de la rama contra la arquitectura y el diseño
---

Revisa los cambios de esta rama frente a `main` (`git diff main...HEAD`):

1. Corre `bash tool/check_layers.sh` y reporta violaciones.
2. Compara nombres de clases, firmas de operaciones y flujo con `docs/diseno/clases.md` y el `secuencias/CUS-XX.md` correspondiente. Lista las diferencias.
3. Verifica las reglas del dominio de CLAUDE.md: UUID, `tienda_id` en toda consulta, unidad de trabajo en operaciones de varios repositorios, entrada en `cola_pendientes`, registros que solo se agregan, `Decimal` para dinero. Que no se haya agregado seguridad fuera del inicio de sesión (nada de RLS, PIN ni cierre por inactividad).
4. Señala reglas de negocio sin prueba unitaria.

Entrega una lista priorizada (bloqueante / importante / menor) con archivo y línea. No cambies código.
