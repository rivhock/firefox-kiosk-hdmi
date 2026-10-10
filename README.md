<div align="center">

# 🦊 Firefox Kiosk + Áudio HDMI

### Automação completa para terminais de exibição no Lubuntu

**Script de instalação automatizada para transformar uma máquina Linux em um terminal de painel web em modo kiosk, com áudio no HDMI e reinício diário automático.**

[📖 Documentação](#-sobre-o-projeto) • [🚀 Instalação](#-como-usar) • [🛠️ Problemas](#-solução-de-problemas) • [💡 FAQ](#-faq)

</div>

---

## 📑 Índice

- [Sobre o Projeto](#-sobre-o-projeto)
- [Como Funciona](#-como-funciona)
- [Funcionalidades](#-funcionalidades)
- [Pré-requisitos](#-pré-requisitos)
- [Como Usar](#-como-usar)
- [Personalização](#️-personalização)
- [Solução de Problemas](#-solução-de-problemas)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Testado em](#-testado-em)
- [FAQ](#-faq)
- [Contribuindo](#-contribuindo)
- [Licença](#-licença)

---

## 🎯 Sobre o Projeto

Este projeto automatiza a configuração de um **terminal kiosk** no Lubuntu, exibindo um painel web em tela cheia de forma contínua, com **áudio roteado para o HDMI** e **reinício automático diário**.

Foi criado para resolver três problemas comuns em ambientes de exibição contínua:

1. 🔇 **Autoplay bloqueado** — O Firefox exige interação do usuário para liberar áudio. Em modo kiosk, não há cliques, então os alertas sonoros não tocam.
2. 🔊 **Áudio perdido no reinício** — Após reiniciar o navegador, o áudio volta para o dispositivo padrão (analógico), não para o HDMI.
3. 🔄 **Página desatualizada** — Painéis web precisam ser recarregados periodicamente para manter o conteúdo sincronizado.

O script cuida de **toda a configuração** — da instalação de dependências até a criação dos serviços do systemd que garantem operação autônoma.

---

## 🔄 Como Funciona

```
─────────────────────────────────────────────────────────
  🔌 Boot do sistema                                     
         ↓                                               
  ⚙️  systemd inicia firefox-kiosk.service               
         ↓                                               
  📜 kiosk-start.sh é executado:                         
    1. Aguarda 5s o sistema de áudio estar pronto        
    2. Define HDMI como saída padrão                     
    3. Abre Firefox em modo kiosk                        
    4. Aguarda 20s o carregamento da página              
    5. Simula 3 cliques (libera autoplay)                
    6. Move o áudio do Firefox para o HDMI               
    7. Monitora continuamente os fluxos de áudio         
         ↓                                               
  ⏰ Todos os dias às 07:00 (timer):                     
    firefox-restart.service reinicia o kiosk             
         ↓                                               
  🔁 O ciclo recomeça automaticamente                    
─────────────────────────────────────────────────────────
```

---

## ✨ Funcionalidades

- ✅ Instalação automatizada com **um único comando**
- ✅ Detecção automática do **dispositivo HDMI** disponível
- ✅ Detecção automática do **binário do Firefox** (`/opt` ou `/usr/bin`)
- ✅ Detecção automática da **resolução da tela** (para o clique simulado)
- ✅ Simulação de cliques com `xdotool` para **liberar autoplay**
- ✅ Criação de `user.js` no perfil do Firefox com **permissões agressivas de autoplay**
- ✅ Serviço systemd para **iniciar o kiosk no boot**
- ✅ Timer systemd para **reinício diário automático**
- ✅ Serviço de **monitoramento contínuo** do áudio
- ✅ Ativação de **linger** (funciona mesmo sem login gráfico)
- ✅ **Backup** fácil de toda a configuração

---

## 📋 Pré-requisitos

| Requisito | Detalhes |
|---|---|
| **Sistema Operacional** | Lubuntu 22.04+ (ou Ubuntu com LXQt) |
| **Firefox** | Instalado via `apt`, `snap` ou manualmente em `/opt/firefox` |
| **Sessão Gráfica** | Você precisa estar **logado na sessão gráfica** (não serve SSH/TTY puro) |
| **Conexão HDMI** | Monitor/TV **ligado** e cabo HDMI **conectado** |
| **Permissão sudo** | Necessário para instalar pacotes e ativar linger |
| **Internet** | Para baixar dependências (`pulseaudio-utils`, `xdotool`) |

> ⚠️ **Atenção:** O script **não** deve ser executado com `sudo`. Ele pede permissão de superusuário apenas quando necessário.

---

## 🚀 Como Usar

### 1. Clonar o repositório

```bash
git clone https://github.com/rivhock/firefox-kiosk-hdmi.git
cd firefox-kiosk-hdmi
```

### 2. Configurar a URL do painel

Abra o script `instalar-kiosk.sh` e edite as variáveis no topo:

```bash
vim instalar-kiosk.sh
```

Procure pelo bloco **CONFIGURAÇÃO**:

```bash
# ============ CONFIGURAÇÃO (ALTERE AQUI) ============
URL="https://endereçodasuapágina"
HORARIO_REINICIO="07:00:00"     # Formato HH:MM:SS
# ====================================================
```

Altere a `URL` e, se quiser, o `HORARIO_REINICIO`.

### 3. Executar o instalador

```bash
chmod +x instalar-kiosk.sh
./instalar-kiosk.sh
```

> ⚠️ **Sem `sudo`!** O script pedirá a senha internamente quando necessário.

### 4. Acompanhar a instalação

O script exibirá mensagens coloridas indicando cada etapa:

- `[INFO]` — Informação geral
- `[ OK ]` — Etapa concluída com sucesso
- `[AVISO]` — Aviso (não impede a execução)
- `[ERRO]` — Erro crítico (aborta o script)

Ao final, o script pergunta se você quer iniciar o Firefox para testar. Digite `s` para sim.

### 5. Verificar se está tudo funcionando

```bash
# Status do kiosk
systemctl --user status firefox-kiosk.service

# Agendamento do timer
systemctl --user list-timers --all | grep firefox

# Ver logs em tempo real
journalctl --user -u firefox-kiosk.service -f
```

---

## ⚙️ Personalização

### Alterar a URL do painel

Edite a variável `URL` no topo do `instalar-kiosk.sh` e reinstale, **ou** edite diretamente o script gerado:

```bash
vim ~/.local/bin/kiosk-start.sh
```

Procure por `URL='...'` e altere.

### Alterar o horário de reinício

```bash
vim ~/.config/systemd/user/firefox-kiosk.timer
```

Altere a linha `OnCalendar`:

```ini
OnCalendar=*-*-* 07:00:00
```

Depois recarregue:

```bash
systemctl --user daemon-reload
systemctl --user restart firefox-kiosk.timer
```

### Ajustar as coordenadas do clique simulado

O script calcula automaticamente com base na resolução da tela. Se o clique não estiver funcionando (por exemplo, caindo em um botão), edite:

```bash
vim ~/.local/bin/kiosk-start.sh
```

Procure por `xdotool mousemove` e ajuste as coordenadas.

---

## 🛠️ Solução de Problemas

Para um guia completo, consulte **[docs/SOLUCAO-DE-PROBLEMAS.md](docs/SOLUCAO-DE-PROBLEMAS.md)**.

### Problemas mais comuns

<details>
<summary><b>🔴 O áudio não sai no HDMI após reiniciar</b></summary>

**Causa:** O Firefox voltou para o dispositivo padrão do sistema após o reinício.

**Solução:**
1. Verifique o nome correto do HDMI:
   ```bash
   pactl list short sinks | grep hdmi
   ```
2. Edite `~/.local/bin/kiosk-start.sh` e atualize a variável `HDMI_SINK`.
3. Reinicie: `systemctl --user restart firefox-kiosk.service`
</details>

<details>
<summary><b>🔴 O painel não toca som, mas o YouTube funciona</b></summary>

**Causa:** Autoplay bloqueado pelo Firefox (a página usa Web Audio API sem interação do usuário).

**Solução:** O script simula cliques via `xdotool` e cria um `user.js` para liberar o autoplay. Verifique se ambos estão funcionando:
```bash
cat ~/.mozilla/firefox/*/user.js
which xdotool
```
</details>

<details>
<summary><b>🔴 Erro de arquitetura <code>armhf</code> no <code>apt</code></b></summary>

**Causa:** Alguém rodou `dpkg --add-architecture armhf` no passado.

**Solução:**
```bash
dpkg --print-foreign-architectures
dpkg -l | grep :armhf     # Se vazio, é seguro remover
sudo dpkg --remove-architecture armhf
sudo apt update
```
</details>

<details>
<summary><b>🔴 <code>Failed to connect to user scope bus</code></b></summary>

**Causa:** Você usou `sudo systemctl --user`. Esses dois não combinam.

**Solução:** Rode sem `sudo`:
```bash
systemctl --user daemon-reload
systemctl --user restart firefox-kiosk.timer
```
</details>

<details>
<summary><b>🔴 O timer não dispara no horário agendado</b></summary>

**Causa:** Linger não está ativado, ou o computador estava desligado no horário.

**Solução:**
```bash
# Ativar linger (precisa de sudo)
sudo loginctl enable-linger $USER

# Confirmar agendamento
systemctl --user list-timers --all | grep firefox

# Verificar fuso horário
timedatectl
```
</details>

---

## 📁 Estrutura do Projeto

```
firefox-kiosk-hdmi/
├── README.md                    # Este arquivo
├── LICENSE                      # Licença MIT
├── instalar-kiosk.sh            # Script de instalação automatizada
└── docs/
    └── SOLUCAO-DE-PROBLEMAS.md  # Guia detalhado de troubleshooting
```

### Arquivos gerados durante a instalação

| Arquivo | Localização | Função |
|---|---|---|
| `kiosk-start.sh` | `~/.local/bin/` | Script principal que inicia o Firefox |
| `fix-firefox-audio.sh` | `~/.local/bin/` | Monitor contínuo de áudio |
| `firefox-kiosk.service` | `~/.config/systemd/user/` | Serviço principal do kiosk |
| `firefox-restart.service` | `~/.config/systemd/user/` | Serviço de reinício |
| `firefox-kiosk.timer` | `~/.config/systemd/user/` | Agendador diário |
| `firefox-audio-fix.service` | `~/.config/systemd/user/` | Serviço do monitor de áudio |
| `user.js` | `~/.mozilla/firefox/*/` | Configurações de autoplay |

---

## ✅ Testado em

| Sistema | Firefox | Status |
|---|---|---|
| Lubuntu 22.04 LTS (x86_64) | Firefox 115+ (apt) | ✅ Funcional |
| Lubuntu 22.04 LTS (x86_64) | Firefox 130+ (`/opt/firefox`) | ✅ Funcional |
| Ubuntu 22.04 com LXQt | Firefox 115+ | ✅ Funcional |

> **Áudio:** PipeWire e PulseAudio testados com sucesso.

---

## ❓ FAQ

<details>
<summary><b>Funciona em outros sabores do Ubuntu?</b></summary>

Sim, desde que tenha sessão gráfica X11 e systemd. Testado principalmente no Lubuntu, mas deve funcionar em Xubuntu, Kubuntu e Ubuntu com LXQt.
</details>

<details>
<summary><b>Posso usar com Chromium em vez do Firefox?</b></summary>

O script foi desenhado para Firefox. O Chromium tem comportamento diferente de autoplay e políticas de kiosk. Adaptações seriam necessárias.
</details>

<details>
<summary><b>Como desinstalar tudo?</b></summary>

Execute:
```bash
systemctl --user disable --now firefox-kiosk.service firefox-kiosk.timer firefox-audio-fix.service
rm ~/.config/systemd/user/firefox-*.service ~/.config/systemd/user/firefox-*.timer
rm ~/.local/bin/kiosk-start.sh ~/.local/bin/fix-firefox-audio.sh
systemctl --user daemon-reload
```
</details>

<details>
<summary><b>Funciona em Wayland?</b></summary>

O script foi desenvolvido para X11. Em Wayland, o `xdotool` e algumas variáveis de ambiente podem não funcionar corretamente.
</details>

<details>
<summary><b>Preciso de um usuário específico?</b></summary>

O script detecta automaticamente o usuário atual. Só é necessário estar logado na sessão gráfica e ter acesso a `sudo`.
</details>

<details>
<summary><b>O que é o "linger" e por que preciso dele?</b></summary>

O `linger` faz com que os serviços do **usuário** (não do sistema) continuem rodando mesmo que você não esteja logado. Sem ele, o systemd do usuário só funciona quando a sessão está ativa.
</details>

---

## 🤝 Contribuindo

Contribuições são muito bem-vindas! Se você encontrou um bug, tem uma sugestão ou quer melhorar o projeto:

1. Faça um **Fork** do projeto
2. Crie uma **branch** para sua feature:
   ```bash
   git checkout -b feature/MinhaMelhoria
   ```
3. Faça o **commit** das mudanças:
   ```bash
   git commit -m 'Adiciona MinhaMelhoria'
   ```
4. Faça o **push** para a branch:
   ```bash
   git push origin feature/MinhaMelhoria
   ```
5. Abra um **Pull Request**

### 🐛 Reportar Bugs

Encontrou um problema? Abra uma [issue](https://github.com/rivhock/firefox-kiosk-hdmi/issues) descrevendo:

- 📋 O que você esperava que acontecesse
- ❌ O que realmente aconteceu
- 📜 Os logs relevantes:
  ```bash
  journalctl --user -u firefox-kiosk.service -n 50 --no-pager
  ```
- 💻 Sua versão do sistema:
  ```bash
  lsb_release -a
  firefox --version
  ```

---

## 📜 Licença

Este projeto está sob a **Licença MIT**. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

```
MIT License

Copyright (c) 2026 rivhock

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 💡 Motivação

Este projeto nasceu da necessidade de configurar **terminais de exibição de painéis web** em modo kiosk no Lubuntu, com áudio funcionando corretamente no HDMI e reinício automático diário.



Se este projeto te ajudou, considere dar uma ⭐ no repositório!

---

<div align="center">

 "Meu ofício é andar no mundo a galope contra o vento tirando touro a trompada e égua xucra no tento"

[⬆ Voltar ao topo](#-firefox-kiosk--áudio-hdmi)

</div>
