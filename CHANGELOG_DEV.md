# Changelog de Desenvolvimento

## Fase 00 - Bootstrap do repositorio

- Status: concluida
- Escopo: criado `project.godot` minimo, cena inicial `scenes/main/Main.tscn`, autoloads base, `.gitignore`, `README.md`, estrutura principal de pastas e scripts placeholder em `tools/`.
- Ajustes tecnicos: removido conflito de `class_name` com autoload singleton e documentado o uso de `APPDATA`/`LOCALAPPDATA` dentro de `./.godot/` para validar no sandbox.
- Validacoes executadas:
  - `godot --headless --path . --log-file ... --quit` com `APPDATA` e `LOCALAPPDATA` apontando para `C:\\jogoCodex\\.godot\\...`
  - `godot --path . --log-file ... --quit-after 1` com o mesmo redirecionamento
- Resultado: ambos os smoke tests passaram com codigo de saida `0`.
- Observacoes: o Godot emitiu aviso nao fatal sobre leitura do root certificate store do Windows no sandbox.
- Proximo passo: iniciar a Fase 01, implementando o core deterministico e os primeiros testes automatizados.

## Fases 01 a 11 - Core, simulacao, conteudo e UI inicial

- Status: implementadas nesta sessao
- Escopo:
  - `Fase 01`: core deterministico com `DeterministicRng`, `RunConfig`, `GameState`, `SimulationClock`, `SimulationRunner` e runner de testes headless interno em `addons/gut/`.
  - `Fase 02`: carregamento e validacao de conteudo JSON com `ContentDb`, `ContentValidator`, defs data-driven e CLI `scripts/tools/ValidateContentCli.gd`.
  - `Fases 03 a 05`: grafo da cidade, pathfinding Dijkstra, populacao por coorte, embarque por prioridade, attrition, onibus, ordens de evacuacao e ciclo completo origem -> abrigo.
  - `Fases 06 e 07`: `CollapseDirector`, `ModifierStack` e integracao dos modificadores nos primeiros sistemas de perigo, panico, embarque e consumo.
  - `Fase 08`: sistema de cartas data-driven com `CardOfferGenerator`, `CardSystem`, reroll, upgrade por duplicata e aplicacao de modificadores observaveis.
  - `Fase 09`: `EventDirector` com trigger, cooldown, fila de eventos e aplicacao de opcoes com efeitos imediatos.
  - `Fases 10 e 11`: cena principal convertida em mapa jogavel minimo com distritos clicaveis, criacao de rota, avance de simulacao, marcador de onibus, oferta de cartas e painel de evento conectado aos sistemas.
- Conteudo inicial criado/expandido:
  - `data/maps/tiny_map.json`
  - `data/scenarios/tiny_scenario.json`
  - `data/cards/core_cards.json` com 8 cartas entre raridades comum e lendaria
  - `data/events/core_events.json` com primeiro evento jogavel
- Validacoes executadas:
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/unit -gexit`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/integration -gexit`
  - `godot --headless --path . -s scripts/tools/ValidateContentCli.gd -- --root=data`
  - `godot --headless --path . --quit-after 1`
- Resultado:
  - 31 testes unitarios passaram.
  - 4 testes de integracao passaram.
  - validacao de conteudo passou com `Cards: 8 | Events: 1 | Maps: 1 | Scenarios: 1`.
  - smoke test da cena principal passou em headless.
- Observacoes:
  - o Godot continua emitindo aviso nao fatal sobre leitura do root certificate store do Windows no sandbox.
  - a UI das fases 10 e 11 foi validada por smoke test de carregamento e ligacao de sistemas; walkthrough manual com clique real ainda nao foi executado nesta sessao.
- Proximo passo: seguir para `Fase 12` (cenario tutorial) ou aprofundar `save/load` e mais conteudo jogavel conforme prioridade da proxima sessao.

## Fases 12 a 14 - Tutorial, save/load e relatorio final

