#!/usr/bin/env bash
set -euo pipefail

VERSION="$(sed -n 's/.*GAME_VERSION := \"\(.*\)\"/\1/p' scripts/core/GameConstants.gd | head -n 1)"
if [ -z "${VERSION}" ]; then
  VERSION="0.1.0-dev"
fi

if [ ! -d dist ]; then
  echo "Pasta dist inexistente. Execute tools/export_builds.sh antes."
  exit 1
fi

required_outputs=(
  "dist/windows/DespachanteDoApocalipse.exe"
  "dist/linux/DespachanteDoApocalipse.x86_64"
)

for required_path in "${required_outputs[@]}"; do
  if [ ! -f "${required_path}" ]; then
    echo "Arquivo de build ausente: ${required_path}. Execute tools/export_builds.sh com os templates corretos antes de gerar o ZIP."
    exit 1
  fi
done

mkdir -p release tmp/release
STAGING="tmp/release/despachante-do-apocalipse-${VERSION}"
ZIP_PATH="release/despachante-do-apocalipse-${VERSION}.zip"

rm -rf "${STAGING}"
mkdir -p "${STAGING}"

cp -R dist "${STAGING}/dist"
cp README.md "${STAGING}/README.md"
mkdir -p "${STAGING}/docs"
cp docs/credits_and_licenses.md "${STAGING}/docs/credits_and_licenses.md"
cp docs/release_checklist.md "${STAGING}/docs/release_checklist.md"

if command -v zip >/dev/null 2>&1; then
  (cd tmp/release && rm -f "../../${ZIP_PATH}" && zip -r "../../${ZIP_PATH}" "despachante-do-apocalipse-${VERSION}" >/dev/null)
elif command -v python >/dev/null 2>&1; then
  python - "${STAGING}" "${ZIP_PATH}" <<'PY'
import os, sys, zipfile
staging, zip_path = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
    base = os.path.dirname(staging)
    for root, _, files in os.walk(staging):
        for file_name in files:
            full = os.path.join(root, file_name)
            rel = os.path.relpath(full, base)
            zf.write(full, rel)
PY
else
  echo "Nenhuma ferramenta para criar ZIP encontrada (zip/python)."
  exit 127
fi

echo "Release gerada em ${ZIP_PATH}"
