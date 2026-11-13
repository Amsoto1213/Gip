#!/usr/bin/env bash
# Verifica que las dependencias entre capas respeten la arquitectura del GIP (DA-01, DA-02, DA-38).
# Uso: bash tool/check_layers.sh   (sale con código 1 si encuentra violaciones)
set -u
cd "$(dirname "$0")/.."

fail=0

# imports en un directorio que coincidan con un patrón prohibido
check() {
  local dir="$1" pattern="$2" rule="$3"
  [ -d "$dir" ] || return 0
  local hits
  hits=$(grep -rnE --include='*.dart' "^\s*(import|export)\s+['\"]([^'\"]*)($pattern)" "$dir" | grep -v '\.g\.dart:' || true)
  if [ -n "$hits" ]; then
    echo "✗ $rule"
    echo "$hits" | sed 's/^/    /'
    fail=1
  fi
}

# 1. Business Layer en Dart puro
check lib/business "package:flutter/|package:drift|package:supabase|package:sqlite3|dart:ui|dart:io" \
  "business/ debe ser Dart puro (sin Flutter, drift, Supabase ni dart:io)"
check lib/business "(/|^)data/|(/|^)presentation/|(/|^)composition_root/|package:gip/main\.dart" \
  "business/ no puede depender de data/, presentation/ ni del composition root"

# 2. Orden interno de la Business Layer: workflow -> componentes -> interfaces -> entidades
check lib/business/entidades "(/|^)(interfaces|componentes|workflow)/" \
  "entidades/ no depende de interfaces/, componentes/ ni workflow/"
check lib/business/interfaces "(/|^)(componentes|workflow)/" \
  "interfaces/ no depende de componentes/ ni workflow/"
check lib/business/componentes "(/|^)workflow/" \
  "componentes/ no depende de workflow/"

# 3. Presentation solo usa workflow y entidades
check lib/presentation "(/|^)data/|business/componentes/|business/interfaces/|package:drift|package:supabase" \
  "presentation/ solo puede usar business/workflow y business/entidades"

# 4. Data implementa interfaces; no sube a presentation ni a la lógica
check lib/data "(/|^)presentation/|business/workflow/|business/componentes/|package:flutter/material" \
  "data/ no depende de presentation/, workflow/ ni componentes/"

# 5. Transversal no depende de ninguna capa
check lib/transversal "(/|^)(business|data|presentation)/" \
  "transversal/ no depende de ninguna capa"

if [ "$fail" -eq 0 ]; then
  echo "✓ Dependencias entre capas correctas"
fi
exit "$fail"
