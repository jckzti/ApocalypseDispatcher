# Despachante do Apocalipse

Bootstrap inicial do projeto em Godot 4.x para o jogo "Despachante do Apocalipse".

## Requisitos

- Godot 4.x instalado e acessivel no `PATH` como `godot`

## Como rodar

Para abrir o projeto no editor:

```bash
godot --path .
```

Para validar o bootstrap em modo headless:

```bash
godot --headless --path . --quit
```

Para executar os placeholders desta fase:

```bash
bash tools/run_tests.sh
bash tools/validate_content.sh
```

Em ambientes restritos, o Codex validou o projeto redirecionando `APPDATA` e `LOCALAPPDATA` para `./.godot/` antes de invocar o Godot.

## Estrutura inicial

O repositorio ja contem a base de pastas para:

- `assets/`
- `data/`
- `docs/`
- `scenes/`
- `scripts/`
- `tests/`
- `tools/`

## Status

- Fase 00 do plano mestre: concluida
- Gameplay: ainda nao implementado
- Proximo passo: Fase 01, core deterministico
