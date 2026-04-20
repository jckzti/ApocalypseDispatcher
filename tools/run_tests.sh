#!/usr/bin/env bash
set -euo pipefail

if ! command -v godot >/dev/null 2>&1; then
  echo "godot nao encontrado no PATH."
  echo "Fase 00 possui apenas smoke test do projeto."
  exit 127
fi

mkdir -p .godot/appdata .godot/localappdata .godot/logs

echo "Fase 00: executando smoke test headless do projeto."
APPDATA="$(pwd)/.godot/appdata" \
LOCALAPPDATA="$(pwd)/.godot/localappdata" \
godot --headless --path . --log-file "$(pwd)/.godot/logs/run_tests.log" --quit
