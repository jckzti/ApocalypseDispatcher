# Despachante do Apocalipse — Plano Mestre de Desenvolvimento

> Documento para ficar na raiz do repositório como `PROJECT_PLAN.md` ou `DESPACHANTE_DO_APOCALIPSE_PLANO_MESTRE.md`.  
> Objetivo: permitir que você e o Codex CLI construam o jogo em partes pequenas, testáveis e expansíveis, até chegar em uma versão completa, distribuível e preparada para novos modos.

---

## 0. Resumo executivo

**Despachante do Apocalipse** é um jogo de estratégia/logística em tempo real com pausa, visão superior simples, estética pixel/low-bit e progressão roguelite por cartas. O jogador não controla um herói. Ele controla uma central de evacuação de uma cidade em colapso: ônibus, rotas, motoristas, combustível, abrigos, bloqueios, boatos, saques, prioridades civis, eventos políticos e decisões moralmente desconfortáveis.

O jogo deve funcionar como uma simulação sistêmica, orientada por dados, com interface simples e alta rejogabilidade. Cada partida gera uma história diferente por causa de mapas, eventos, cartas, sinergias, prioridades e colapso urbano progressivo.

**Stack recomendada:** Godot 4.x + GDScript tipado + dados em JSON + testes com GUT.  
**Motivo:** projeto muito bom para Codex CLI porque grande parte do trabalho é texto: scripts, cenas simples, dados, testes, balanceamento e documentação. A UI pode começar como grafos/retângulos/ícones simples antes de receber arte final.

---

## 1. Decisões fixas do projeto

Estas decisões são âncoras. O Codex deve tratá-las como requisitos, não sugestões.

### 1.1 Engine e linguagem

- Usar **Godot 4.x**.
- Usar **GDScript tipado** como linguagem principal.
- Evitar C# no MVP para reduzir setup e fricção.
- Evitar plugins pesados no MVP.
- Usar cenas Godot apenas onde fizer sentido visualmente; manter a simulação em scripts puros, testáveis.

### 1.2 Forma do jogo

- Visão superior.
- Tempo real com pausa e controle de velocidade.
- População agregada por distrito e coorte, não civis individuais reais no core da simulação.
- Ônibus, comboios e alguns eventos podem ter representação visual como agentes.
- O mapa inicial pode ser grafo urbano com nós e arestas, não precisa ser tilemap completo no começo.
- O jogo deve ser jogável mesmo com arte placeholder.

### 1.3 Rejogabilidade

- Toda run tem seed.
- Eventos, cartas e mapas devem ser dirigidos por dados.
- O jogo deve suportar modo campanha, desafios e modo infinito.
- Deve haver progressão dentro da run e meta-progressão leve entre runs.
- Cartas devem criar builds e sinergias reais, não apenas bônus numéricos isolados.

### 1.4 Ética de design

- No MVP, “Ouro”, “Verba”, “Créditos” ou qualquer recurso de reroll é **moeda interna do jogo**, não dinheiro real.
- Não implementar microtransações no MVP.
- O loop pode ser viciante no sentido de ser satisfatório, profundo e rejogável, mas deve evitar dark patterns agressivos.
- Caso monetização real seja considerada no futuro, ela deve ser transparente, opcional e não pay-to-win.

### 1.5 Requisito técnico central

A simulação deve ser separada da interface.

Isto é obrigatório porque:

- permite testes automatizados;
- facilita balanceamento;
- facilita novos modos;
- permite simular milhares de runs sem renderizar UI;
- reduz bugs gerados por estado espalhado em cenas.

---

## 2. Visão de produto

### 2.1 Fantasia do jogador

Você é a mesa de crise de uma cidade prestes a cair. Você enxerga o mapa, escuta rádio, recebe relatórios ruins, decide rotas e tenta salvar o máximo possível sem deixar a cidade mergulhar no caos total.

Você não é o salvador heroico. Você é o despachante cansado que decide quem recebe o último ônibus.

### 2.2 Promessa principal

> “Cada partida é uma crise logística diferente, onde cartas, eventos e colapso urbano criam builds emergentes e dilemas de evacuação.”

### 2.3 Pilares de design

1. **Logística sob pressão**  
   O jogador deve sempre ter mais problemas do que recursos.

2. **Decisões moralmente tensas**  
   Salvar hospital agora pode sacrificar bairros periféricos. Controlar fake news pode reduzir pânico, mas destruir confiança.

3. **Builds de crise**  
   O jogador pode criar estilos: comboios blindados, rede de rádio, corredores humanitários, evacuação médica, controle autoritário, mercado negro, engenheiros de rota, etc.

4. **Simulação legível**  
   O jogo pode ser profundo, mas cada consequência precisa ser comunicada de forma clara.

5. **Dados acima de hardcode**  
   Cartas, eventos, mapas, cenários e modificadores devem ser adicionáveis sem mexer no core.

6. **Partidas que viram histórias**  
   O relatório final deve parecer uma crônica: “salvamos 38 mil, perdemos a zona leste quando a ponte caiu, e a decisão de armar comboios custou a confiança pública.”

---

## 3. Escopo de versão

### 3.1 Protótipo jogável vertical slice

Objetivo: provar o loop principal em 20–30 minutos de partida.

Inclui:

- mapa com 8 a 12 distritos;
- 3 a 5 abrigos/saídas;
- 6 a 10 ônibus;
- combustível;
- população por coorte;
- perigo/collapse por distrito;
- rotas;
- eventos;
- cartas de recompensa;
- reroll com moeda interna;
- UI simples;
- relatório final;
- testes do core.

### 3.2 MVP completo distribuível

Objetivo: um jogo pequeno, mas completo, publicável em itch.io/Steam demo.

Inclui:

- 3 cenários base;
- 1 modo infinito;
- 80+ cartas;
- 60+ eventos;
- 4 arquétipos de build fortes;
- save/load;
- settings;
- tutorial inicial;
- export Windows/Linux/Web;
- balanceamento básico;
- tela final rica;
- documentação de modding simples.

### 3.3 Pós-MVP

Possibilidades:

- campanha com cidades diferentes;
- editor de cenários;
- facções persistentes;
- clima e estações;
- evacuação por trem/barco/helicóptero;
- mod support;
- leaderboard local por seed;
- histórias proceduralmente geradas;
- integração com Steam achievements;
- localização EN/ES.

---

## 4. Como usar este documento com Codex CLI

### 4.1 Regra de trabalho

O Codex deve executar **uma fase ou uma tarefa pequena por vez**. Não pedir para ele “fazer o jogo inteiro” em um único prompt.

Fluxo recomendado:

1. Abrir issue ou branch pequena.
2. Mandar Codex ler este documento.
3. Mandar implementar apenas a próxima fase.
4. Exigir testes ou smoke test.
5. Revisar diff.
6. Commitar.
7. Repetir.

### 4.2 Prompt-base para o Codex

Usar este prompt no início de sessões grandes:

```text
Leia DESPACHANTE_DO_APOCALIPSE_PLANO_MESTRE.md inteiro antes de alterar arquivos.
Você está trabalhando em um jogo Godot 4 chamado Despachante do Apocalipse.
Implemente somente a fase/tarefa solicitada.
Não reescreva arquitetura sem necessidade.
Mantenha simulação separada da UI.
Use GDScript tipado.
Crie ou atualize testes quando a tarefa tocar regras de simulação.
Ao final, liste arquivos alterados, comandos executados e próximos passos.
```

### 4.3 Prompt para revisão local

```text
Revise este repositório como code reviewer.
Procure bugs de simulação, estado global acidental, acoplamento UI/core, dados hardcoded, ausência de testes e problemas de performance.
Não faça alterações ainda; primeiro produza uma lista priorizada de achados.
```

### 4.4 Prompt para cada fase

```text
Leia a seção "Fase X" do plano.
Implemente apenas o escopo da Fase X.
Respeite os critérios de aceite.
Se encontrar inconsistência, faça a menor decisão segura e documente no final.
Rode os testes/comandos possíveis.
```

### 4.5 Convenções de branch

- `feat/phase-00-bootstrap`
- `feat/phase-01-sim-core`
- `feat/phase-02-city-graph`
- `feat/phase-03-fleet-routing`
- `feat/phase-04-events`
- `feat/phase-05-cards`
- `feat/phase-06-ui-loop`
- `feat/phase-07-save-meta`
- `feat/phase-08-balance-content`
- `release/mvp-demo`

---

## 5. Estrutura recomendada do repositório

A raiz do repositório também será a raiz do projeto Godot.

