# Changelog

Todas as mudanças notáveis deste projeto serão documentadas aqui.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [1.0.0] - 2026-10-10

### Adicionado
- Script `instalar-kiosk.sh` com instalação automatizada
- Detecção automática de HDMI, Firefox e resolução de tela
- Simulação de cliques com `xdotool` para liberar autoplay
- Criação de `user.js` no perfil do Firefox com permissões agressivas de autoplay
- Serviços systemd para início no boot e reinício diário
- Monitoramento contínuo do áudio via `fix-firefox-audio.service`
- Ativação automática de linger
- Documentação completa no README
- Guia de solução de problemas em `docs/SOLUCAO-DE-PROBLEMAS.md`
- Licença MIT
- Templates de Issue e Pull Request
