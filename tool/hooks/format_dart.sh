#!/usr/bin/env bash
# Hook PostToolUse de Claude Code: formatea con `dart format` el archivo .dart que Claude acaba de editar.
# Lee el JSON del evento por stdin y extrae tool_input.file_path sin depender de jq.
input=$(cat)
file=$(printf '%s' "$input" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"\(.*\)"/\1/')
case "$file" in
  *.g.dart) ;;                                   # código generado: no tocar
  *.dart) dart format "$file" >/dev/null 2>&1 ;;
esac
exit 0
