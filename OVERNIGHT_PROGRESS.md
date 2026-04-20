# Overnight Progress

## Resumo acumulado

- Fases concluídas nesta sessão: `01` até `25`.
- Fase atual do repositório: `25`.
- Estado atual do projeto:
  - campanha base, tutorial, save/load, score final, modo infinito e UI jogável estão implementados;
  - o projeto segue com `40` cartas, `35` eventos, `5` game modes, `3` mapas e `6` cenários validados;
  - o menu principal da cena em `Main.gd` agora mostra a versão da demo e abre créditos/licenças;
  - há tooling de export/release em `sh` e em `ps1`, com build exportada para `Windows`, `Linux` e `Web`;
  - o artefato final de distribuição foi gerado em `release/despachante-do-apocalipse-0.1.0-dev.zip`;
  - a runtime agora resolve `game_modes` data-driven, inclui os desafios `Combustivel Zero` e `Desafio Diario`, mostra ranking local por seed e ranking diario por data;
  - a UI principal e o relatorio final agora alternam entre `pt_BR` e `en_US` com locale persistido em `settings.json`.
  - a apresentacao da run foi reestruturada: mapa desenhado, estradas, placas de distrito, onibus com token proprio e HUD em secoes.

## O que foi feito nesta etapa

- Fase 19:
  - adicionados `export_presets.cfg`, `tools/export_builds.ps1` e `tools/make_release_zip.ps1`;
  - reforçados os scripts `sh` existentes para usar `TMP` e `TEMP` locais;
  - criado o fluxo de créditos/licenças no menu e atualizado o `README.md` de jogador/release;
  - os scripts de release passaram a falhar cedo se faltarem templates ou arquivos exportados reais;
  - os presets de export passaram a excluir docs, tooling e staging do `.pck`;
  - o fluxo de export passou a limpar `tmp/release` e remover `*.import` residuais do `dist/web`.
- Fase 20:
  - `AutoplayScenarioCli.gd` ganhou QA explícita de tutorial, save manual automatizado e heurística melhor de cartas/eventos;
  - o tutorial foi rebalanceado para um alvo final coerente com o mapa curto e oferta de carta mais cedo;
  - corrigido o link quebrado de documentação no `README.md`;
  - export final executado com templates oficiais `4.6.2.stable` a partir de `C:\\jogoCodex\\.godot\\downloads\\Godot_v4.6.2-stable_export_templates.tpz`;
  - release zip final gerado e conferido.
- Fase 21:
  - criada a categoria `data/game_modes/` com `GameModeDef.gd`, resolucao de cenario em runtime e restricao de deck por modo;
  - migrados os cenarios existentes para `game_mode_id`;
  - criado o cenario `desafio_combustivel_zero`;
  - criado `docs/modding.md` com autoracao basica de `game_modes` e `scenarios`.
- Fase 22:
  - `ScoreSystem.gd` passou a registrar a seed no relatorio final;
  - `SaveService.gd` passou a persistir ranking local por seed;
  - `Main.gd` e `EndRunReport.gd` agora mostram seed atual e melhores runs locais por cenario.
- Fase 23:
  - criado `DailyChallengeService.gd` para seed fixa por data, rotacao de cenario base e mutadores diarios;
  - criado o modo `daily_ops` e o cenario `desafio_diario`;
  - `SaveService.gd`, `ScoreSystem.gd`, `Main.gd`, `AutoplayScenarioCli.gd` e `SimulateRunsCli.gd` passaram a entender leaderboard e contexto diario.
- Fase 24:
  - criado `LocalizationService.gd` com catalogos `pt_BR` e `en_US`;
  - `SettingsService.gd` passou a persistir `locale`;
  - `Main.gd` ganhou seletor de idioma e aplicacao de localizacao nos principais textos da HUD;
  - `EndRunReport.gd` passou a seguir o locale ativo nos labels e botoes.