- Status: implementadas nesta sessao
- Escopo:
  - `Fase 12`: criado o cenario `campanha_tutorial_primeiras_rotas` com `tutorial_map`, passos guiados, ofertas de carta por marco e 4 eventos roteirizados.
  - `Fase 13`: implementado `SaveService.gd` com save manual, autosave, load, perfil versionado, desbloqueios e roundtrip de runtime restaurando grafo, modificadores, onibus e ordens.
  - `Fase 14`: implementado `ScoreSystem.gd`, overlay `scenes/report/EndRunReport.tscn`, condicoes de fim de run, historico no perfil e relatorio final com score reproduzivel.
- UI e fluxo:
  - a `Main.gd` agora permite selecionar cenario, iniciar nova run, salvar, carregar e concluir a run com relatorio final;
  - o tutorial ensina selecao de origem/abrigo, criacao de rota, avancar tempo, cartas, eventos e save manual;
  - o tutorial desbloqueia cenarios adicionais via perfil ao ser concluido.
- Conteudo criado/expandido:
  - `data/maps/tutorial_map.json`
  - `data/scenarios/tutorial.json`
  - `data/cards/tutorial_cards.json`
  - `data/events/tutorial_events.json`
- Testes adicionados:
  - `tests/unit/test_save_service.gd`
  - `tests/unit/test_score_system.gd`
  - `tests/unit/test_event_filtering.gd`
- Validacoes executadas:
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/unit -gexit`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/integration -gexit`
  - `godot --headless --path . -s scripts/tools/ValidateContentCli.gd -- --root=data`
  - `godot --headless --path . --quit-after 1`
- Resultado:
  - 36 testes unitarios passaram.
  - 5 testes de integracao passaram.
  - validacao de conteudo passou com `Cards: 16 | Events: 9 | Maps: 3 | Scenarios: 3`.
  - smoke test da cena principal passou em headless.
- Observacoes:
  - o Godot continua emitindo aviso nao fatal sobre leitura do root certificate store do Windows no sandbox.
  - o relatorio final foi validado por carga de cena e testes do score; ainda nao houve walkthrough manual completo com cliques reais ate o fim da run.

## Fase 15 - Conteudo inicial da campanha base

- Status: parcialmente avancada nesta sessao
- Escopo entregue:
  - criado o mapa maior `data/maps/cidade_cinza.json` com 12 distritos, 3 abrigos e malha de estradas mais densa;
  - criado o cenario `data/scenarios/campanha_01_cidade_cinza.json` com 3 onibus, recursos iniciais, objetivos e marcos de carta;
  - adicionadas cartas em `data/cards/cidade_cinza_cards.json`;
  - adicionados eventos em `data/events/cidade_cinza_events.json`;
  - adicionado teste de integracao `tests/integration/test_cidade_cinza_scenario.gd` para provar avanço com multiplas ordens.
- Resultado atual:
  - `Cidade Cinza` ja carrega, passa validacao de conteudo e avanca em simulacao headless;
  - o pacote total de conteudo subiu para `16` cartas e `9` eventos.
- O que ainda falta para fechar a fase pelo criterio original do plano:
  - expandir o pacote ate a ordem de grandeza prevista (`40` cartas e `35` eventos);
  - balancear a campanha base com uma run longa completa e mais variedade de builds.

## Fase 15 - Fechamento da campanha base

- Status: concluida nesta sessao
- Escopo entregue:
  - expandido o pacote de conteudo para `40` cartas e `35` eventos com `data/cards/vertical_slice_cards.json` e `data/events/vertical_slice_events.json`;
  - ampliada a campanha `Cidade Cinza` para `8` onibus iniciais e mais marcos de carta;
  - adicionada a CLI `scripts/tools/AutoplayScenarioCli.gd` para validacao headless longa do cenario base;
  - aplicado suporte extra de modificadores em `CardSystem.gd` e `PopulationModel.gd` para sustentar o novo pacote de cartas.
- Validacoes executadas:
  - `godot --headless --path . -s scripts/tools/ValidateContentCli.gd -- --root=data`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/unit -gexit`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/integration -gexit`
  - `godot --headless --path . -s scripts/tools/AutoplayScenarioCli.gd -- --scenario=campanha_01_cidade_cinza --minutes=540 --seed=20260420`
