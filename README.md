# firefox-kiosk-hdmi
Script de automação para Firefox em modo kiosk com áudio HDMI e reinício diário no Lubuntu

# Instalador Firefox Kiosk + Áudio HDMI

Script de automação para configurar um terminal Linux (testado no Lubuntu 22.04) para exibir um painel web em modo kiosk, com áudio roteado para a saída HDMI e reinício automático diário.

## 📋 Sobre o Projeto

Este projeto automatiza a instalação e configuração de um ambiente de quiosque (kiosk) para Firefox. Ele foi criado para resolver problemas comuns como:
- Autoplay de áudio bloqueado em modo kiosk.
- Áudio não roteado corretamente para o HDMI após reiniciar o navegador.
- Necessidade de reiniciar o navegador periodicamente para atualizar a página.

O script cuida de toda a configuração, desde a instalação de dependências até a criação de serviços do systemd para garantir que tudo funcione de forma autônoma.

## ✨ Funcionalidades

- [x] Instalação automática de dependências (`pulseaudio-utils`, `xdotool`).
- [x] Detecção automática do dispositivo de saída HDMI.
- [x] Criação de script de inicialização do Firefox com simulação de cliques para liberar autoplay.
- [x] Configuração de serviços systemd para iniciar o Firefox no boot e reiniciá-lo diariamente.
- [x] Criação de um serviço de monitoramento para garantir que o áudio permaneça no HDMI.
- [x] Criação de arquivo `user.js` no perfil do Firefox para forçar permissões de autoplay.

## 🚀 Como Usar

### Pré-requisitos

- Sistema operacional Linux (testado no Lubuntu 22.04+).
- Firefox instalado (via apt, snap ou manualmente em `/opt/firefox`).
- Conexão com a internet para instalar dependências.
- Estar logado na sessão gráfica (não via SSH/TTY).

### Instalação

1.  Clone este repositório para a máquina de destino:
    ```bash
    git clone https://github.com/seu-usuario/firefox-kiosk-hdmi.git
    cd firefox-kiosk-hdmi
