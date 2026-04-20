# Despachante do Apocalipse

Demo em Godot 4.x de um roguelite/simulador tatico de evacuacao urbana em colapso.

## O que ja existe

- tutorial jogavel;
- campanha base `Cidade Cinza`;
- desafio pos-MVP `Combustivel Zero`;
- desafio diario com seed fixa por data e mutadores rotativos;
- modo infinito `Colapso Total`;
- ranking local por seed no resumo lateral e no relatorio final;
- base de localizacao `pt_BR` / `en_US` na UI principal e no relatorio final;
- sistema de cartas, eventos, score final, save/load e autosave;
- validacao headless de conteudo, autoplay e simulacao em lote para balanceamento.

## Como abrir o projeto

```bash
godot --path .
```

Em ambientes restritos, use `APPDATA` e `LOCALAPPDATA` apontando para `./.godot/` antes de invocar o Godot.

## Como jogar a demo atual

1. Abra o projeto e entre na cena principal.
2. Escolha um cenario no topo.
3. Clique em um distrito de origem e em um abrigo.
4. Use `Criar Rota`.
5. Rode a simulacao com `Iniciar Simulacao` ou avance minuto a minuto.
6. Resolva eventos, escolha cartas e acompanhe o relatorio final.

## Atalhos atuais

- `Espaco`: iniciar/pausar simulacao
- `.`: avancar 1 minuto
- `R`: criar rota com a selecao atual
- `G`: gerar oferta de cartas
- `Ctrl+S`: salvar
- `Ctrl+L`: carregar
- `1`, `2`, `3`: escolher opcoes de evento

## Saves e configuracoes

- Save manual: `user://saves/current_run.json`
- Autosave: `user://saves/autosave.json`
- Perfil: `user://profile.json`
- Configuracoes de acessibilidade/UX: `user://settings.json`

`settings.json` agora tambem persiste o locale da interface.

Isso significa que os saves **nao** ficam dentro da pasta da build exportada.

## Validacao local

```bash
bash tools/run_tests.sh
bash tools/validate_content.sh
```

No Windows, sem depender de `bash`:

```powershell
$env:APPDATA="$PWD/.godot/appdata"
$env:LOCALAPPDATA="$PWD/.godot/localappdata"
$env:TEMP="$PWD/.godot/temp"
$env:TMP="$PWD/.godot/temp"
godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/unit -gexit
godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/integration -gexit
godot --headless --path . -s scripts/tools/ValidateContentCli.gd -- --root=data
```

Validadores adicionais:

- `scripts/tools/AutoplayScenarioCli.gd`
- `scripts/tools/SimulateRunsCli.gd`

Exemplo de autoplay do desafio diario para uma data especifica:

```powershell
godot --headless --path . -s scripts/tools/AutoplayScenarioCli.gd -- --scenario=desafio_diario --date=2026-04-20 --minutes=360
```

## Export e release

Arquivos adicionados para distribuicao:

- `export_presets.cfg`
- `tools/export_builds.sh`
- `tools/make_release_zip.sh`
- `tools/export_builds.ps1`
- `tools/make_release_zip.ps1`
- `docs/release_checklist.md`
- `docs/credits_and_licenses.md`

Fluxo esperado:

```bash
bash tools/export_builds.sh
bash tools/make_release_zip.sh
```

Fluxo equivalente em PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File tools/export_builds.ps1
powershell -ExecutionPolicy Bypass -File tools/make_release_zip.ps1
```

Se os templates de exportacao nao estiverem instalados, passe um pacote local oficial:

```powershell
powershell -ExecutionPolicy Bypass -File tools/export_builds.ps1 -TemplateArchive .\.godot\downloads\Godot_v4.6.2-stable_export_templates.tpz
```

## Documentacao

- Balanceamento: `docs/balance_notes.md`
- Creditos/licencas: `docs/credits_and_licenses.md`
- Checklist de release: `docs/release_checklist.md`
- Modding basico: `docs/modding.md`