- Resultado:
  - conteudo validado com `Cards: 40 | Events: 35 | Maps: 3 | Scenarios: 3` naquele momento do projeto;
  - autoplay longo da campanha encerrou com score reproducivel e sem falhas de runtime.

## Fase 16 - Modo infinito

- Status: concluida nesta sessao
- Escopo:
  - criado o cenario `data/scenarios/infinito_colapso_total.json`;
  - implementado `scripts/sim/InfiniteModeDirector.gd` com ondas, spawn deterministico de novas chamadas, extração voluntaria e pressao crescente;
  - integrado o diretor ao `SimulationRunner.gd`;
  - adicionados overlevels por duplicata no `CardSystem.gd` e vies de duplicata/raridade tardia em `CardOfferGenerator.gd`;
  - ampliado `ScoreSystem.gd` para score por ondas e extracao;
  - `Main.gd` agora suporta extrair relatorio em runs infinitas e ofertas de carta recorrentes;
  - `SaveService.gd` passou a liberar todos os cenarios assim que o tutorial e concluido.
- Testes adicionados:
  - `tests/unit/test_infinite_mode_director.gd`
  - cobertura extra em `tests/unit/test_card_system.gd`
- Validacoes executadas:
  - `godot --headless --path . -s scripts/tools/AutoplayScenarioCli.gd -- --scenario=infinito_colapso_total --minutes=20 --seed=20260420`
  - `godot --headless --path . -s scripts/tools/AutoplayScenarioCli.gd -- --scenario=infinito_colapso_total --minutes=60 --seed=20260420 --retire-at-wave=2`
- Resultado:
  - o modo infinito ficou jogavel, sem tempo fixo, com extracao voluntaria e score por onda;
  - as runs headless chegaram as ondas e encerraram com relatorio final sem erro.

## Fase 17 - UX e acessibilidade basica

- Status: concluida nesta sessao
- Escopo:
  - `SettingsService.gd` agora persiste `pause_on_event`, `font_scale`, `colorblind_mode` e filtro de mapa;
  - `Main.gd` recebeu tooltips nos principais controles, pausa automatica configuravel em eventos, confirmacao para opcoes perigosas, busca no log, filtros de mapa, atalhos de teclado e paleta daltônica basica;
  - o log agora registra timestamp da run para ajudar o jogador a entender o que aconteceu;
  - `EndRunReport.gd` passou a exibir dados de ondas quando a run e infinita.
- Testes adicionados:
  - `tests/unit/test_settings_service.gd`
- Critico resolvido:
  - reaplicado o redirecionamento de `APPDATA` e `LOCALAPPDATA` para `./.godot/` durante as validacoes, evitando crash do Godot ao tentar criar `user://logs` fora do workspace.

## Fase 18 - Balanceamento automatizado

- Status: iniciada e avancada nesta sessao
- Escopo:
  - criada a CLI `scripts/tools/SimulateRunsCli.gd` para simular lotes de runs, gerar CSV/JSON e registrar seeds quebradas;
  - criada `docs/balance_notes.md` com baseline, ajustes aplicados e reamostragem;
  - ajustados `ScoreSystem.gd`, `campanha_01_cidade_cinza.json`, `infinito_colapso_total.json` e `InfiniteModeDirector.gd` para reduzir inflacao de score e apertar a pressao do infinito.
- Validacoes executadas:
  - `godot --headless --path . -s scripts/tools/SimulateRunsCli.gd -- --scenario=campanha_01_cidade_cinza --runs=100 --minutes=240 --seed-start=4000`
  - `godot --headless --path . -s scripts/tools/SimulateRunsCli.gd -- --scenario=infinito_colapso_total --runs=100 --minutes=60 --seed-start=5000 --retire-at-wave=2`
  - spot checks posteriores com `30` runs apos o rebalance para os dois cenarios.
- Resultado atual:
  - `Cidade Cinza` saiu de `100x S` no baseline para amostra posterior concentrada em nota `B`;
  - o infinito saiu de `100x S` com retirada na onda `2` para amostra posterior concentrada em nota `A` com retirada na onda `3`;
  - `0` seeds quebradas nas amostras executadas.

## Fase 19 - Build e distribuicao