- Fase 25:
  - criado `scripts/ui/OperationsMapView.gd` para desenhar o teatro operacional no lugar dos antigos botões/retângulos do mapa;
  - `Main.gd` foi reorganizado em superfícies visuais com hierarquia mais clara, header de situação, barra de comando agrupada e lateral seccionada;
  - selecao, frota e ordens passaram a mostrar nomes legíveis, preview de rota e estados de ônibus localizados;
  - o layout do mapa ganhou padding e reposicionamento adaptativo das placas, corrigindo o recorte do abrigo e a sobreposição mais gritante do tutorial;
  - a build web foi reexportada e validada de novo em Playwright após o redesign.

## O que foi testado

- Conteúdo:
  - `godot --headless --path . -s scripts/tools/ValidateContentCli.gd -- --root=data`
  - resultado final: `Cards: 40 | Events: 35 | GameModes: 5 | Maps: 3 | Scenarios: 6`
- Testes automatizados:
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/unit -gexit`
  - resultado final: `48 ok, 0 falhas`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/integration -gexit`
  - resultado final: `5 ok, 0 falhas`
- Smoke:
  - `godot --headless --path . --quit-after 1`
  - resultado final: cena principal continua carregando sem erro de script
- QA visual web:
  - `http://localhost:8000/` validado com Playwright após o reexport
  - resultado: carregamento ok, sem erros de console, mapa redesenhado renderizando corretamente e clique em distrito revalidado
- QA automatizada:
  - `campanha_tutorial_primeiras_rotas`: `Tempo 8 | Salvos 62 | Fim tutorial_complete | Tutorial QA 8/8`
  - `campanha_01_cidade_cinza`: `Tempo 287 | Nota B | Fim command_center_lost`
  - `infinito_colapso_total`: `Tempo 20 | Nota C | Fim player_retired | Onda 1`
  - `desafio_combustivel_zero` em autoplay longa: `Tempo 287 | Nota D | Fim command_center_lost`
  - `desafio_diario` em autoplay com `--date=2026-04-20`: `Tempo 287 | Nota D | Fim command_center_lost | Base Desafio - Combustivel Zero | Mutadores Janela de Radio + Tanques Emergenciais`
- Release tooling:
  - `powershell -ExecutionPolicy Bypass -File tools/export_builds.ps1 -TemplateArchive .\\.godot\\downloads\\Godot_v4.6.2-stable_export_templates.tpz`
  - resultado: exports `Windows Desktop`, `Linux/X11` e `Web` gerados com sucesso em `dist/`
  - `powershell -ExecutionPolicy Bypass -File tools/make_release_zip.ps1`
  - resultado: `release/despachante-do-apocalipse-0.1.0-dev.zip` gerado com sucesso
- Balance/QA pós-MVP:
  - `godot --headless --path . -s scripts/tools/SimulateRunsCli.gd -- --scenario=desafio_combustivel_zero --runs=20 --minutes=320 --seed-start=9000`
  - resultado: `20/20` runs completas e `0` seeds quebradas
- Artefatos finais conferidos:
  - `dist/windows/DespachanteDoApocalipse.exe` + `.pck`
  - `dist/linux/DespachanteDoApocalipse.x86_64` + `.pck`
  - `dist/web/index.html`, `.js`, `.wasm`, `.pck` e icones
  - release zip sem `README/docs` embutidos dentro do `.pck` e sem `*.import` no `dist/web`

## Pendências / bloqueios

- Não houve bloqueio remanescente de release ao final desta etapa.
- Risco residual conhecido:
  - o Godot continua emitindo o aviso não fatal sobre `root certificate store` do Windows neste ambiente, mas isso nao impediu testes, export nem empacotamento.
  - a localizacao atual cobre a HUD principal e o relatorio final; logs da simulacao e o conteudo narrativo data-driven continuam majoritariamente em PT-BR.
  - a validacao manual Playwright desta etapa confirmou o clique em distrito apos o redesign, mas nao refez um walkthrough completo ate o relatorio final na interface nova.

## Observações

- O Godot continua emitindo o aviso não fatal sobre `root certificate store` do Windows no sandbox.
- Para qualquer validação headless neste ambiente, o redirecionamento de `APPDATA`, `LOCALAPPDATA`, `TMP` e `TEMP` para `./.godot/` continua obrigatório.
