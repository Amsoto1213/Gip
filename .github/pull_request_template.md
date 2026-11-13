## Caso de uso

CUS-XX — <nombre> · Cierra #<issue>

## Qué cambia

- 

## Checklist

- [ ] Sigue `docs/diseno/secuencias/CUS-XX.md` (o la diferencia está en `docs/decisiones.md`)
- [ ] Reglas de negocio con prueba unitaria
- [ ] `flutter analyze`, `flutter test` y `bash tool/check_layers.sh` pasan
- [ ] Probado en Android y en Chrome
- [ ] Probado sin internet (modo avión) si el CUS es crítico (venta, entrada, fiado, existencias)
- [ ] Si cambió el esquema: migración drift (`schemaVersion`) **y** migración Supabase
- [ ] Capturas de pantalla (móvil y web)
