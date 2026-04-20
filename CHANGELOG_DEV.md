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
