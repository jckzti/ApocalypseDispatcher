# Modding Basico

Esta demo ja separa grande parte do gameplay em JSON. O caminho suportado hoje para modding leve e criar ou editar arquivos em `data/` e validar tudo com a CLI de conteudo.

## O que pode ser modado

- `data/game_modes/*.json`: regras macro de um modo, deck permitido, objetivos-base e tags.
- `data/scenarios/*.json`: recursos iniciais, frota, objetivos especificos e eventos liberados.
- `data/maps/*.json`: distritos, estradas, posicoes visuais e tags do mapa.
- `data/cards/*.json`: cartas, raridade, efeitos por nivel e restricoes.
- `data/events/*.json`: eventos, triggers, opcoes e efeitos.

## Fluxo recomendado

1. Copie um arquivo existente do mesmo tipo que voce quer criar.
2. Troque `id` e `name` por valores unicos.
3. Ajuste apenas um sistema por vez.
4. Rode a validacao de conteudo.
5. Se mexeu em um cenario completo, rode autoplay ou simulacao em lote.

## Estrutura minima de Game Mode

```json
{
  "id": "challenge_zero_fuel",
  "name": "Desafio - Combustivel Zero",
  "description": "Frota remendada e deck enxuto.",
  "scenario_pool": ["desafio_combustivel_zero"],
  "allowed_cards": ["card_public_map", "card_fuel_rationing"],
  "allowed_card_classes": ["logistics", "engineering"],
  "tags": ["challenge", "fuel"],
  "ruleset_modifiers": {
    "mode_label": "Desafio",
    "card_offer_minutes": [6, 14, 28]
  },
  "objective_set": [
    { "type": "limited_fleet", "value": 1, "label": "Operar com frota parcial" }
  ],
  "end_condition_set": {
    "max_minutes": 360,
    "command_center_lost": true
  },
  "reward_curve": {}
}
```

## Estrutura minima de Scenario

```json
{
  "id": "desafio_exemplo",
  "name": "Desafio Exemplo",
  "game_mode_id": "challenge_zero_fuel",
  "map_id": "cidade_cinza",
  "starting_seed_mode": "fixed",
  "starting_resources": {
    "budget": 8,
    "fuel": 40,
    "order": 45,
    "trust": 48,
    "communication": 4,
    "intelligence": 2,
    "medical_supplies": 8,
    "parts": 4,
    "authority": 0
  },
  "starting_buses": [
    { "id": "bus_demo_01", "capacity": 60, "fuel_max": 170, "fuel_current": 95, "speed_kmh": 36, "tags": ["challenge"] }
  ],
  "starting_cards": ["card_public_map"],
  "allowed_card_classes": ["logistics", "engineering"],
  "allowed_event_ids": ["event_supply_drop"],
  "objectives": [
    { "type": "save_population", "value": 500, "label": "Salvar 500 pessoas" }
  ],
  "end_conditions": {},
  "metadata": {
    "card_offer_repeat_interval_minutes": 14
  }
}
```

## Como a resolucao funciona

- `ScenarioDef` agora aponta para um `game_mode_id`.
- Em runtime, o jogo resolve um cenario final somando:
  - `ruleset_modifiers` do modo em `metadata`;
  - `objective_set` do modo antes dos objetivos do cenario;
  - `end_condition_set` do modo antes dos overrides do cenario;
  - `allowed_cards` e `allowed_card_classes` do modo junto das restricoes do cenario.

Na pratica:

- use `game_modes` para regras compartilhadas;
- use `scenarios` para tuning local de uma run.

## Comandos uteis

Validar conteudo:

```powershell
$env:APPDATA="$PWD/.godot/appdata"
$env:LOCALAPPDATA="$PWD/.godot/localappdata"
$env:TEMP="$PWD/.godot/temp"
$env:TMP="$PWD/.godot/temp"
godot --headless --path . -s scripts/tools/ValidateContentCli.gd -- --root=data
```

Rodar autoplay de um cenario:

```powershell
godot --headless --path . -s scripts/tools/AutoplayScenarioCli.gd -- --scenario=desafio_combustivel_zero --minutes=240 --seed=20260420
```

Rodar simulacao em lote:

```powershell
godot --headless --path . -s scripts/tools/SimulateRunsCli.gd -- --scenario=desafio_combustivel_zero --runs=50 --minutes=240 --seed-start=7000
```

## Limites atuais

- O sistema ainda nao suporta hot-reload de mods dentro da run.
- Nao ha sandbox para mods; arquivos malformados vao falhar na validacao.
- Deck por modo hoje e restricao de oferta, nao editor visual.
- O ZIP de release nao inclui esta documentacao; ela fica no repositório de desenvolvimento.