- Status: concluida nesta sessao
- Escopo:
  - `Main.gd` ganhou versao visivel no menu e botao de creditos com dialog ligado a `docs/credits_and_licenses.md`;
  - criados `export_presets.cfg`, `tools/export_builds.sh`, `tools/make_release_zip.sh`, `tools/export_builds.ps1` e `tools/make_release_zip.ps1`;
  - criado `docs/release_checklist.md` e atualizado `README.md` para fluxo de jogador, validacao e release;
  - scripts de teste/validacao em shell passaram a redirecionar tambem `TMP` e `TEMP` para `./.godot/`;
  - os scripts de release agora falham cedo quando faltam templates ou builds reais, em vez de gerar artefatos vazios;
  - `tools/export_builds.ps1` e `tools/export_builds.sh` passaram a limpar `tmp/release` antes do export para evitar ruido de UID duplicado;
  - o pipeline de export passou a remover os arquivos `*.import` gerados em `dist/web`, deixando a distribuicao final mais enxuta.
- Validacoes executadas:
  - `godot --headless --path . --quit-after 1`
  - `godot --headless --path . -s scripts/tools/ValidateContentCli.gd -- --root=data`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/unit -gexit`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/integration -gexit`
  - `powershell -ExecutionPolicy Bypass -File tools/export_builds.ps1 -TemplateArchive .\\.godot\\downloads\\Godot_v4.6.2-stable_export_templates.tpz`
  - `powershell -ExecutionPolicy Bypass -File tools/make_release_zip.ps1`
- Resultado:
  - a versao aparece no menu e os saves continuam em `user://`, fora da pasta da build;
  - o fluxo de export/release ficou pronto em `ps1` e `sh`, com templates oficiais `4.6.2.stable` instalados localmente a partir do arquivo `.tpz`;
  - os exports `Windows Desktop`, `Linux/X11` e `Web` foram gerados com sucesso em `dist/`;
  - o zip final `release/despachante-do-apocalipse-0.1.0-dev.zip` foi gerado com binarios, `README.md` e docs de release;
  - os `.pck` finais deixaram de embutir `README`, `docs`, `scripts/tools`, `dist` e outros artefatos de desenvolvimento.

## Fase 20 - QA final da demo

- Status: concluida nesta sessao
- Escopo:
  - `AutoplayScenarioCli.gd` passou a:
    - registrar save manual quando o tutorial exige persistencia;
    - pontuar cartas e opcoes de evento por impacto operacional;
    - preferir cartas novas para validar corretamente o passo de tutorial de build;
    - reportar `Tutorial QA` com contagem de passos concluidos;
  - `data/scenarios/tutorial.json` foi rebalanceado para um objetivo final coerente com o mapa curto e com oferta de carta mais cedo;
  - `README.md` teve link quebrado removido e instrucoes de validacao/export ajustadas.
- Validacoes executadas:
  - `godot --headless --path . -s scripts/tools/ValidateContentCli.gd -- --root=data`
  - `godot --headless --path . --quit-after 1`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/unit -gexit`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/integration -gexit`
  - `godot --headless --path . -s scripts/tools/AutoplayScenarioCli.gd -- --scenario=campanha_tutorial_primeiras_rotas --minutes=40 --seed=20260420`
  - `godot --headless --path . -s scripts/tools/AutoplayScenarioCli.gd -- --scenario=campanha_01_cidade_cinza --minutes=540 --seed=20260420`
  - `godot --headless --path . -s scripts/tools/AutoplayScenarioCli.gd -- --scenario=infinito_colapso_total --minutes=20 --seed=20260420`
  - `powershell -ExecutionPolicy Bypass -File tools/export_builds.ps1`
  - `powershell -ExecutionPolicy Bypass -File tools/make_release_zip.ps1`
- Resultado:
  - tutorial agora fecha com `8/8` passos em QA automatizada;
  - `Cidade Cinza` roda ate encerramento de campanha sem crash em autoplay longo;
  - o infinito roda `20` minutos e gera relatorio com onda e score;
  - `40` testes unitarios e `5` de integracao continuam passando apos os ajustes finais;
  - a demo terminou a sessao com build exportada para Windows/Linux/Web e zip de release pronto para distribuicao.

