#!/usr/bin/env bash
set -euo pipefail

if ! command -v godot >/dev/null 2>&1; then
  echo "godot nao encontrado no PATH."
  exit 127
fi

mkdir -p .godot/appdata .godot/localappdata .godot/logs .godot/temp .godot/downloads
mkdir -p dist/windows dist/linux dist/web
rm -rf tmp/release

export APPDATA="$(pwd)/.godot/appdata"
export LOCALAPPDATA="$(pwd)/.godot/localappdata"
export TMP="$(pwd)/.godot/temp"
export TEMP="$(pwd)/.godot/temp"

declare -a exports=(
  "Windows Desktop|dist/windows/DespachanteDoApocalipse.exe|windows_export.log"
  "Linux/X11|dist/linux/DespachanteDoApocalipse.x86_64|linux_export.log"
  "Web|dist/web/index.html|web_export.log"
)

failures=0
for item in "${exports[@]}"; do
  preset="${item%%|*}"
  rest="${item#*|}"
  output="${rest%%|*}"
  log_file=".godot/logs/${rest##*|}"
  mkdir -p "$(dirname "$output")"
  echo "Exportando ${preset} -> ${output}"
  if godot --headless --path . --log-file "$(pwd)/${log_file}" --export-release "${preset}" "$(pwd)/${output}"; then
    echo "OK: ${preset}"
  else
    failures=$((failures + 1))
    echo "FALHA: ${preset}. Verifique ${log_file}"
  fi
done

if [ "$failures" -gt 0 ]; then
  echo "Export finalizado com ${failures} falha(s)."
  exit 1
fi

find dist/web -maxdepth 1 -type f -name '*.import' -delete

echo "Todos os exports configurados foram gerados em ./dist."