```text
despachante-do-apocalipse/
├── project.godot
├── README.md
├── AGENTS.md
├── DESPACHANTE_DO_APOCALIPSE_PLANO_MESTRE.md
├── CHANGELOG.md
├── LICENSE
├── .gitignore
├── export_presets.cfg
├── addons/
│   └── gut/
├── assets/
│   ├── fonts/
│   ├── icons/
│   ├── sfx/
│   ├── music/
│   └── sprites/
├── data/
│   ├── cards/
│   │   ├── logistics.json
│   │   ├── communications.json
│   │   ├── security.json
│   │   ├── medical.json
│   │   ├── civic.json
│   │   ├── engineering.json
│   │   ├── black_market.json
│   │   └── anomalies.json
│   ├── events/
│   │   ├── collapse_events.json
│   │   ├── social_events.json
│   │   ├── route_events.json
│   │   ├── faction_events.json
│   │   └── moral_events.json
│   ├── maps/
│   │   ├── cidade_cinza.json
│   │   ├── porto_santo_amaro.json
│   │   └── vale_das_sirenas.json
│   ├── scenarios/
│   │   ├── tutorial.json
│   │   ├── campanha_01_cidade_cinza.json
│   │   ├── desafio_combustivel_zero.json
│   │   └── infinito_colapso_total.json
│   └── localization/
│       ├── pt_BR.json
│       └── en_US.json
├── docs/
│   ├── design_bible.md
│   ├── content_authoring.md
│   ├── balance_notes.md
│   ├── release_checklist.md
│   └── modding.md
├── scenes/
│   ├── main/
│   │   ├── Main.tscn
│   │   └── Main.gd
│   ├── ui/
│   │   ├── MainMenu.tscn
│   │   ├── RunHud.tscn
│   │   ├── DistrictPanel.tscn
│   │   ├── RoutePanel.tscn
│   │   ├── CardChoiceModal.tscn
│   │   ├── EventModal.tscn
│   │   ├── EndRunReport.tscn
│   │   └── Tooltip.tscn
│   ├── map/
│   │   ├── MapView.tscn
│   │   ├── DistrictNodeView.tscn
│   │   ├── RoadEdgeView.tscn
│   │   └── BusTokenView.tscn
│   └── debug/
│       └── DebugOverlay.tscn
├── scripts/
│   ├── autoload/
│   │   ├── App.gd
│   │   ├── ContentDb.gd
│   │   ├── SaveService.gd
│   │   └── SettingsService.gd
│   ├── core/
│   │   ├── DeterministicRng.gd
│   │   ├── GameConstants.gd
│   │   ├── GameEnums.gd
│   │   ├── GameSignals.gd
│   │   ├── GameState.gd
│   │   ├── RunConfig.gd
│   │   └── Versioning.gd
│   ├── data/
│   │   ├── CardDef.gd
│   │   ├── EventDef.gd
│   │   ├── ScenarioDef.gd
│   │   ├── MapDef.gd
│   │   ├── DistrictDef.gd
│   │   ├── RoadDef.gd
│   │   └── ContentValidator.gd
│   ├── sim/
│   │   ├── SimulationRunner.gd
│   │   ├── SimulationClock.gd
│   │   ├── CityGraph.gd
│   │   ├── DistrictState.gd
│   │   ├── RoadState.gd
│   │   ├── ShelterState.gd
│   │   ├── PopulationModel.gd
│   │   ├── FleetManager.gd
│   │   ├── BusUnit.gd
│   │   ├── RoutePlanner.gd
│   │   ├── EvacuationOrder.gd
│   │   ├── EvacuationResolver.gd
│   │   ├── CollapseDirector.gd
│   │   ├── EventDirector.gd
│   │   ├── CardSystem.gd
│   │   ├── CardOfferGenerator.gd
│   │   ├── ModifierStack.gd
│   │   ├── EconomySystem.gd
│   │   ├── ScoreSystem.gd
│   │   └── UnlockSystem.gd
│   ├── ui/
│   │   ├── HudController.gd
│   │   ├── MapViewController.gd
│   │   ├── DistrictPanelController.gd
│   │   ├── RoutePanelController.gd
│   │   ├── CardChoiceController.gd
│   │   ├── EventModalController.gd
│   │   ├── EndRunReportController.gd
│   │   └── TooltipController.gd
│   └── tools/
│       ├── ValidateContentCli.gd
│       ├── SimulateRunsCli.gd
│       └── ExportRunReportCli.gd
├── tests/
│   ├── unit/
│   │   ├── test_rng.gd
│   │   ├── test_city_graph.gd
│   │   ├── test_route_planner.gd
│   │   ├── test_population_model.gd
│   │   ├── test_fleet_manager.gd
│   │   ├── test_collapse_director.gd
│   │   ├── test_card_offer_generator.gd
│   │   ├── test_event_director.gd
│   │   └── test_save_migration.gd
│   ├── integration/
│   │   ├── test_tutorial_run_10_minutes.gd
│   │   ├── test_seed_reproducibility.gd
│   │   └── test_end_run_report.gd
│   └── fixtures/
│       ├── tiny_map.json
│       ├── tiny_cards.json
│       └── tiny_events.json
└── tools/
    ├── run_tests.sh
    ├── validate_content.sh
    ├── simulate_balance.sh
    ├── export_builds.sh
    └── make_release_zip.sh
```

---

## 6. Arquivo AGENTS.md recomendado

Criar `AGENTS.md` na raiz com este conteúdo adaptado:

