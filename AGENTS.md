# Instruções permanentes para o Codex

Este repositório contém o jogo "Despachante do Apocalipse".

## Fonte de verdade

Leia primeiro:

- DESPACHANTE_DO_APOCALIPSE_PLANO_MESTRE.md

Siga o plano por fases. Antes de implementar uma fase, verifique os critérios de aceite dessa fase. Ao terminar, rode os testes/comandos disponíveis e registre no resumo o que foi feito, o que foi testado e o que ainda falta.

## Segurança

- Trabalhe somente dentro deste repositório.
- Não edite, mova, apague ou sobrescreva arquivos fora do workspace.
- Não use comandos destrutivos fora da pasta do projeto.
- Não use `Remove-Item -Recurse -Force` fora de subpastas claramente geradas pelo projeto.
- Não use `del /s /q C:\`, `rd /s /q C:\`, `format`, `diskpart`, `takeown`, `icacls`, comandos de registro do Windows, nem alterações no sistema operacional.
- Não use `git reset --hard`, `git clean -fdx` ou comandos equivalentes sem instrução explícita do usuário.
- Não altere `.git`, `.codex` ou credenciais.
- Não instale ferramentas globalmente sem instrução explícita.
- Não grave arquivos em Desktop, Downloads, Documents, System32, Program Files ou diretórios de usuário fora do repo.

## Arquivos que podem ser apagados/recriados

Somente quando necessário:

- build/
- dist/
- tmp/
- temp/
- cache/
- .godot/
- logs gerados pelo projeto
- artefatos de exportação do Godot

## Estilo de implementação

- Prefira Godot 4.x com GDScript.
- Mantenha a simulação determinística.
- Separe dados de gameplay em JSON/resources sempre que possível.
- Escreva testes para sistemas determinísticos.
- Não faça assets finais complexos; use placeholders claros e substituíveis.
- Priorize jogo funcional antes de polimento visual.
- Mantenha arquitetura extensível para modos futuros.