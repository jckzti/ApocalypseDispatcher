#!/usr/bin/env bash
set -euo pipefail

if ! command -v godot >/dev/null 2>&1; then
  echo "godot nao encontrado no PATH."
  echo "Nao foi possivel executar os testes automatizados."
  exit 127
fi

mkdir -p .godot/appdata .godot/localappdata .godot/logs .godot/temp

echo "Executando testes unitarios."
APPDATA="$(pwd)/.godot/appdata" \
LOCALAPPDATA="$(pwd)/.godot/localappdata" \
TMP="$(pwd)/.godot/temp" \
TEMP="$(pwd)/.godot/temp" \
godot --headless --path . --log-file "$(pwd)/.godot/logs/run_tests_unit.log" -s addons/gut/gut_cmdln.gd -- -gdir=tests/unit -gexit

echo "Executando testes de integracao."
APPDATA="$(pwd)/.godot/appdata" \
LOCALAPPDATA="$(pwd)/.godot/localappdata" \
TMP="$(pwd)/.godot/temp" \
TEMP="$(pwd)/.godot/temp" \
godot --headless --path . --log-file "$(pwd)/.godot/logs/run_tests_integration.log" -s addons/gut/gut_cmdln.gd -- -gdir=tests/integration -gexit
