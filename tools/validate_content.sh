#!/usr/bin/env bash
set -euo pipefail

if ! command -v godot >/dev/null 2>&1; then
  echo "godot nao encontrado no PATH."
  echo "Nao foi possivel validar o conteudo."
  exit 127
fi

mkdir -p .godot/appdata .godot/localappdata .godot/logs .godot/temp

echo "Validando conteudo JSON."
APPDATA="$(pwd)/.godot/appdata" \
LOCALAPPDATA="$(pwd)/.godot/localappdata" \
TMP="$(pwd)/.godot/temp" \
TEMP="$(pwd)/.godot/temp" \
godot --headless --path . --log-file "$(pwd)/.godot/logs/validate_content.log" -s scripts/tools/ValidateContentCli.gd -- --root=data
