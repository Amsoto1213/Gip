---
description: Implementa un caso de uso del sistema (CUS-XX) siguiendo el diseño de EA
argument-hint: CUS-XX
---

Vamos a implementar $ARGUMENTS.

1. Lee `docs/diseno/secuencias/$ARGUMENTS.md` completo y, en `docs/diseno/clases.md`, cada clase que aparece como participante.
2. Revisa qué ya existe en `lib/` y `test/` para esas clases (no dupliques).
3. Revisa el mockup de la pantalla en `docs/ui/mockups/` (busca el CUS en `docs/ui/pantallas.md`).
4. Presenta un plan corto: archivos que vas a crear o cambiar por capa, en este orden: entidades → interfaces → pruebas del servicio con repositorios falsos → servicio → coordinador → repositorio drift (+ tabla y migración si hace falta) → view model → vista. Señala cualquier diferencia entre el diagrama y el código existente y cualquier archivo compartido que vayas a tocar (ver CLAUDE.md).
5. **Espera mi aprobación antes de escribir código.**
6. Al terminar: `flutter analyze`, `flutter test`, `bash tool/check_layers.sh`, y un resumen de lo hecho con el mensaje de commit sugerido (`feat(<modulo>): $ARGUMENTS ...`).