## Fase 21 - Arquitetura de modos e desafio pos-MVP

- Status: concluida nesta sessao
- Escopo:
  - criado `GameModeDef.gd` e a categoria `data/game_modes/` para modos data-driven;
  - `ScenarioDef.gd`, `RunConfig.gd`, `ContentDb.gd` e `ContentValidator.gd` agora entendem `game_mode_id`, `allowed_card_ids` e cenario resolvido em runtime;
  - os cenarios existentes foram migrados para `campaign_standard`, `tutorial_guided` e `infinite_waves`;
  - criado o novo cenario `data/scenarios/desafio_combustivel_zero.json` com deck restrito e tuning proprio;
  - criado `docs/modding.md` documentando a estrutura minima de `game_modes`, `scenarios` e o fluxo de validacao.
- Testes adicionados:
  - `tests/unit/test_game_modes.gd`
  - ampliacao de `tests/unit/test_content_validation.gd` para referencias de `game_mode_id`
  - fixtures de validacao agora incluem `game_modes/`
- Validacoes executadas:
  - `godot --headless --path . -s scripts/tools/ValidateContentCli.gd -- --root=data`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/unit -gexit`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/integration -gexit`
  - `godot --headless --path . -s scripts/tools/AutoplayScenarioCli.gd -- --scenario=desafio_combustivel_zero --minutes=240 --seed=20260420`
  - `godot --headless --path . -s scripts/tools/AutoplayScenarioCli.gd -- --scenario=desafio_combustivel_zero --minutes=400 --seed=20260420`
  - `godot --headless --path . -s scripts/tools/SimulateRunsCli.gd -- --scenario=desafio_combustivel_zero --runs=20 --minutes=320 --seed-start=9000`
- Resultado:
  - o projeto agora tem `4` game modes validados e `5` cenarios;
  - o desafio `Combustivel Zero` fecha autoplay completa sem seed quebrada;
  - a runtime deixou de depender de excecoes espalhadas em cenarios para identificar modos futuros.

## Fase 22 - Ranking local por seed

- Status: concluida nesta sessao
- Escopo:
  - `ScoreSystem.gd` passou a registrar a `seed` no relatorio final;
  - `SaveService.gd` agora persiste `seed_leaderboards` por cenario, deduplica por seed e mantem as melhores runs locais;
  - `Main.gd` ganhou painel lateral com ranking local por seed do cenario atual;
  - `EndRunReport.gd` passou a exibir seed da run e os melhores seeds locais do cenario;
  - `README.md` foi atualizado para citar o desafio pos-MVP e o ranking local.
- Testes adicionados/expandidos:
  - `tests/unit/test_save_service.gd` agora cobre ranking local por seed;
  - `tests/unit/test_score_system.gd` agora verifica a seed no relatorio.
- Validacoes executadas:
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/unit -gexit`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/integration -gexit`
  - `godot --headless --path . --quit-after 1`
- Resultado:
  - o jogo agora registra e mostra melhores scores locais reproduziveis por seed sem qualquer servico externo;
  - a fase atual do repositorio avancou para `Fase 22`.

## Fase 23 - Desafio diario data-driven

- Status: concluida nesta sessao
- Escopo:
  - criado `scripts/core/DailyChallengeService.gd` para resolver seed fixa por data, cenario-base rotativo e mutadores diarios data-driven;
  - criado o modo `daily_ops` em `data/game_modes/core_game_modes.json`;
  - criado `data/scenarios/desafio_diario.json` com pool de cenarios base e mutadores diarios;
  - `ContentDb.gd`, `SaveService.gd`, `ScoreSystem.gd`, `Main.gd`, `AutoplayScenarioCli.gd` e `SimulateRunsCli.gd` passaram a entender contexto diario;
  - o perfil agora persiste leaderboard local por data para o desafio diario, separado do ranking normal por seed.
- Testes adicionados/expandidos:
  - `tests/unit/test_daily_challenge_service.gd`
  - `tests/unit/test_save_service.gd` agora cobre save/load e leaderboard do desafio diario
  - `tests/unit/test_content_validation.gd` passou a validar `daily_ops` e `desafio_diario`
