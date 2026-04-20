#!/usr/bin/env bash
set -euo pipefail

if ! command -v godot >/dev/null 2>&1; then
  echo "godot nao encontrado no PATH."
  echo "A validacao de conteudo sera implementada em fases futuras."
  exit 127
fi

mkdir -p .godot/appdata .godot/localappdata .godot/logs

echo "Fase 00: validacao de conteudo ainda nao implementada; executando smoke test do bootstrap."
APPDATA="$(pwd)/.godot/appdata" \
LOCALAPPDATA="$(pwd)/.godot/localappdata" \
godot --headless --path . --log-file "$(pwd)/.godot/logs/validate_content.log" --quit
