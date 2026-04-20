Leia primeiro:

- AGENTS.md
- DESPACHANTE_DO_APOCALIPSE_PLANO_MESTRE.md
- CHANGELOG_DEV.md

Contexto:
A Fase 00 já foi concluída e validada. Continue a partir da Fase 01.

Objetivo:
Implementar o máximo possível do jogo "Despachante do Apocalipse", fase por fase, até chegar a uma versão jogável, funcional, testada e exportável, seguindo o plano mestre.

Modo de trabalho:
1. Trabalhe estritamente dentro deste repositório.
2. Não peça confirmação ao usuário.
3. Não pare após uma única fase, a menos que exista bloqueio real.
4. Após concluir uma fase, continue automaticamente para a próxima.
5. Se uma fase for grande demais, divida internamente em subetapas, mas continue avançando.
6. Priorize jogo funcional antes de polimento.
7. Preserve arquitetura extensível para modos futuros.
8. Não use rede.
9. Não edite, mova, apague ou sobrescreva arquivos fora deste workspace.
10. Não execute comandos destrutivos fora de pastas geradas pelo projeto.
11. Não use `git reset --hard`, `git clean -fdx`, `Remove-Item -Recurse -Force` em raiz do projeto, `rd /s /q`, `format`, `diskpart`, `takeown`, `icacls`, alterações no registro do Windows, nem comandos de sistema.
12. Não altere `.git`, `.codex`, credenciais, PATH global, variáveis globais ou configurações do sistema operacional.

Para cada fase:
1. Leia os critérios de aceite da fase no plano mestre.
2. Implemente a menor fatia completa e testável.
3. Rode validações possíveis, preferindo comandos headless do Godot.
4. Corrija erros encontrados.
5. Atualize `CHANGELOG_DEV.md` com:
   - fase trabalhada;
   - arquivos criados/alterados;
   - decisões técnicas;
   - testes executados;
   - pendências reais.
6. Atualize ou crie `OVERNIGHT_PROGRESS.md` com um resumo acumulado.
7. Gere, quando útil, um patch/checkpoint em `snapshots/phase_XX.patch` usando `git diff`, mas não execute commits se o sandbox bloquear `.git`.

Critérios de prioridade:
1. Core determinístico e testes.
2. Simulação jogável.
3. UI simples mas utilizável.
4. Conteúdo mínimo suficiente para loop viciante.
5. Save/load.
6. Balanceamento inicial.
7. Export desktop.
8. Polimento e documentação.

Validações esperadas:
- `godot --headless --path . --quit`
- scripts em `tools/`, se existirem
- testes automatizados, se existirem
- validação de conteúdo, se existir
- abertura rápida da cena principal, quando possível

Se Godot tentar gravar fora do workspace:
- Reutilize a solução já descoberta na Fase 00, redirecionando `APPDATA` e `LOCALAPPDATA` para subpastas dentro do repositório.
- Registre isso no changelog.

Quando encontrar bloqueio:
1. Registre o bloqueio em `OVERNIGHT_PROGRESS.md`.
2. Faça uma alternativa segura dentro do workspace.
3. Continue em outra frente que não dependa do bloqueio.

Não finalize cedo com frases como "próximo passo: fase seguinte" se ainda houver trabalho viável dentro do plano.
Continue trabalhando fase por fase até:
- todas as fases relevantes estarem concluídas;
- ou a sessão atingir limite/contexto;
- ou surgir bloqueio técnico real que impeça avanço seguro.

Resposta final esperada:
- fases concluídas;
- fases parcialmente concluídas;
- testes executados e resultado;
- arquivos principais alterados;
- como rodar o jogo;
- como continuar se algo ficou pendente.