- Validacoes executadas:
  - `godot --headless --path . -s scripts/tools/ValidateContentCli.gd -- --root=data`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/unit -gexit`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/integration -gexit`
  - `godot --headless --path . --quit-after 1`
  - `godot --headless --path . -s scripts/tools/AutoplayScenarioCli.gd -- --scenario=desafio_diario --date=2026-04-20 --minutes=360`
- Resultado:
  - o projeto passou a ter `5` game modes validados e `6` cenarios;
  - o desafio diario roda com seed e mutadores reproduziveis por data e fecha autoplay sem falha de runtime.

## Fase 24 - Localizacao basica da UI

- Status: concluida nesta sessao
- Escopo:
  - criado `LocalizationService.gd` como autoload com fallback `pt_BR -> key` e carga de catalogos JSON;
  - criados `data/localization/pt_BR.json` e `data/localization/en_US.json`;
  - `SettingsService.gd` agora persiste `locale`;
  - `Main.gd` recebeu seletor de idioma e aplicacao de localizacao nos principais textos estaticos, resumos, leaderboard e status;
  - `EndRunReport.gd` passou a respeitar o locale atual para labels do relatorio e botoes.
- Testes adicionados/expandidos:
  - `tests/unit/test_localization_service.gd`
  - `tests/unit/test_settings_service.gd` agora cobre persistencia de `locale`
- Validacoes executadas:
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/unit -gexit`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/integration -gexit`
  - `godot --headless --path . --quit-after 1`
- Resultado:
  - a demo agora alterna entre `pt_BR` e `en_US` na UI principal e no relatorio final sem afetar o core deterministico;
  - a fase atual do repositorio avancou para `Fase 24`.

## Fase 25 - Rework visual da operacao

- Status: concluida nesta sessao
- Escopo:
  - a cena principal em `scenes/main/Main.gd` foi reorganizada para sair do layout de painel de debug e ganhar hierarquia visual real, com cabecalho de situacao, barra de comando agrupada e coluna lateral em secoes;
  - criado `scripts/ui/OperationsMapView.gd`, um canvas dedicado para o teatro operacional, desenhando estradas, halos de risco, placas de distrito, rotas destacadas, onibus com silhueta propria e legenda embutida;
  - o mapa deixou de depender de `Button` e `ColorRect` soltos, passando a usar hitboxes customizadas com padding interno, o que eliminou o corte do abrigo no Web e melhorou a leitura espacial;
  - `Main.gd` passou a exibir nomes humanos em selecao, frota e ordens, com preview de rota sugerida, estados de onibus localizados e detalhe melhor do distrito focado;
  - os botoes dinamicos de cartas e eventos tambem receberam estilo consistente com o restante da HUD.
- Ajustes de UX entregues:
  - filtros do mapa agora destacam em vez de simplesmente sumir com a cidade;
  - placas de distrito ganharam reposicionamento para evitar sobreposicao nos mapas menores;
  - o tutorial e a navegacao no Web ficaram mais legiveis em `1600x980`, com mapa central finalmente dominante na tela.
- Arquivos principais:
  - `scenes/main/Main.gd`
  - `scripts/ui/OperationsMapView.gd`
  - `data/localization/pt_BR.json`
  - `data/localization/en_US.json`
  - `scripts/autoload/App.gd`
- Validacoes executadas:
  - `godot --headless --path . --quit-after 1`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/unit -gexit`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -- -gdir=tests/integration -gexit`
  - `godot --headless --path . -s scripts/tools/ValidateContentCli.gd -- --root=data`
  - `powershell -ExecutionPolicy Bypass -File tools/export_builds.ps1 -TemplateArchive .\\.godot\\downloads\\Godot_v4.6.2-stable_export_templates.tpz`
  - validacao manual via Playwright em `http://localhost:8000/`
- Resultado:
  - a apresentacao da run saiu do estado de placeholder tecnico e passou a comunicar um mapa operacional de verdade;
  - a build Web continuou carregando sem erros de console e o clique em distritos foi revalidado apos o redesign;
  - a fase atual do repositorio avancou para `Fase 25`.