```md
# Instruções para agentes

- Leia `DESPACHANTE_DO_APOCALIPSE_PLANO_MESTRE.md` antes de implementar funcionalidades.
- Este é um projeto Godot 4.x com GDScript tipado.
- Separe simulação de UI. Não coloque regras de gameplay em controllers visuais.
- Conteúdo deve vir de `data/*.json` sempre que possível.
- Toda regra de simulação nova precisa de teste unitário ou integração.
- Não introduza assets com licença desconhecida.
- Não implemente microtransações.
- Não altere o escopo de uma fase sem registrar no resumo final.
- Ao final de cada alteração, reporte:
  - arquivos alterados;
  - testes/comandos executados;
  - riscos remanescentes;
  - próxima tarefa recomendada.
```

---

## 7. Loop principal do jogo

### 7.1 Loop macro de uma run

1. Escolher cenário ou seed.
2. Receber briefing: cidade, ameaça, recursos iniciais, objetivos.
3. Começar simulação pausada.
4. Inspecionar mapa.
5. Criar ou ajustar rotas.
6. Definir prioridades civis.
7. Alocar ônibus, motoristas e combustível.
8. Iniciar tempo.
9. Eventos disparam.
10. Reagir reconfigurando logística.
11. Ao completar marcos, escolher cartas.
12. A cidade colapsa progressivamente.
13. A run termina por vitória, extração, colapso total ou desistência.
14. Exibir relatório final e desbloqueios.

### 7.2 Loop de 30 segundos

O jogador deve estar quase sempre alternando entre:

- ler alerta;
- pausar;
- clicar no distrito;
- ver população/risco;
- ajustar rota;
- gastar verba;
- escolher carta/evento;
- acelerar o tempo;
- ver consequências.

### 7.3 Loop de recompensa

- A cada objetivo parcial, evacuação relevante ou crise resolvida, o jogador ganha:
  - carta;
  - verba;
  - reputação;
  - desbloqueio temporário;
  - intel;
  - upgrade de frota.

- A tela de cartas oferece 3 opções inicialmente.
- Reroll custa verba/ouro interno.
- O custo de reroll aumenta dentro da mesma escolha.
- A raridade das cartas aumenta com o nível de crise.
- Cartas com tags semelhantes às escolhas anteriores têm peso maior, para permitir builds sem remover variedade.

---

## 8. Recursos e métricas

### 8.1 Recursos globais

| Recurso | Descrição | Uso principal |
|---|---|---|
| Verba | Moeda interna de operação | Reroll, compras emergenciais, reparos |
| Combustível | Diesel disponível | Mover ônibus e comboios |
| Ordem Pública | Controle social/segurança | Reduz saques, bloqueios e pânico |
| Confiança | Crença da população na central | Melhora adesão às evacuações |
| Comunicação | Capacidade de transmitir instruções | Reduz fake news, aumenta velocidade de resposta |
| Inteligência | Qualidade dos dados de campo | Revela bloqueios/eventos antes |
| Suprimentos Médicos | Recursos para coortes vulneráveis | Reduz mortes de pacientes/idosos |
| Peças | Manutenção da frota | Reparo de ônibus e desbloqueios mecânicos |
| Autoridade | Poder institucional acumulado | Permite medidas duras, mas gera dívida moral/política |

### 8.2 Métricas derivadas

| Métrica | Como muda | Efeito |
|---|---|---|
| Pânico | Sobe com perigo, fake news, mortes | Diminui embarque, aumenta tumultos |
| Desinformação | Sobe com eventos e baixa comunicação | Cria rotas falsas, aglomerações |
| Saques | Sobe com baixa ordem e escassez | Bloqueia estradas, consome recursos |
| Fadiga dos motoristas | Sobe por uso contínuo | Aumenta acidentes e lentidão |
| Dano da frota | Sobe em rotas perigosas | Reduz capacidade e velocidade |
| Pressão política | Sobe por mortes e decisões duras | Dispara eventos negativos |
| Dívida moral | Sobe por escolhas autoritárias/cruéis | Penaliza relatório e desbloqueia eventos sombrios |

### 8.3 Coortes populacionais

Cada distrito possui população agregada nestas categorias:

| Coorte | Peso de score | Vulnerabilidade | Observação |
|---|---:|---:|---|
| Adultos | 1.0 | 1.0 | Base da população |
| Crianças | 1.8 | 1.4 | Alta pressão moral |
| Idosos | 1.6 | 1.6 | Embarque mais lento |
| Pacientes | 2.2 | 2.0 | Exigem ônibus adaptado ou suprimento médico |
| Equipes essenciais | 1.4 | 1.0 | Podem melhorar serviços se resgatadas |
| Motoristas voluntários | 1.2 | 1.0 | Podem virar recurso |
| Alta influência | 0.8 | 1.0 | Salvá-los reduz pressão política, mas pode afetar confiança |

Regra: o jogador pode priorizar coortes, mas priorizar demais grupos privilegiados deve afetar confiança pública.

---

## 9. Modelo de cidade

### 9.1 Representação inicial

Usar grafo:

- `DistrictState` = nó.
- `RoadState` = aresta.
- `ShelterState` = distrito ou entidade conectada ao grafo.
- Ônibus se movem por caminhos calculados em cima das arestas.

Isto permite gameplay profundo sem precisar de pathfinding tile-based no MVP.

### 9.2 Distrito

Atributos principais:

```text
id
nome
posição visual x/y
população por coorte
pânico 0..100
confiança local 0..100
perigo 0..100
colapso 0..100
saque 0..100
desinformação 0..100
capacidade de embarque por minuto
infraestrutura 0..100
abrigo? true/false
capacidade de abrigo
tags: centro, periferia, industrial, hospitalar, porto, universidade, favela, terminal, etc.
flags temporárias
```

### 9.3 Estrada

Atributos principais:

```text
id
from_district_id
to_district_id
comprimento_km
capacidade_tráfego 0..100
bloqueio 0..100
perigo 0..100
qualidade 0..100
visibilidade 0..100
one_way? true/false
tags: ponte, túnel, avenida, estrada, beira-rio, trilho_futuro
flags temporárias
```

### 9.4 Ameaça e colapso

Cada distrito tem `danger` e `collapse`.

- `danger` representa perigo imediato.
- `collapse` representa perda estrutural acumulada.
- Distrito colapsado não pode embarcar normalmente.
- Estradas conectadas a distritos colapsados ficam mais perigosas ou bloqueadas.
- Colapso se propaga por vizinhança, eventos e tempo.

Fórmula inicial sugerida por minuto:

```text
danger_delta = base_threat_rate
             + neighbor_collapsed_count * 0.15
             + scenario_pressure
             + event_modifiers
             - mitigation_modifiers

collapse_delta = max(0, danger - 65) * 0.015
               + direct_event_damage
               - engineering_mitigation
```

O Codex deve implementar primeiro uma fórmula simples e ajustável, não tentar simulação física complexa.

---

## 10. Frota e rotas

### 10.1 Ônibus

Atributos:

```text
id
nome/código
capacidade_base
capacidade_atual
combustível_atual
combustível_max
consumo_por_km
velocidade_base_kmh
estado: idle, to_pickup, loading, to_dropoff, unloading, returning, repairing, disabled
posição: district_id ou road progress
dano 0..100
fadiga_motorista 0..100
tags: articulado, escolar, adaptado, blindado, elétrico_futuro
modificadores ativos
```

### 10.2 Ordem de evacuação

O jogador não microcontrola cada passageiro; cria ordens:

```text
id
pickup_district_id
dropoff_shelter_id
priority_policy
assigned_bus_ids
active true/false
repeat true/false
min_load_percent
avoid_high_danger true/false
allow_dangerous_roads true/false
created_at_minute
```

### 10.3 Prioridades de embarque

Políticas iniciais:

- `balanced`: proporcional.
- `children_first`: crianças e idosos primeiro.
- `medical_first`: pacientes primeiro.
- `essential_staff_first`: equipes essenciais primeiro.
- `fastest_boarding`: adultos primeiro para maximizar volume.
- `political_pressure`: alta influência primeiro, com penalidade de confiança.

### 10.4 Cálculo de rota

Usar Dijkstra no MVP.

Custo da aresta:

```text
cost = length_km
     * traffic_multiplier
     * danger_multiplier
     * blockade_multiplier
     * road_quality_multiplier
     * card_modifiers
```

Se `avoid_high_danger = true`, arestas acima de um limite recebem custo altíssimo.

### 10.5 Embarque/desembarque

Taxa de embarque sugerida:

```text
boarding_rate = district_boarding_base
              * bus_boarding_modifier
              * panic_modifier
              * communication_modifier
              * priority_policy_modifier
              * weather_or_event_modifier
```

Pânico alto reduz embarque. Comunicação e confiança aumentam embarque.

---

## 11. Sistema de eventos

### 11.1 Tipos de evento

1. **Eventos de colapso**  
   Incêndio, enchente, ponte rompendo, queda de energia, nuvem tóxica, contaminação, apagão.

2. **Eventos sociais**  
   Fake news, protesto, saque, boato de último ônibus, pânico em abrigo.

3. **Eventos de rota**  
   Bloqueio, acidente, pedágio ilegal, comboio preso, estrada liberada por voluntários.

4. **Eventos de facção**  
   Sindicato de motoristas, polícia, rádio amador, hospital, prefeitura, milícia, imprensa.

5. **Eventos morais**  
   Quem evacuar primeiro? Mentir para reduzir pânico? Abandonar zona condenada? Usar força?

### 11.2 Estrutura de evento

Cada evento tem:

- gatilhos;
- texto;
- opções;
- consequências imediatas;
- consequências atrasadas;
- flags;
- peso de repetição;
- tags.

### 11.3 Exemplo de JSON de evento

```json
{
  "id": "event_fake_news_last_bus",
  "title": "Boato do Último Ônibus",
  "body": "Mensagens virais dizem que apenas um comboio sairá da Zona Norte. Milhares estão indo para o terminal errado.",
  "category": "social",
  "tags": ["fake_news", "panic", "communications"],
  "min_crisis_level": 1,
  "weight": 12,
  "cooldown_minutes": 30,
  "trigger": {
    "min_global_disinformation": 35,
    "min_population_remaining": 5000
  },
  "options": [
    {
      "id": "broadcast_correction",
      "label": "Transmitir correção em todos os canais",
      "requirements": { "communication": 8 },
      "effects": {
        "global_disinformation_add": -18,
        "trust_add": 4,
        "budget_add": -2
      }
    },
    {
      "id": "use_decoy_bus",
      "label": "Enviar ônibus-isca para dispersar a multidão",
      "effects": {
        "panic_add": -10,
        "trust_add": -6,
        "bus_damage_random_add": 8,
        "moral_debt_add": 2
      }
    },
    {
      "id": "ignore",
      "label": "Ignorar e manter o plano",
      "effects": {
        "target_district_panic_add": 16,
        "target_district_boarding_modifier_minutes": -0.25
      }
    }
  ]
}
```

---

## 12. Sistema de cartas

### 12.1 Objetivo das cartas

Cartas são o principal motor de builds e replay. Elas devem:

- modificar regras;
- criar novas opções;
- reforçar arquétipos;
- permitir combos;
- resolver crises com custo;
- mudar a forma como o jogador pensa rotas.

### 12.2 Classes de cartas

| Classe | Fantasia | Mecânica |
|---|---|---|
| Logística | frota, combustível, turnos | capacidade, consumo, velocidade |
| Engenharia | pontes, barricadas, oficinas | desbloqueio, reparo, mitigação |
| Comunicação | rádio, sirenes, informação | pânico, fake news, confiança |
| Segurança | escolta, ordem, bloqueios | saques, perigo, autoridade |
| Médica | triagem, ambulâncias, hospitais | coortes vulneráveis, mortes |
| Cívica | voluntários, bairros, abrigos | confiança, embarque, abrigo |
| Mercado Negro | diesel paralelo, favores | poder alto com custo moral |
| Anomalia | efeitos raros do apocalipse | regras estranhas, alto risco |

### 12.3 Raridades

| Raridade | Peso inicial | Papel |
|---|---:|---|
| Comum | Alto | Bônus simples e fundação de build |
| Incomum | Médio | Modificadores com condição |
| Rara | Baixo | Mecânicas novas e sinergias fortes |
| Épica | Muito baixo | Virada de estratégia |
| Lendária | Raríssima | Define build/run |
| Anômala | Especial | Altera regras com alto risco |

### 12.4 Tags de sinergia

Exemplos:

```text
diesel, convoy, radio, siren, trust, authority, hospital, children,
night_ops, engineer, bridge, shelter, volunteer, black_market,
intelligence, drone, barricade, panic, media, route, repair,
high_risk, moral_debt, anomaly
```

### 12.5 Sinergias por limiar

Cada tag acumulada pode ativar bônus:

| Tag | 3 cartas | 6 cartas | 9 cartas |
|---|---|---|---|
| radio | -10% desinformação | eventos de fake news avisam antes | pode cancelar 1 fake news por dia |
| diesel | -8% consumo | compra emergencial mais barata | rotas longas geram verba |
| convoy | +10% velocidade em comboio | escolta reduz dano | comboios ignoram 1 bloqueio leve |
| hospital | pacientes embarcam +25% | morte médica -20% | hospitais viram mini-abrigos |
| authority | saques -15% | desbloqueia toque de recolher | risco de revolta severa |
| volunteer | embarque +10% | reparos gratuitos ocasionais | distritos confiantes autoevacuam |
| black_market | compra diesel alternativa | eventos ilegais rendem recursos | dívida moral explode no fim |

### 12.6 Geração de ofertas

Pseudoalgoritmo:

```text
input: crisis_level, elapsed_minutes, owned_cards, unlocked_cards, rng

1. Filtrar cartas disponíveis por:
   - desbloqueada;
   - min_crisis_level;
   - cenário compatível;
   - não banida por flags;
   - não exclusiva conflitante.

2. Calcular peso de raridade:
   - começo: comum dominante;
   - meio: incomum/rara crescem;
   - tarde: épica/lendária aparecem;
   - pity: após muitas ofertas sem rara+, aumentar chance.

3. Aplicar peso de sinergia:
   - tags já presentes aumentam chance moderadamente;
   - tags ausentes não desaparecem;
   - evitar oferecer 3 cartas quase idênticas.

4. Sortear 3 cartas distintas.

5. Se jogador rerollar:
   - gastar verba;
   - aumentar custo;
   - evitar repetir exatamente a mesma oferta.
```

### 12.7 Progressão de cartas

- Carta nova adiciona efeito nível 1.
- Carta duplicada pode:
  - virar upgrade da carta;
  - ou dar escolha entre upgrade e verba.
- Níveis sugeridos: I, II, III.
- Algumas cartas raras são únicas e não upam.

### 12.8 Exemplo de JSON de carta

```json
{
  "id": "card_radio_ham_network",
  "name": "Rede de Rádio Amador",
  "class": "communications",
  "rarity": "uncommon",
  "tags": ["radio", "trust", "fake_news"],
  "min_crisis_level": 1,
  "max_level": 3,
  "description": "Reduz desinformação global e melhora embarque em distritos com confiança alta.",
  "effects_by_level": [
    {
      "global_disinformation_rate_mult": 0.92,
      "boarding_rate_if_trust_above_60_add": 0.05
    },
    {
      "global_disinformation_rate_mult": 0.86,
      "boarding_rate_if_trust_above_60_add": 0.09
    },
    {
      "global_disinformation_rate_mult": 0.78,
      "boarding_rate_if_trust_above_60_add": 0.14,
      "reveal_social_events_minutes_early": 5
    }
  ],
  "exclusive_group": null,
  "flavor": "Quando a internet cai, o chiado vira infraestrutura crítica."
}
```

---

## 13. Builds desejadas

### 13.1 Build “Comboio de Aço”

Foco: segurança, comboios, autoridade.

Vantagens:

- atravessa rotas perigosas;
- reduz saques;
- protege ônibus;
- excelente em zonas colapsando.

Custos:

- confiança menor;
- maior pressão política;
- eventos de abuso/revolta;
- alto consumo.

Cartas-chave:

- Escolta Armada;
- Comboio Blindado;
- Toque de Recolher;
- Corredor de Força;
- Depósito Militar.

### 13.2 Build “Cidade no Rádio”

Foco: comunicação, confiança, fake news.

Vantagens:

- reduz pânico;
- embarque mais rápido;
- eventos avisam antes;
- melhor controle de massa.

Custos:

- fraco contra bloqueios físicos;
- depende de energia/infra;
- eventos de mídia hostil.

Cartas-chave:

- Rede de Rádio Amador;
- Sirenes de Bairro;
- Porta-voz Confiável;
- Mapa Público Atualizado;
- Central Antiboato.

### 13.3 Build “Diesel até o Inferno”

Foco: combustível, rotas longas, eficiência.

Vantagens:

- move mais ônibus;
- mantém evacuação constante;
- cria economia forte.

Custos:

- vulnerável a saques no combustível;
- risco de mercado negro;
- explosões/acidentes.

Cartas-chave:

- Racionamento Inteligente;
- Tanques Auxiliares;
- Diesel de Garagem;
- Contrato com Caminhoneiros;
- Refinaria Improvisada.

### 13.4 Build “Triagem Sagrada”

Foco: hospitais, pacientes, idosos, crianças.

Vantagens:

- pontuação alta;
- baixa dívida moral;
- eventos cívicos positivos.

Custos:

- embarque mais lento;
- rotas médicas exigentes;
- adultos ficam para trás.

Cartas-chave:

- Ônibus Adaptados;
- Equipes de Triagem;
- Abrigo Clínico;
- Prioridade Pediátrica;
- Corredor Hospitalar.

### 13.5 Build “Mutirão Popular”

Foco: voluntários, confiança, abrigos locais.

Vantagens:

- autoevacuação;
- reparos baratos;
- embarque estável;
- resiliência social.

Custos:

- menos controle direto;
- vulnerável a fake news;
- pode gerar eventos de multidão.

Cartas-chave:

- Comitês de Bairro;
- Voluntários no Terminal;
- Cozinhas Comunitárias;
- Oficinas Populares;
- Abrigos de Escola.

### 13.6 Build “Mercado Negro”

Foco: recursos rápidos, alto risco.

Vantagens:

- resolve escassez;
- compra diesel, peças e bloqueios;
- funciona quando instituições falham.

Custos:

- dívida moral;
- eventos criminosos;
- perda de confiança;
- possível final ruim.

Cartas-chave:

- Diesel Sem Nota;
- Pedágio Negociado;
- Favores na Madrugada;
- Contrabandistas de Peças;
- O Dono da Ponte.

---

## 14. Conteúdo inicial de cartas

O MVP deve implementar pelo menos 80 cartas, mas o vertical slice pode começar com estas 40. O Codex deve colocá-las em JSON por classe.

| ID | Nome | Classe | Raridade | Tags | Efeito resumido |
|---|---|---|---|---|---|
| card_extra_driver_shift | Turno Extra de Motoristas | logística | comum | convoy | +velocidade, +fadiga |
| card_fuel_rationing | Racionamento Inteligente | logística | comum | diesel | -consumo por km |
| card_auxiliary_tanks | Tanques Auxiliares | logística | incomum | diesel | +combustível máximo dos ônibus |
| card_express_boarding | Embarque em Fila Dupla | logística | comum | route | +embarque, +pânico se confiança baixa |
| card_articulated_buses | Ônibus Articulados | logística | rara | convoy | +capacidade, -velocidade em ruas ruins |
| card_night_routes | Rotas Noturnas | logística | incomum | night_ops | menos tráfego, mais risco |
| card_dispatch_algorithm | Algoritmo de Despacho | logística | épica | intelligence, route | sugere melhor rota e reduz ociosidade |
| card_last_depot | Última Garagem | logística | lendária | diesel, repair | recupera ônibus desativados uma vez |
| card_radio_ham_network | Rede de Rádio Amador | comunicação | incomum | radio, trust | -desinformação, +embarque com confiança |
| card_public_map | Mapa Público Atualizado | comunicação | comum | radio, route | -pânico em distritos informados |
| card_trusted_spokesperson | Porta-voz Confiável | comunicação | rara | trust, media | eventos sociais têm opção extra |
| card_sirens | Sirenes de Bairro | comunicação | comum | siren | alerta distritos antes do perigo |
| card_anti_rumor_cell | Central Antiboato | comunicação | épica | fake_news, radio | cancela fake news periódica |
| card_local_megaphones | Carros de Som | comunicação | comum | trust | +embarque em bairros periféricos |
| card_backup_power | Geradores para Torres | comunicação | rara | radio, engineer | comunicação resiste a apagões |
| card_open_frequency | Frequência Aberta | comunicação | incomum | radio, volunteer | +intel, risco de boatos |
| card_armed_escort | Escolta Armada | segurança | incomum | authority, convoy | -dano de rota, -confiança |
| card_curfew | Toque de Recolher | segurança | rara | authority | -saques, +pressão política |
| card_checkpoint_grid | Rede de Barreiras | segurança | comum | barricade | bloqueia saques, atrasa ônibus |
| card_crowd_control | Controle de Multidão | segurança | comum | authority, panic | -pânico imediato, +dívida moral |
| card_armored_convoy | Comboio Blindado | segurança | épica | convoy, authority | ignora bloqueio leve |
| card_negotiators | Negociadores de Rua | segurança | incomum | trust | reduz saques sem autoridade |
| card_military_depot | Depósito Militar | segurança | lendária | authority, repair | peças e escolta, eventos severos |
| card_quiet_route | Operação Silêncio | segurança | rara | night_ops | rota invisível, risco se descoberta |
| card_triage_teams | Equipes de Triagem | médica | comum | hospital | pacientes embarcam melhor |
| card_adapted_buses | Ônibus Adaptados | médica | incomum | hospital, convoy | pacientes ocupam menos capacidade |
| card_mobile_clinic | Clínica Móvel | médica | rara | hospital | reduz mortes em distrito alvo |
| card_pediatric_priority | Prioridade Pediátrica | médica | comum | children, hospital | crianças pontuam mais e embarcam primeiro |
| card_field_hospital | Hospital de Campanha | médica | épica | shelter, hospital | cria mini-abrigo temporário |
| card_medicine_cache | Estoque de Insulina | médica | comum | hospital | reduz mortes de pacientes |
| card_hospital_corridor | Corredor Hospitalar | médica | rara | hospital, route | rotas hospitalares mais rápidas |
| card_mercy_protocol | Protocolo Misericórdia | médica | anômala | moral_debt, hospital | salva muitos vulneráveis, abandona adultos |
| card_neighborhood_committees | Comitês de Bairro | cívica | comum | volunteer, trust | +confiança local |
| card_school_shelters | Abrigos de Escola | cívica | comum | shelter, children | +capacidade de abrigo |
| card_community_kitchens | Cozinhas Comunitárias | cívica | incomum | volunteer, trust | -pânico por escassez |
| card_popular_workshops | Oficinas Populares | cívica | rara | volunteer, repair | reparos gratuitos ocasionais |
| card_mutual_aid | Rede de Apoio Mútuo | cívica | épica | volunteer, shelter | autoevacuação lenta |
| card_bridge_bailey | Ponte Bailey | engenharia | épica | bridge, engineer | reconecta estrada colapsada |
| card_road_crews | Equipes de Desobstrução | engenharia | comum | engineer, route | reduz bloqueios |
| card_mobile_repair | Oficina Móvel | engenharia | incomum | repair | repara ônibus em campo |
| card_drainage_pumps | Bombas de Drenagem | engenharia | rara | engineer | segura enchentes |
| card_black_market_diesel | Diesel Sem Nota | mercado_negro | incomum | black_market, diesel | combustível imediato, dívida moral |
| card_paid_toll | Pedágio Negociado | mercado_negro | comum | black_market, route | remove bloqueio por verba |
| card_midnight_favors | Favores na Madrugada | mercado_negro | rara | black_market, night_ops | evento ruim vira recurso |
| card_bridge_owner | O Dono da Ponte | mercado_negro | lendária | black_market, bridge | controla ponte, final sombrio |
| card_red_moon | Lua Vermelha | anomalia | anômala | anomaly | perigo sobe à noite, cartas raras sobem |
| card_time_window | Janela de 11 Minutos | anomalia | anômala | anomaly, route | uma rota fica instantânea temporariamente |
| card_empty_bus | O Ônibus Vazio | anomalia | anômala | anomaly, moral_debt | salva coorte fantasma, custo desconhecido |

---

## 15. Conteúdo inicial de eventos

O MVP deve implementar 60+ eventos. O vertical slice pode começar com estes 35.

| ID | Nome | Categoria | Gatilho | Decisão central |
|---|---|---|---|---|
| event_fake_news_last_bus | Boato do Último Ônibus | social | desinformação alta | corrigir, usar isca ou ignorar |
| event_fuel_depot_looted | Saque no Depósito de Diesel | social | ordem baixa | proteger, negociar ou perder combustível |
| event_bridge_crack | Ponte Trincando | rota | perigo em estrada ponte | fechar cedo ou arriscar comboio |
| event_hospital_plea | Hospital Pede Prioridade | moral | pacientes em risco | salvar hospital ou manter plano |
| event_driver_union | Sindicato Exige Segurança | facção | fadiga alta | ceder, pressionar ou substituir |
| event_influencer_leaks_route | Influencer Revela Rota | social | mídia/desinformação | prender, desmentir ou redirecionar |
| event_blackout | Apagão Geral | colapso | crise nível 2 | gastar geradores ou aceitar cegueira |
| event_school_shelter_overflow | Abrigo Escolar Lotado | cívico | abrigo cheio | expandir, transferir ou fechar portas |
| event_illegal_checkpoint | Pedágio Ilegal | rota | saques altos | pagar, escoltar ou desviar |
| event_bus_missing | Comboio Sumiu | rota | perigo alto | resgatar ou abandonar |
| event_children_at_terminal | Crianças no Terminal Errado | moral | fake news | redirecionar frota ou acalmar |
| event_press_conference | Coletiva de Imprensa | facção | pressão política | transparência ou propaganda |
| event_fire_jumps_river | Fogo Cruza o Rio | colapso | distrito colapsado | evacuar margem ou conter |
| event_flooded_underpass | Túnel Alagado | rota | chuva/enchente | bombear, bloquear ou arriscar |
| event_volunteers_arrive | Voluntários Chegam | cívico | confiança alta | organizar ou dispensar |
| event_panic_stampede | Tumulto no Embarque | social | pânico alto | parar embarque ou usar força |
| event_radio_silence | Silêncio no Rádio | comunicação | infraestrutura baixa | mandar equipe ou operar no escuro |
| event_mayor_calls | Ligação do Prefeito | facção | alta influência em risco | obedecer ou recusar |
| event_militia_offer | Milícia Oferece Escolta | mercado_negro | ordem baixa | aceitar custo moral ou rejeitar |
| event_refinery_blast | Explosão na Refinaria | colapso | diesel alto/industrial | conter ou evacuar industrial |
| event_false_safe_zone | Zona Segura Falsa | social | desinformação alta | admitir erro ou encobrir |
| event_damaged_bus_fire | Ônibus em Chamas | frota | dano alto | salvar passageiros ou veículo |
| event_shelter_infection | Surto no Abrigo | médica | abrigo lotado | quarentena ou dispersão |
| event_elderly_home | Asilo Isolado | moral | idosos em distrito | rota especial ou abandono |
| event_road_crew_trapped | Engenheiros Presos | engenharia | bloqueio alto | resgatar para ganhar reparos |
| event_night_curfew_backlash | Revolta Contra Toque de Recolher | segurança | autoridade alta | recuar ou reprimir |
| event_rain_of_ash | Chuva de Cinzas | colapso | crise nível 3 | reduzir velocidade/visibilidade |
| event_bus_driver_hero | Motorista Herói | frota | sucesso de rota perigosa | promover ou preservar anonimato |
| event_faction_radio_hams | Rádio Amadores Pedem Frequência | comunicação | carta rádio | abrir frequência ou controlar |
| event_terminal_fire | Terminal Incendiado | colapso | pânico/saque | redirecionar embarque |
| event_last_train_future_hook | Último Trem | expansão | cenário ferroviário futuro | gancho pós-MVP |
| event_anomaly_red_signal | Sinal Vermelho Permanente | anomalia | carta anômala | obedecer sinal ou ignorar |
| event_population_refuses | Bairro Recusa Evacuação | social | confiança baixa | convencer, forçar ou abandonar |
| event_food_riot | Motim por Comida | cívico | abrigo sem suprimento | abastecer ou remover abrigo |
| event_command_center_threatened | Central Ameaçada | colapso | perigo no centro | mover comando ou resistir |

---

## 16. Cenários iniciais

### 16.1 Tutorial — “Primeira Sirene”

Objetivo: ensinar sem sobrecarregar.

- 5 distritos.
- 2 abrigos.
- 3 ônibus.
- 8 cartas possíveis.
- Eventos roteirizados.
- Sem anomalias.
- Duração: 12 minutos.

Vitória tutorial:

- evacuar 1.500 pessoas;
- completar 3 ordens de evacuação;
- escolher 2 cartas;
- resolver 1 evento.

### 16.2 Cidade Cinza

Cenário base.

- 12 distritos.
- 3 abrigos.
- 8 ônibus.
- Ameaça: incêndio urbano + queda de infraestrutura.
- Duração média: 45–70 minutos.

Objetivo:

- salvar 35% da população para vitória mínima;
- 55% para vitória boa;
- 75% para vitória heroica.

### 16.3 Porto Santo Amaro

Cenário logístico.

- 14 distritos.
- 2 pontes críticas.
- Porto como saída especial.
- Muito combustível, muitas rotas frágeis.

Objetivo:

- manter porto operacional até evacuar comboios suficientes.

### 16.4 Vale das Sirenas

Cenário social/comunicação.

- 10 distritos.
- pânico e fake news altos.
- ameaça se move devagar, mas população resiste.

Objetivo:

- reduzir pânico enquanto evacua.

### 16.5 Infinito — “Colapso Total”

- Sem vitória final.
- Crise escala em ondas.
- Cartas sobem de raridade indefinidamente.
- Duplicatas viram upgrades.
- A cada marco, o jogador pode extrair relatório e encerrar run com pontuação.
- Depois de certo ponto, o jogo fica deliberadamente opressivo, mas ainda com decisões significativas.

---

## 17. UI e UX

### 17.1 Tela principal da run

Layout recomendado:

```text
┌─────────────────────────────────────────────────────────────┐
│ Top bar: tempo | velocidade | população salva | combustível │
├───────────────┬───────────────────────────────┬─────────────┤
│ Feed/eventos  │                               │ Painel      │
│ rádio         │          MAPA DA CIDADE       │ distrito/   │
│ alertas       │                               │ rota        │
├───────────────┴───────────────────────────────┴─────────────┤
│ Bottom bar: cartas ativas | botões ordem | pausa | filtros   │
└─────────────────────────────────────────────────────────────┘
```

### 17.2 Interações essenciais

- Clicar em distrito abre painel:
  - população;
  - perigo;
  - pânico;
  - confiança;
  - mortes projetadas;
  - botão “Criar evacuação daqui”.

- Clicar em abrigo mostra:
  - capacidade;
  - ocupação;
  - segurança;
  - suprimentos.

- Criar rota:
  - selecionar origem;
  - selecionar destino;
  - escolher prioridade;
  - escolher ônibus;
  - confirmar.

- Clicar em ônibus:
  - status;
  - ocupação;
  - dano;
  - combustível;
  - rota atual.

### 17.3 Legibilidade do mapa

Cores podem ser definidas depois, mas estados visuais devem existir:

- distrito seguro;
- distrito ameaçado;
- distrito em pânico;
- distrito colapsando;
- distrito perdido;
- abrigo;
- rota ativa;
- rota bloqueada;
- comboio em movimento.

### 17.4 Eventos

Eventos importantes devem pausar o jogo por padrão.

Tipos de aviso:

- pequeno: feed lateral;
- médio: banner clicável;
- grande: modal com decisão.

### 17.5 Tela de cartas

Quando abrir:

- pausa a simulação;
- mostra 3 cartas;
- mostra custo de reroll;
- mostra tags atuais do jogador;
- mostra sinergias próximas;
- permite tooltip detalhado;
- escolher carta fecha modal e aplica efeito.

### 17.6 Relatório final

Exibir:

- população inicial;
- salvos;
- mortos;
- desaparecidos;
- porcentagem salva;
- coortes salvas;
- distritos perdidos;
- principais decisões;
- cartas-chave da build;
- score;
- título da run.

Títulos possíveis:

- “Burocrata do Fim”;
- “O Último Motorista”;
- “A Cidade no Rádio”;
- “Salvação com Mãos Sujas”;
- “Ninguém Saiu em Ordem, Mas Saíram”.

---

## 18. Direção artística e áudio

### 18.1 Arte

MVP:

- formas simples;
- ícones vetoriais ou pixel placeholder;
- mapa 2D limpo;
- ônibus como retângulos/ícones;
- distritos como blocos/nós.

Pós-MVP:

- pixel art 16/32px;
- animação simples de fumaça/luzes;
- retratos estilizados para facções;
- cartões com ilustração minimalista;
- mapa com pequenas vinhetas urbanas.

### 18.2 Interface temática

A UI deve parecer uma central de despacho:

- rádio;
- mapas de emergência;
- fichas burocráticas;
- alertas vermelhos;
- carimbos;
- linhas de rota;
- ruído/glitch sutil.

### 18.3 Áudio

MVP:

- clique;
- alerta;
- sirene curta;
- rádio estático;
- motor distante;
- confirmação de carta;
- evento grave.

Pós-MVP:

- camada musical dinâmica por crise;
- vozes de rádio proceduralmente selecionadas;
- som de chuva/fogo/queda de energia por cenário.

---

## 19. Arquitetura técnica

### 19.1 Princípio central

A UI observa o estado. A simulação altera o estado.

Não fazer:

```text
Botão da UI calcula morte, muda pânico, escolhe evento e move ônibus diretamente.
```

Fazer:

```text
UI cria Command/Intent -> SimulationRunner processa -> GameState muda -> sinais notificam UI.
```

### 19.2 Camadas

```text
Content JSON
   ↓
ContentDb / ContentLoader / ContentValidator
   ↓
RunConfig + GameState
   ↓
Simulation systems
   ↓
Signals / snapshots
   ↓
UI controllers / scenes
```

### 19.3 GameState

`GameState` guarda tudo que precisa ser salvo/reproduzido:

```text
seed
rng_state
elapsed_minutes
crisis_level
global_resources
global_metrics
district_states
road_states
shelter_states
bus_units
evacuation_orders
owned_cards
active_modifiers
scheduled_events
event_history
run_flags
score_state
```

### 19.4 SimulationRunner

Responsável por:

- receber comandos do jogador;
- avançar tick;
- chamar sistemas em ordem estável;
- emitir eventos para UI.

Ordem sugerida do tick:

```text
1. clock.advance(delta)
2. economy.update_passive_income
3. collapse_director.update
4. event_director.update
5. fleet_manager.update
6. evacuation_resolver.update
7. population_model.update_attrition
8. card_system.update_temporary_modifiers
9. score_system.update
10. check_end_conditions
11. emit state_changed
```

### 19.5 Comandos do jogador

Criar uma estrutura de comandos:

```text
CreateEvacuationOrder
CancelEvacuationOrder
AssignBusToOrder
UnassignBusFromOrder
ChangePriorityPolicy
SpendBudgetOnReroll
ChooseCard
ChooseEventOption
PauseSimulation
SetSimulationSpeed
RepairBus
BuyEmergencyFuel
```

No MVP, comandos podem ser dictionaries tipados por enum. Depois podem virar classes.

### 19.6 Determinismo

Toda aleatoriedade da run deve usar `DeterministicRng` do jogo, nunca `randf()` solto.

Requisito de teste:

- mesma seed + mesmas ações = mesmo resultado.

### 19.7 Salvamento

Salvar em JSON versionado:

```text
user://profile_v1.json
user://save_run_autosave_v1.json
user://runs/run_YYYYMMDD_HHMM_seed.json
```

Todo save deve ter:

```json
{
  "save_version": 1,
  "game_version": "0.1.0",
  "created_at": "...",
  "run_state": {}
}
```

### 19.8 Modificadores

Usar `ModifierStack` para evitar ifs espalhados.

Exemplos:

```text
boarding_rate_mult
fuel_consumption_mult
road_danger_add
district_panic_add
fake_news_event_weight_mult
medical_vulnerability_mult
authority_gain_mult
trust_loss_mult
```

Cada carta/evento adiciona modificadores com:

```text
source_id
target_scope
target_id opcional
stat
operation: add, multiply, max, min, set_flag
duration_minutes opcional
stacking_rule
```

---

## 20. Schemas de dados

### 20.1 CardDef

```json
{
  "id": "string_unique",
  "name": "string",
  "class": "logistics|engineering|communications|security|medical|civic|black_market|anomaly",
  "rarity": "common|uncommon|rare|epic|legendary|anomalous",
  "tags": ["string"],
  "min_crisis_level": 0,
  "max_level": 3,
  "description": "string",
  "effects_by_level": [
    {
      "stat_name": 1.0
    }
  ],
  "requirements": {},
  "exclusive_group": null,
  "flavor": "string"
}
```

### 20.2 EventDef

```json
{
  "id": "string_unique",
  "title": "string",
  "body": "string",
  "category": "collapse|social|route|faction|moral|anomaly",
  "tags": ["string"],
  "min_crisis_level": 0,
  "weight": 10,
  "cooldown_minutes": 30,
  "trigger": {},
  "options": [
    {
      "id": "string",
      "label": "string",
      "requirements": {},
      "effects": {}
    }
  ]
}
```

### 20.3 MapDef

```json
{
  "id": "cidade_cinza",
  "name": "Cidade Cinza",
  "description": "string",
  "districts": [
    {
      "id": "centro",
      "name": "Centro",
      "x": 0.5,
      "y": 0.5,
      "tags": ["center", "terminal"],
      "population": {
        "adults": 4200,
        "children": 900,
        "elderly": 600,
        "patients": 120,
        "essential_staff": 240,
        "volunteer_drivers": 30,
        "high_influence": 60
      },
      "panic": 10,
      "trust": 55,
      "danger": 5,
      "collapse": 0,
      "boarding_base_per_minute": 80,
      "is_shelter": false,
      "shelter_capacity": 0
    }
  ],
  "roads": [
    {
      "id": "road_centro_terminal",
      "from": "centro",
      "to": "terminal_oeste",
      "length_km": 4.2,
      "traffic": 40,
      "blockade": 0,
      "danger": 5,
      "quality": 80,
      "tags": ["avenue"]
    }
  ]
}
```

### 20.4 ScenarioDef

```json
{
  "id": "campanha_01_cidade_cinza",
  "name": "Cidade Cinza",
  "map_id": "cidade_cinza",
  "starting_seed_mode": "random",
  "starting_resources": {
    "budget": 8,
    "fuel": 1200,
    "order": 50,
    "trust": 50,
    "communication": 5,
    "intelligence": 3,
    "medical_supplies": 20,
    "parts": 15,
    "authority": 0
  },
  "starting_buses": [
    { "id": "bus_01", "capacity": 70, "fuel_max": 180, "speed_kmh": 38, "tags": [] }
  ],
  "starting_cards": ["card_fuel_rationing", "card_public_map"],
  "allowed_card_classes": ["logistics", "communications", "security", "medical", "civic", "engineering", "black_market", "anomaly"],
  "objectives": [
    { "type": "save_population_percent", "value": 0.35, "label": "Salvar 35% da população" }
  ],
  "end_conditions": {
    "max_minutes": 720,
    "command_center_lost": true,
    "all_shelters_lost": true
  }
}
```

---

## 21. Testes

### 21.1 Estratégia

A maior parte dos testes deve rodar sem UI.

Categorias:

1. **Unitários**: rota, RNG, cartas, eventos, população.
2. **Integração**: simular 10 minutos com seed fixa.
3. **Regressão**: seed conhecida deve gerar resultado conhecido.
4. **Conteúdo**: JSON válido, ids únicos, referências existentes.
5. **Performance**: simular N minutos sem render em tempo aceitável.

### 21.2 Testes obrigatórios do core

- RNG retorna mesma sequência por seed.
- Dijkstra encontra rota mais barata.
- Bloqueio aumenta custo de rota.
- Distrito com perigo alto gera mais mortes.
- Pânico reduz embarque.
- Confiança/comunicação aumentam embarque.
- Ônibus consome combustível por km.
- Ônibus sem combustível para ou reduz operação.
- Carta aplica modificador correto.
- Duplicata de carta aumenta nível.
- Oferta de carta respeita raridade e crise.
- Evento respeita trigger e cooldown.
- Escolha de evento aplica efeitos.
- Save/load preserva estado.
- Mesma seed + mesmas ações gera mesmo resultado.

### 21.3 Comandos sugeridos

Criar `tools/run_tests.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/integration -gexit
```

Criar `tools/validate_content.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
godot --headless --path . -s scripts/tools/ValidateContentCli.gd
```

Criar `tools/simulate_balance.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
godot --headless --path . -s scripts/tools/SimulateRunsCli.gd -- --scenario campanha_01_cidade_cinza --runs 100 --minutes 720
```

---

## 22. Balanceamento

### 22.1 Métricas para coletar em simulações

Para cada run simulada:

- seed;
- cenário;
- população inicial;
- população salva;
- mortes;
- desaparecidos;
- tempo de sobrevivência;
- cartas escolhidas;
- número de rerolls;
- combustível restante;
- ônibus perdidos;
- eventos disparados;
- score;
- causa de fim;
- distritos salvos/perdidos.

### 22.2 Alvos iniciais

Para cenário base no MVP:

| Percentil de player | Salvos esperados |
|---|---:|
| Iniciante | 20–35% |
| Intermediário | 35–55% |
| Bom | 55–70% |
| Excelente | 70–82% |
| Quebrando o jogo | 82%+ |

### 22.3 Curva de raridade sugerida

| Crise | Comum | Incomum | Rara | Épica | Lendária | Anômala |
|---:|---:|---:|---:|---:|---:|---:|
| 0 | 80 | 18 | 2 | 0 | 0 | 0 |
| 1 | 65 | 27 | 8 | 0 | 0 | 0 |
| 2 | 48 | 32 | 16 | 4 | 0 | 0 |
| 3 | 35 | 34 | 22 | 8 | 1 | 0 |
| 4 | 24 | 32 | 28 | 13 | 2 | 1 |
| 5+ | 15 | 28 | 32 | 18 | 4 | 3 |

### 22.4 Economia de reroll

Custo sugerido por tela de recompensa:

```text
primeiro reroll: 2 verba
segundo reroll: 4 verba
terceiro reroll: 7 verba
quarto+: 11 verba
```

Reroll nunca deve ser obrigatório, mas deve ser tentador quando o jogador está perto de fechar sinergia.

### 22.5 Evitar snowball excessivo

- Cartas fortes devem ter custo, condição ou risco.
- Builds muito seguras devem perder em pontuação máxima.
- Mercado negro deve resolver curto prazo e cobrar no longo prazo.
- Autoridade deve controlar caos e gerar revolta.
- Comunicação deve ser poderosa socialmente, mas não remove bloqueios físicos.

---

## 23. Fases de implementação

Cada fase abaixo deve ser uma tarefa separada para o Codex.

---

### Fase 00 — Bootstrap do repositório

Objetivo: criar projeto Godot mínimo, estrutura de pastas e documentação base.

Tarefas:

- Criar `project.godot` mínimo.
- Criar `.gitignore` adequado para Godot.
- Criar `README.md`.
- Criar `AGENTS.md`.
- Criar pastas da estrutura recomendada.
- Criar cena `scenes/main/Main.tscn` com script simples.
- Criar autoloads vazios: `App`, `ContentDb`, `SaveService`, `SettingsService`.
- Criar `tools/run_tests.sh`, `tools/validate_content.sh` como placeholders.

Critérios de aceite:

- Projeto abre no Godot.
- `godot --path .` roda sem erro fatal.
- Estrutura principal existe.
- README explica como rodar.

Prompt recomendado:

```text
Execute a Fase 00 do plano. Crie o projeto Godot mínimo e a estrutura de pastas. Não implemente gameplay ainda.
```

---

### Fase 01 — Core determinístico

Objetivo: criar base de simulação sem UI.

Tarefas:

- Implementar `DeterministicRng.gd`.
- Implementar `GameEnums.gd`.
- Implementar `GameConstants.gd`.
- Implementar `RunConfig.gd`.
- Implementar `GameState.gd` básico.
- Implementar `SimulationClock.gd`.
- Implementar `SimulationRunner.gd` com tick vazio.
- Criar testes de RNG e clock.

Critérios de aceite:

- Teste prova que mesma seed gera mesma sequência.
- `SimulationRunner.advance(minutes)` altera tempo corretamente.
- Nenhum sistema usa aleatoriedade global.

Prompt:

```text
Execute a Fase 01. Foque em core determinístico e testes. Não crie UI além do mínimo existente.
```

---

### Fase 02 — Content loading e validação

Objetivo: carregar JSON de mapas, cartas, eventos e cenários.

Tarefas:

- Implementar `ContentDb.gd`.
- Implementar defs: `CardDef`, `EventDef`, `ScenarioDef`, `MapDef`, `DistrictDef`, `RoadDef`.
- Implementar `ContentValidator.gd`.
- Criar fixtures pequenos.
- Criar `ValidateContentCli.gd`.
- Criar testes de validação.

Critérios de aceite:

- JSON inválido falha com mensagem clara.
- IDs duplicados falham.
- Referência a mapa/carta/evento inexistente falha.
- Conteúdo fixture carrega sem erro.

Prompt:

```text
Execute a Fase 02. Implemente carregamento e validação de conteúdo JSON conforme schemas do plano. Inclua fixtures e testes.
```

---

### Fase 03 — Cidade em grafo e pathfinding

Objetivo: representar distritos, estradas e rotas.

Tarefas:

- Implementar `CityGraph.gd`.
- Implementar `DistrictState.gd`.
- Implementar `RoadState.gd`.
- Implementar `ShelterState.gd`.
- Implementar `RoutePlanner.gd` com Dijkstra.
- Criar mapa fixture `tiny_map.json`.
- Criar testes de pathfinding.

Critérios de aceite:

- Dijkstra encontra rota entre dois distritos.
- Estrada bloqueada altera rota.
- Estrada perigosa aumenta custo.
- Distrito abrigo é reconhecido.

Prompt:

```text
Execute a Fase 03. Crie o modelo de cidade em grafo e pathfinding com testes. Não implemente frota ainda.
```

---

### Fase 04 — População e evacuação básica

Objetivo: simular população por coorte e mortes por perigo.

Tarefas:

- Implementar `PopulationModel.gd`.
- Implementar cálculo de vulnerabilidade.
- Implementar embarque por prioridade.
- Implementar atrito/mortes por perigo e pânico.
- Criar testes para coortes.

Critérios de aceite:

- Prioridade `children_first` embarca crianças primeiro.
- Prioridade `medical_first` embarca pacientes primeiro.
- Perigo alto aumenta mortes.
- Pânico reduz embarque.

Prompt:

```text
Execute a Fase 04. Implemente modelo de população agregada e evacuação por coorte com testes.
```

---

### Fase 05 — Frota, ônibus e ordens de evacuação

Objetivo: ônibus executam rotas e salvam pessoas.

Tarefas:

- Implementar `BusUnit.gd`.
- Implementar `FleetManager.gd`.
- Implementar `EvacuationOrder.gd`.
- Implementar `EvacuationResolver.gd`.
- Integrar com `RoutePlanner`.
- Integrar consumo de combustível.
- Integrar dano/fadiga simples.
- Teste de uma rota completa: origem -> abrigo.

Critérios de aceite:

- Ônibus sai, viaja, embarca, viaja, desembarca.
- População do distrito diminui.
- População salva aumenta.
- Combustível diminui.
- Ônibus sem combustível não completa rota.

Prompt:

```text
Execute a Fase 05. Faça ônibus executarem ordens de evacuação sobre o grafo. Inclua teste de integração simples.
```

---

### Fase 06 — Diretor de colapso

Objetivo: cidade degrada com o tempo.

Tarefas:

- Implementar `CollapseDirector.gd`.
- Propagar perigo por vizinhança.
- Aumentar colapso quando perigo alto.
- Bloquear estradas por colapso.
- Criar crise global por nível.
- Testes de propagação.

Critérios de aceite:

- Distrito perigoso piora com tempo.
- Colapso afeta estradas conectadas.
- Mitigadores futuros podem alterar fórmula via modificadores.

Prompt:

```text
Execute a Fase 06. Implemente o diretor de colapso com fórmulas simples e testáveis.
```

---

### Fase 07 — Sistema de modificadores

Objetivo: criar base para cartas e eventos alterarem regras sem hardcode.

Tarefas:

- Implementar `ModifierStack.gd`.
- Suportar operações add/multiply/min/max/set flag.
- Suportar duração.
- Aplicar modificadores em embarque, consumo, perigo e pânico.
- Testes.

Critérios de aceite:

- Dois modificadores multiplicativos compõem corretamente.
- Modificador temporário expira.
- Sistemas consultam `ModifierStack`, não ifs de carta específica.

Prompt:

```text
Execute a Fase 07. Crie ModifierStack genérico e conecte nos primeiros stats da simulação.
```

---

### Fase 08 — Cartas e ofertas

Objetivo: implementar escolha de cartas, raridade, reroll e sinergia.

Tarefas:

- Implementar `CardSystem.gd`.
- Implementar `CardOfferGenerator.gd`.
- Carregar cartas JSON.
- Aplicar carta como modificadores.
- Implementar raridade por crise.
- Implementar reroll com custo.
- Implementar upgrade por duplicata.
- Testes de oferta e aplicação.

Critérios de aceite:

- Oferta retorna 3 cartas distintas.
- Raridade respeita crise.
- Reroll consome verba.
- Carta escolhida altera regra observável.
- Duplicata aumenta nível até máximo.

Prompt:

```text
Execute a Fase 08. Implemente sistema de cartas data-driven, ofertas, raridade, reroll e upgrades com testes.
```

---

### Fase 09 — Eventos com escolhas

Objetivo: eventos disparam e opções aplicam consequências.

Tarefas:

- Implementar `EventDirector.gd`.
- Carregar eventos JSON.
- Avaliar triggers.
- Respeitar cooldown.
- Enfileirar evento para UI.
- Aplicar opção escolhida.
- Implementar consequências imediatas.
- Criar primeiros eventos reais.
- Testes.

Critérios de aceite:

- Evento com trigger falso não dispara.
- Evento com trigger verdadeiro pode disparar.
- Cooldown impede repetição imediata.
- Opção altera estado.

Prompt:

```text
Execute a Fase 09. Implemente EventDirector data-driven com triggers, cooldown e escolhas.
```

---

### Fase 10 — UI de mapa jogável

Objetivo: criar a primeira interface interativa da run.

Tarefas:

- Implementar `MapView.tscn`.
- Renderizar distritos como nós.
- Renderizar estradas como linhas.
- Renderizar ônibus como tokens.
- Painel de distrito.
- Painel de rota.
- Botão para criar ordem simples.
- Top bar de recursos.
- Controles pause/velocidade.

Critérios de aceite:

- Jogador vê mapa e recursos.
- Clicar distrito mostra dados.
- Criar ordem de evacuação pela UI funciona.
- Tempo pode pausar/acelerar.
- Ônibus se move visualmente.

Prompt:

```text
Execute a Fase 10. Crie UI jogável simples para mapa, distritos, recursos e criação de rota. Não faça polimento visual avançado.
```

---

### Fase 11 — UI de cartas e eventos

Objetivo: fechar loop de decisões.

Tarefas:

- Implementar `CardChoiceModal.tscn`.
- Implementar `EventModal.tscn`.
- Tooltips de carta.
- Reroll.
- Mostrar tags/sinergias.
- Eventos pausam jogo.
- Escolha de evento aplica efeito.

Critérios de aceite:

- Recompensa de carta aparece em marco configurado.
- Escolher carta muda estado.
- Reroll funciona e atualiza custo.
- Evento aparece e opções funcionam.

Prompt:

```text
Execute a Fase 11. Crie UI de escolha de cartas e eventos, conectada aos sistemas já existentes.
```

---

### Fase 12 — Cenário tutorial

Objetivo: ter onboarding jogável.

Tarefas:

- Criar `data/maps/tutorial_map.json`.
- Criar `data/scenarios/tutorial.json`.
- Criar 8–12 cartas iniciais.
- Criar 4–6 eventos roteirizados.
- Criar mensagens guiadas.
- Limitar sistemas para ensinar gradualmente.

Critérios de aceite:

- Novo jogador entende como criar rota.
- Tutorial termina em 10–15 minutos.
- Não depende de conhecimento externo.

Prompt:

```text
Execute a Fase 12. Crie cenário tutorial com mapa pequeno, cartas/eventos mínimos e mensagens guiadas.
```

---

### Fase 13 — Save/load e perfil

Objetivo: persistir run e meta-progressão.

Tarefas:

- Implementar `SaveService.gd`.
- Save de run atual.
- Autosave.
- Load.
- Profile com desbloqueios.
- Migração de save versionado.
- Testes.

Critérios de aceite:

- Salvar e carregar mantém estado relevante.
- Save tem versão.
- Save inválido não crasha o jogo.

Prompt:

```text
Execute a Fase 13. Implemente save/load versionado e perfil de desbloqueios com testes.
```

---

### Fase 14 — Relatório final e scoring

Objetivo: dar fechamento narrativo e mecânico.

Tarefas:

- Implementar `ScoreSystem.gd`.
- Implementar `EndRunReport.tscn`.
- Calcular score por coorte, população, decisões, cartas, tempo.
- Listar eventos marcantes.
- Mostrar título da run.
- Salvar histórico de runs.

Critérios de aceite:

- Run termina com relatório completo.
- Score é reproduzível.
- Relatório cita cartas e eventos principais.

Prompt:

```text
Execute a Fase 14. Implemente pontuação, condições de fim e relatório final narrativo.
```

---

### Fase 15 — Conteúdo do cenário base

Objetivo: transformar vertical slice em jogo com variedade.

Tarefas:

- Implementar `cidade_cinza.json` com 12 distritos.
- Implementar 40 cartas da seção 14.
- Implementar 35 eventos da seção 15.
- Implementar cenário `campanha_01_cidade_cinza.json`.
- Balancear valores iniciais.
- Validar conteúdo.

Critérios de aceite:

- Uma run completa é jogável.
- Pelo menos 4 builds são possíveis.
- Não há ids quebrados.
- Conteúdo passa validação.

Prompt:

```text
Execute a Fase 15. Crie conteúdo data-driven para Cidade Cinza com as cartas/eventos listados no plano.
```

---

### Fase 16 — Modo infinito

Objetivo: cumprir a ideia de jogo não finito.

Tarefas:

- Criar cenário `infinito_colapso_total.json`.
- Implementar escalonamento de crise sem limite rígido.
- Implementar marcos de extração voluntária.
- Implementar upgrades por duplicata mais longos.
- Implementar raridade tardia.
- Implementar score por ondas.

Critérios de aceite:

- Jogo não acaba por tempo fixo.
- Crise continua escalando.
- Jogador pode encerrar e registrar score.
- Cartas continuam relevantes por upgrades.

Prompt:

```text
Execute a Fase 16. Implemente modo infinito com escalonamento, marcos e encerramento voluntário.
```

---

### Fase 17 — Polimento de UX e acessibilidade

Objetivo: tornar o jogo confortável.

Tarefas:

- Tooltips completos.
- Pausa automática configurável.
- Confirmação de decisões perigosas.
- Log de eventos pesquisável.
- Filtros de mapa.
- Atalhos de teclado.
- Tamanho de fonte configurável.
- Modo daltônico básico.

Critérios de aceite:

- Jogador entende por que algo aconteceu.
- Decisões críticas mostram consequência prevista.
- UI não exige reflexo rápido.

Prompt:

```text
Execute a Fase 17. Faça polimento de UX, tooltips, filtros, atalhos e acessibilidade básica.
```

---

### Fase 18 — Balanceamento automatizado

Objetivo: medir runs e ajustar números.

Tarefas:

- Implementar `SimulateRunsCli.gd`.
- Rodar N runs sem UI.
- Exportar CSV/JSON de métricas.
- Criar `docs/balance_notes.md`.
- Ajustar cartas/eventos dominantes.

Critérios de aceite:

- 100 runs simuladas geram relatório.
- Seeds quebradas são registradas.
- Pelo menos 3 ajustes de balance documentados.

Prompt:

```text
Execute a Fase 18. Crie ferramenta headless de simulação de balanceamento e relatório de métricas.
```

---

### Fase 19 — Build e distribuição

Objetivo: exportar builds distribuíveis.

Tarefas:

- Configurar `export_presets.cfg`.
- Criar exports Windows/Linux/Web inicialmente.
- Criar `tools/export_builds.sh`.
- Criar `tools/make_release_zip.sh`.
- Criar página de créditos/licenças.
- Criar checklist de release.

Critérios de aceite:

- Build exporta localmente.
- ZIP contém executável e dados.
- Versão aparece no menu.
- Saves não ficam dentro da pasta do jogo.

Prompt:

```text
Execute a Fase 19. Configure export e scripts de release para uma demo distribuível.
```

---

### Fase 20 — QA final da demo

Objetivo: fechar uma versão publicável.

Tarefas:

- Rodar testes.
- Jogar tutorial completo.
- Jogar Cidade Cinza completo.
- Jogar 20 minutos do infinito.
- Corrigir crashers.
- Corrigir textos quebrados.
- Revisar licenças.
- Criar changelog.
- Criar README para jogadores.

Critérios de aceite:

- Sem crash conhecido em fluxo principal.
- Tutorial completo.
- Uma run normal completa.
- Build exportado.
- Release zip pronto.

Prompt:

```text
Execute a Fase 20. Faça QA final da demo, corrija problemas críticos e prepare release zip.
```

---

## 24. Critérios de “jogo completo”

O projeto pode ser considerado completo para primeira distribuição quando:

- há menu principal;
- há tutorial;
- há pelo menos um cenário completo;
- há modo infinito;
- há 80+ cartas ou, no mínimo, 40 muito bem balanceadas;
- há 60+ eventos ou, no mínimo, 35 variados;
- há save/load;
- há relatório final;
- há export para pelo menos Windows e Linux;
- há README de jogador;
- há créditos/licenças;
- há testes do core;
- o jogo pode ser jogado por 45 minutos sem crash;
- o loop de cartas realmente cria builds diferentes.

---

## 25. Roadmap pós-MVP

### 25.1 Novos modos

1. **Modo Campanha Nacional**  
   Várias cidades conectadas. Recursos carregam parcialmente de uma para outra.

2. **Modo Desafio Diário**  
   Seed fixa e modificadores diários.

3. **Modo Sandbox**  
   Jogador configura ameaça, população, recursos e deck.

4. **Modo Ferrovia**  
   Trens como evacuação de alta capacidade, mas baixa flexibilidade.

5. **Modo Porto/Aeroporto**  
   Janelas de evacuação por navio/avião.

6. **Modo Dois Centros de Comando**  
   Alternar entre zonas da cidade com recursos separados.

### 25.2 Expansões de sistemas

- Facções com reputação persistente.
- Política municipal.
- Clima dinâmico.
- Lei marcial.
- Doenças em abrigos.
- Cadeia de suprimentos.
- Eventos narrativos encadeados.
- Editor de cartas.
- Editor de mapas.
- Workshop/mods.

### 25.3 Arquitetura para novos modos

Criar interface conceitual `GameModeDef`:

```json
{
  "id": "string",
  "scenario_pool": [],
  "ruleset_modifiers": {},
  "allowed_cards": [],
  "objective_set": [],
  "end_condition_set": [],
  "reward_curve": {}
}
```

No código, evitar checks como:

```gdscript
if mode == "infinite":
```

Preferir regras dirigidas por `ScenarioDef` e `GameModeDef`.

---

## 26. Riscos e mitigação

### 26.1 Escopo grande demais

Risco: tentar fazer simulação, UI bonita, conteúdo e build ao mesmo tempo.

Mitigação:

- manter mapa como grafo no MVP;
- fazer arte placeholder;
- implementar conteúdo por JSON;
- priorizar loop jogável.

### 26.2 Codex gerar arquitetura inconsistente

Risco: sessões diferentes criarem padrões diferentes.

Mitigação:

- usar este documento como fonte da verdade;
- manter `AGENTS.md`;
- revisar diffs pequenos;
- exigir testes por fase.

### 26.3 Simulação ilegível

Risco: o jogo parecer injusto.

Mitigação:

- tooltips de causa;
- log de eventos;
- previsão de consequência;
- fórmulas simples no começo.

### 26.4 Balanceamento quebrado

Risco: uma build dominar ou jogo ficar impossível.

Mitigação:

- simulação headless;
- métricas por run;
- ajustes documentados;
- cartas fortes com tradeoff.

### 26.5 Performance

Risco: muita entidade individual.

Mitigação:

- população agregada;
- agentes visuais apenas para ônibus;
- tick de simulação desacoplado de frame;
- evitar pathfinding todo frame;
- cache de rotas quando possível.

---

## 27. Checklist de qualidade para cada PR

Antes de aceitar qualquer PR:

- [ ] A mudança respeita a fase atual?
- [ ] Não colocou regra de gameplay dentro da UI?
- [ ] Adicionou/atualizou teste quando mexeu em simulação?
- [ ] Conteúdo novo passa validação?
- [ ] Mesma seed continua reproduzível?
- [ ] Não há assets sem licença?
- [ ] Não quebrou save versionado?
- [ ] Não introduziu dependência pesada sem motivo?
- [ ] README/docs foram atualizados se necessário?
- [ ] O resumo final lista comandos executados?

---

## 28. Checklist de release

- [ ] Versão atualizada em `Versioning.gd`.
- [ ] `CHANGELOG.md` atualizado.
- [ ] Todos os testes passam.
- [ ] Conteúdo validado.
- [ ] Tutorial testado do início ao fim.
- [ ] Cenário base testado do início ao fim.
- [ ] Modo infinito testado por pelo menos 20 minutos.
- [ ] Export Windows OK.
- [ ] Export Linux OK.
- [ ] Export Web OK se habilitado.
- [ ] ZIP de release criado.
- [ ] Créditos e licenças incluídos.
- [ ] README de jogador incluído.
- [ ] Saves ficam em `user://`.
- [ ] Configurações persistem.
- [ ] Sem crash conhecido no fluxo principal.

---

## 29. Comandos úteis

Instalar Codex CLI, caso ainda não esteja instalado:

```bash
npm i -g @openai/codex
```

Abrir Codex no repositório:

```bash
codex
```

Rodar prompt direto no repositório:

```bash
codex -C . "Leia o plano e execute a Fase 00."
```

Rodar Godot:

```bash
godot --path .
```

Rodar projeto em modo editor:

```bash
godot -e --path .
```

Rodar validação de conteúdo:

```bash
./tools/validate_content.sh
```

Rodar testes:

```bash
./tools/run_tests.sh
```

Exportar build release, depois de configurar preset:

```bash
godot --headless --path . --export-release "Linux/X11" builds/linux/despachante-do-apocalipse.x86_64
```

---

## 30. Primeiro pacote de prompts para execução real

Use estes prompts em sequência.

### Prompt 1 — Bootstrap

```text
Leia DESPACHANTE_DO_APOCALIPSE_PLANO_MESTRE.md e execute somente a Fase 00.
Crie o projeto Godot mínimo, estrutura de pastas, README, AGENTS.md, .gitignore e cena principal placeholder.
Não implemente gameplay.
Ao final, explique como rodar o projeto.
```

### Prompt 2 — Core

```text
Execute somente a Fase 01.
Implemente DeterministicRng, GameState mínimo, SimulationClock e SimulationRunner com tick básico.
Adicione testes unitários para RNG e clock.
Não implemente UI nova.
```

### Prompt 3 — Conteúdo

```text
Execute somente a Fase 02.
Implemente carregamento/validação de JSON para mapas, cenários, cartas e eventos.
Crie fixtures pequenos e testes.
```

### Prompt 4 — Cidade

```text
Execute somente a Fase 03.
Implemente CityGraph, DistrictState, RoadState, ShelterState e RoutePlanner com Dijkstra.
Crie tiny_map.json e testes de rota.
```

### Prompt 5 — Primeira evacuação

```text
Execute as Fases 04 e 05, mas mantenha o escopo mínimo.
Quero conseguir simular um ônibus indo de um distrito a um abrigo e salvando pessoas.
Inclua testes de integração para essa evacuação.
```

### Prompt 6 — Primeiro loop jogável

```text
Execute Fases 06, 07, 08 e 09 em PRs separados ou commits separados.
Depois crie uma UI mínima da Fase 10 para eu clicar em distrito, criar rota e ver ônibus se mover.
Não faça polimento visual ainda.
```

---

## 31. Notas finais de direção

O jogo deve parecer simples por fora e profundo por dentro.

O coração não é “mover ônibus”; é gerenciar consequências. As melhores histórias virão quando o jogador disser:

- “Eu salvei o hospital, mas perdi o porto.”
- “A build de rádio virou o jogo.”
- “O mercado negro me salvou e destruiu meu final.”
- “Eu achei que controlar fake news era secundário, até a cidade correr para o terminal errado.”
- “Mais uma run, agora vou tentar comboio blindado.”

Sempre que houver dúvida de implementação, escolher a alternativa que preserve:

1. simulação testável;
2. clareza para o jogador;
3. conteúdo data-driven;
4. espaço para builds;
5. facilidade de expansão.

---

## 32. Referências úteis

Estas referências são para consulta técnica durante implementação:

- OpenAI Codex CLI: https://developers.openai.com/codex/cli
- OpenAI Codex CLI features: https://developers.openai.com/codex/cli/features
- OpenAI Codex CLI command reference: https://developers.openai.com/codex/cli/reference
- Godot command line tutorial: https://docs.godotengine.org/pt-br/4.x/tutorials/editor/command_line_tutorial.html
- Godot exporting projects: https://docs.godotengine.org/pt-br/4.x/tutorials/export/exporting_projects.html
- GUT Godot Unit Test: https://github.com/bitwes/Gut
