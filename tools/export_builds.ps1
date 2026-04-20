param(
	[string]$TemplateArchive = "",
	[string]$TemplateDir = "",
	[switch]$SkipWeb
)

$ErrorActionPreference = "Stop"

$godot = Get-Command godot -ErrorAction SilentlyContinue
if (-not $godot) {
	throw "godot nao encontrado no PATH."
}

$repoRoot = (Get-Location).Path
$localDirs = @(
	".godot\appdata",
	".godot\localappdata",
	".godot\logs",
	".godot\temp",
	".godot\downloads",
	"dist\windows",
	"dist\linux",
	"dist\web"
)
New-Item -ItemType Directory -Force -Path $localDirs | Out-Null

$transientPaths = @(
	"tmp\release"
)
foreach ($relativePath in $transientPaths) {
	$absolutePath = Join-Path $repoRoot $relativePath
	if (Test-Path -LiteralPath $absolutePath) {
		Remove-Item -LiteralPath $absolutePath -Recurse -Force
	}
}

$env:APPDATA = Join-Path $repoRoot ".godot\appdata"
$env:LOCALAPPDATA = Join-Path $repoRoot ".godot\localappdata"
$env:TEMP = Join-Path $repoRoot ".godot\temp"
$env:TMP = Join-Path $repoRoot ".godot\temp"

$version = "4.6.2.stable"
$templatesRoot = Join-Path $env:APPDATA "Godot\export_templates\$version"

function Install-TemplatesFromDirectory {
	param([string]$SourceDir)
	if (-not (Test-Path -LiteralPath $SourceDir)) {
		throw "Diretorio de templates nao encontrado: $SourceDir"
	}
	$candidate = Get-ChildItem -LiteralPath $SourceDir -Recurse -Directory |
		Where-Object { Test-Path (Join-Path $_.FullName "version.txt") } |
		Select-Object -First 1
	if (-not $candidate) {
		if (Test-Path (Join-Path $SourceDir "version.txt")) {
			$candidate = Get-Item -LiteralPath $SourceDir
		}
	}
	if (-not $candidate) {
		throw "Nao foi possivel localizar um conjunto valido de templates em $SourceDir"
	}
	New-Item -ItemType Directory -Force -Path $templatesRoot | Out-Null
	Copy-Item -Path (Join-Path $candidate.FullName "*") -Destination $templatesRoot -Recurse -Force
}

function Install-TemplatesFromArchive {
	param([string]$ArchivePath)
	if (-not (Test-Path -LiteralPath $ArchivePath)) {
		throw "Arquivo de templates nao encontrado: $ArchivePath"
	}
	$stagingRoot = Join-Path $repoRoot "tmp\export_templates"
	$zipPath = Join-Path $stagingRoot "templates.zip"
	$extractPath = Join-Path $stagingRoot "unzipped"
	if (Test-Path -LiteralPath $stagingRoot) {
		Remove-Item -LiteralPath $stagingRoot -Recurse -Force
	}
	New-Item -ItemType Directory -Force -Path $stagingRoot | Out-Null
	Copy-Item -LiteralPath $ArchivePath -Destination $zipPath -Force
	Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force
	Install-TemplatesFromDirectory -SourceDir $extractPath
}

if ($TemplateArchive) {
	Install-TemplatesFromArchive -ArchivePath (Resolve-Path -LiteralPath $TemplateArchive).Path
} elseif ($TemplateDir) {
	Install-TemplatesFromDirectory -SourceDir (Resolve-Path -LiteralPath $TemplateDir).Path
}

if (-not (Test-Path -LiteralPath $templatesRoot)) {
	throw "Templates de exportacao ausentes em $templatesRoot. Passe -TemplateArchive ou -TemplateDir com os templates 4.6.2.stable."
}

$exports = @(
	@{ Preset = "Windows Desktop"; Output = "dist\windows\DespachanteDoApocalipse.exe"; Log = ".godot\logs\windows_export.log" },
	@{ Preset = "Linux/X11"; Output = "dist\linux\DespachanteDoApocalipse.x86_64"; Log = ".godot\logs\linux_export.log" }
)
if (-not $SkipWeb) {
	$exports += @{ Preset = "Web"; Output = "dist\web\index.html"; Log = ".godot\logs\web_export.log" }
}

$failures = @()
foreach ($entry in $exports) {
	$outputPath = Join-Path $repoRoot $entry.Output
	$logPath = Join-Path $repoRoot $entry.Log
	New-Item -ItemType Directory -Force -Path (Split-Path $outputPath -Parent) | Out-Null
	Write-Host ("Exportando {0} -> {1}" -f $entry.Preset, $entry.Output)
	& $godot.Source --headless --path . --log-file $logPath --export-release $entry.Preset $outputPath
	if ($LASTEXITCODE -ne 0) {
		$failures += $entry.Preset
		Write-Warning ("Falha em {0}. Verifique {1}" -f $entry.Preset, $entry.Log)
		continue
	}
	Write-Host ("OK: {0}" -f $entry.Preset)
}

if ($failures.Count -gt 0) {
	throw ("Export finalizado com falha em: {0}" -f ($failures -join ", "))
}

$webImportFiles = Get-ChildItem -Path (Join-Path $repoRoot "dist\web") -Filter "*.import" -File -ErrorAction SilentlyContinue
foreach ($file in $webImportFiles) {
	Remove-Item -LiteralPath $file.FullName -Force
}

Write-Host "Todos os exports configurados foram gerados em ./dist."
