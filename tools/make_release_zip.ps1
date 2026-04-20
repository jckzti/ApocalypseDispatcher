param()

$ErrorActionPreference = "Stop"

$versionMatch = Select-String -Path "scripts/core/GameConstants.gd" -Pattern 'GAME_VERSION := "([^"]+)"' | Select-Object -First 1
$version = if ($versionMatch) { $versionMatch.Matches[0].Groups[1].Value } else { "0.1.0-dev" }

if (-not (Test-Path -LiteralPath "dist")) {
	throw "Pasta dist inexistente. Execute tools/export_builds.ps1 antes."
}

$requiredOutputs = @(
	"dist\windows\DespachanteDoApocalipse.exe",
	"dist\linux\DespachanteDoApocalipse.x86_64"
)
foreach ($requiredPath in $requiredOutputs) {
	if (-not (Test-Path -LiteralPath $requiredPath)) {
		throw "Arquivo de build ausente: $requiredPath. Execute tools/export_builds.ps1 com os templates corretos antes de gerar o ZIP."
	}
}

$stagingRoot = Join-Path (Get-Location) "tmp\release"
$stagingPath = Join-Path $stagingRoot ("despachante-do-apocalipse-{0}" -f $version)
$zipPath = Join-Path (Get-Location) ("release\despachante-do-apocalipse-{0}.zip" -f $version)

New-Item -ItemType Directory -Force -Path "release", $stagingRoot | Out-Null
if (Test-Path -LiteralPath $stagingPath) {
	Remove-Item -LiteralPath $stagingPath -Recurse -Force
}
if (Test-Path -LiteralPath $zipPath) {
	Remove-Item -LiteralPath $zipPath -Force
}

New-Item -ItemType Directory -Force -Path $stagingPath, (Join-Path $stagingPath "docs") | Out-Null
Copy-Item -LiteralPath "dist" -Destination (Join-Path $stagingPath "dist") -Recurse -Force
Copy-Item -LiteralPath "README.md" -Destination (Join-Path $stagingPath "README.md") -Force
Copy-Item -LiteralPath "docs/credits_and_licenses.md" -Destination (Join-Path $stagingPath "docs\credits_and_licenses.md") -Force
Copy-Item -LiteralPath "docs/release_checklist.md" -Destination (Join-Path $stagingPath "docs\release_checklist.md") -Force

Compress-Archive -LiteralPath $stagingPath -DestinationPath $zipPath -Force
Write-Host ("Release gerada em {0}" -f $zipPath)
