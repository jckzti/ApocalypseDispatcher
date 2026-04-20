# Release Checklist

## Build

- [ ] `export_presets.cfg` revisado
- [ ] `tools/export_builds.sh` executado
- [ ] Build Windows gerada
- [ ] Build Linux gerada
- [ ] Build Web gerada ou bloqueio documentado
- [ ] Versao visivel no menu principal
- [ ] Saves confirmados em `user://`

## QA

- [ ] Suite de testes unitarios passou
- [ ] Suite de integracao passou
- [ ] Conteudo validado
- [ ] Tutorial concluido
- [ ] Cidade Cinza validada em run completa
- [ ] Infinito validado por pelo menos 20 minutos
- [ ] Sem crash conhecido no fluxo principal

## Conteudo e docs

- [ ] `CHANGELOG_DEV.md` atualizado
- [ ] `README.md` revisado para jogadores
- [ ] `docs/credits_and_licenses.md` revisado
- [ ] `docs/balance_notes.md` revisado
- [ ] Licencas de novos assets revisadas

## Empacotamento

- [ ] `tools/make_release_zip.sh` executado
- [ ] ZIP final contem build(s), README e docs essenciais
- [ ] Nome da release inclui versao correta
