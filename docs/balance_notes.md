# Balance Notes

## Rodada inicial de simulacao automatizada

Ferramenta usada: `scripts/tools/SimulateRunsCli.gd`

Baseline antes do rebalance:

- `campanha_01_cidade_cinza`, `100` runs, `240` minutos, seeds `4000-4099`
  - score medio: `2324.76`
  - notas: `100x S`
  - seeds quebradas: `0`
- `infinito_colapso_total`, `100` runs, retirada na onda `2`, seeds `5000-5099`
  - score medio: `2138.00`
  - notas: `100x S`
  - mortes medias: `0`
  - seeds quebradas: `0`

Leitura inicial:

- `Cidade Cinza` estava premiando recursos e eventos demais; a campanha não estava abrindo espaço para notas abaixo de `S`.
- O infinito estava lucrativo cedo demais; retirar na onda `2` ainda devolvia score de topo com pressão baixa.
- O simulador em lote mostrou estabilidade do core e zero seeds quebradas, então o próximo passo seguro era ajustar economia, grade e pressão do infinito.

## Ajustes aplicados

1. `scripts/sim/ScoreSystem.gd`
   - eventos reduzidos de `12` para `6` pontos por resolução;
   - peso de recursos reduzido;
   - penalidade por tempo aumentada;
   - curva de notas apertada para `S >= 2600`, `A >= 1900`, `B >= 1300`, `C >= 750`.

2. `data/scenarios/campanha_01_cidade_cinza.json`
   - recursos iniciais reduzidos:
     - verba `16 -> 13`
     - combustivel `1200 -> 980`
     - comunicacao `6 -> 5`
     - suprimentos medicos `14 -> 12`
     - pecas `9 -> 7`

3. `data/scenarios/infinito_colapso_total.json` + `scripts/sim/InfiniteModeDirector.gd`
   - recursos iniciais do infinito reduzidos;
   - ondas aceleradas `15 -> 12` minutos;
   - spawn por onda e pressão de perigo/pânico/colapso aumentados;
   - score de onda reduzido para `100 * onda`;
   - `SimulateRunsCli.gd` passou a usar retirada padrão na onda `3` para medir runs menos rasas.

## Reamostragem apos o rebalance

Spot check posterior:

- `campanha_01_cidade_cinza`, `30` runs, `240` minutos, seeds `8000-8029`
  - score medio: `1551.37`
  - notas: `30x B`
  - seeds quebradas: `0`

- `infinito_colapso_total`, `30` runs, retirada na onda `3`, `72` minutos maximos, seeds `9000-9029`
  - score medio: `2421.10`
  - notas: `30x A`
  - seeds quebradas: `0`

## Proximos focos

- Abrir mais variancia no infinito acima da onda `3`; ele ainda gera `0` mortes medias no autoplay atual.
- Melhorar a heuristica do simulador para trocar cartas e prioridades de rota de forma menos linear.
- Revisar eventos que hoje entram em quase toda run de `Cidade Cinza`, porque a fila de eventos ainda esta previsivel demais.
