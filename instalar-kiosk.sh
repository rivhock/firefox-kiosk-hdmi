#!/bin/bash
# =============================================================
# Firefox Kiosk + Áudio HDMI
# =============================================================
# Instalador automatizado para terminais de exibição em modo kiosk
#
# Copyright (c) 2026 rivhock
# Licenciado sob a MIT License.
# Veja o arquivo LICENSE para mais informações.
#
# Repositório: https://github.com/rivhock/firefox-kiosk-hdmi
# =============================================================

set -e

# ============ CONFIGURAÇÃO (ALTERE AQUI) ============
URL="https://urldoseusite.aqui.....
HORARIO_REINICIO="07:00:00"     # Formato HH:MM:SS
# ====================================================

# ---- Cores ----
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${AZUL}[INFO]${NC} $1"; }
ok()   { echo -e "${VERDE}[ OK ]${NC} $1"; }
aviso(){ echo -e "${AMARELO}[AVISO]${NC} $1"; }
erro() { echo -e "${VERMELHO}[ERRO]${NC} $1"; exit 1; }

# ---- 1. Detectar ambiente ----
USER_NAME=$(whoami)
USER_ID=$(id -u)
HOME_DIR="/home/${USER_NAME}"
XAUTH="${HOME_DIR}/.Xauthority"

echo ""
echo "===================================================="
echo " INSTALADOR FIREFOX KIOSK + ÁUDIO HDMI"
echo "===================================================="
log "Usuário:    ${USER_NAME}"
log "UID:        ${USER_ID}"
log "Home:       ${HOME_DIR}"
log "URL:        ${URL}"
log "Reinício:   ${HORARIO_REINICIO}"
echo ""

# ---- 2. Verificar XAUTHORITY ----
if [ ! -f "${XAUTH}" ]; then
    aviso "XAUTHORITY não encontrado em ${XAUTH}, procurando alternativa..."
    ALT=$(find "${HOME_DIR}" -maxdepth 2 -name ".Xauthority" 2>/dev/null | head -n1)
    if [ -n "$ALT" ]; then
        XAUTH="$ALT"
        ok "Encontrado em: ${XAUTH}"
    else
        erro "XAUTHORITY não encontrado. Faça login na sessão gráfica primeiro."
    fi
fi
ok "XAUTHORITY: ${XAUTH}"

# ---- 3. Instalar dependências ----
log "Instalando dependências (pulseaudio-utils, xdotool)..."
sudo apt update -qq 2>/dev/null || true
sudo apt install -y pulseaudio-utils xdotool 2>/dev/null || true
ok "Dependências instaladas"

# ---- 4. Detectar HDMI ----
log "Detectando saída HDMI..."
HDMI_SINK=$(DISPLAY=:0 XAUTHORITY="${XAUTH}" pactl list short sinks 2>/dev/null \
    | awk '{print $2}' | grep -i "hdmi" | head -n1)

if [ -z "$HDMI_SINK" ]; then
    erro "Nenhuma saída HDMI encontrada. Verifique o cabo e o monitor ligado."
fi
ok "HDMI: ${HDMI_SINK}"

# ---- 5. Detectar Firefox ----
if [ -x "/opt/firefox/firefox" ]; then
    FIREFOX_BIN="/opt/firefox/firefox"
elif [ -x "/usr/bin/firefox" ]; then
    FIREFOX_BIN="/usr/bin/firefox"
elif command -v firefox >/dev/null 2>&1; then
    FIREFOX_BIN=$(command -v firefox)
else
    erro "Firefox não encontrado. Instale antes de continuar."
fi
ok "Firefox: ${FIREFOX_BIN}"

# ---- 6. Detectar resolução ----
RESOLUTION=$(DISPLAY=:0 XAUTHORITY="${XAUTH}" xrandr 2>/dev/null \
    | grep " connected" | grep -oP '\d+x\d+' | head -n1)
if [ -z "$RESOLUTION" ]; then
    aviso "Não detectou resolução, usando 1920x1080"
    WIDTH=1920; HEIGHT=1080
else
    WIDTH=$(echo "$RESOLUTION" | cut -dx -f1)
    HEIGHT=$(echo "$RESOLUTION" | cut -dx -f2)
fi
CLICK_X=$((WIDTH / 2))
CLICK_Y=$((HEIGHT / 2))
CORNER_X=$((WIDTH - 20))
CORNER_Y=$((HEIGHT - 30))
ok "Resolução: ${WIDTH}x${HEIGHT} (clique em ${CLICK_X},${CLICK_Y})"

# ---- 7. Criar pasta ~/.local/bin ----
mkdir -p "${HOME_DIR}/.local/bin"

# ---- 8. Criar kiosk-start.sh ----
log "Criando kiosk-start.sh..."
cat > "${HOME_DIR}/.local/bin/kiosk-start.sh" <<EOF
#!/bin/bash

export DISPLAY=:0
export XAUTHORITY=${XAUTH}
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${USER_ID}/bus
export XDG_RUNTIME_DIR=/run/user/${USER_ID}

HDMI_SINK='${HDMI_SINK}'
URL='${URL}'

sleep 5
pactl set-default-sink "\$HDMI_SINK"

${FIREFOX_BIN} --kiosk "\$URL" &
FIREFOX_PID=\$!

sleep 20

xdotool mousemove ${CLICK_X} ${CLICK_Y}
xdotool click 1
sleep 1
xdotool click 1
sleep 1
xdotool click 1
xdotool mousemove ${CORNER_X} ${CORNER_Y}

for i in 1 2 3; do
    pactl list sink-inputs 2>/dev/null | awk '
        /^Sink Input #[0-9]+/ { id = \$3; gsub("#","",id) }
        /application.name = ".*[Ff]irefox.*"/ { print id }
    ' | while read -r input_id; do
        if [ -n "\$input_id" ]; then
            echo "\$(date '+%H:%M:%S') - [tentativa \$i] Movendo sink-input #\$input_id para HDMI"
            pactl move-sink-input "\$input_id" "\$HDMI_SINK" 2>/dev/null
        fi
    done
    sleep 3
done

while kill -0 \$FIREFOX_PID 2>/dev/null; do
    pactl list sink-inputs 2>/dev/null | awk '
        /^Sink Input #[0-9]+/ { id = \$3; gsub("#","",id) }
        /application.name = ".*[Ff]irefox.*"/ { print id }
    ' | while read -r input_id; do
        if [ -n "\$input_id" ]; then
            pactl move-sink-input "\$input_id" "\$HDMI_SINK" 2>/dev/null
        fi
    done
    sleep 5
done
EOF
chmod +x "${HOME_DIR}/.local/bin/kiosk-start.sh"
ok "kiosk-start.sh criado"

# ---- 9. Criar pasta systemd ----
mkdir -p "${HOME_DIR}/.config/systemd/user"

# ---- 10. firefox-kiosk.service ----
log "Criando firefox-kiosk.service..."
cat > "${HOME_DIR}/.config/systemd/user/firefox-kiosk.service" <<EOF
[Unit]
Description=Firefox em modo kiosk
After=graphical-session.target

[Service]
Type=simple
Environment=DISPLAY=:0
Environment=XAUTHORITY=${XAUTH}
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${USER_ID}/bus
Environment=XDG_RUNTIME_DIR=/run/user/${USER_ID}
ExecStartPre=/bin/bash -c 'pkill -KILL firefox || true; sleep 2'
ExecStart=${HOME_DIR}/.local/bin/kiosk-start.sh
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF
ok "firefox-kiosk.service criado"

# ---- 11. firefox-restart.service ----
log "Criando firefox-restart.service..."
cat > "${HOME_DIR}/.config/systemd/user/firefox-restart.service" <<EOF
[Unit]
Description=Reiniciar o Firefox Kiosk

[Service]
Type=oneshot
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${USER_ID}/bus
ExecStart=/usr/bin/systemctl --user restart firefox-kiosk.service
EOF
ok "firefox-restart.service criado"

# ---- 12. firefox-kiosk.timer ----
log "Criando firefox-kiosk.timer..."
cat > "${HOME_DIR}/.config/systemd/user/firefox-kiosk.timer" <<EOF
[Unit]
Description=Reinicia o Firefox kiosk todo dia às ${HORARIO_REINICIO}

[Timer]
OnCalendar=*-*-* ${HORARIO_REINICIO}
Persistent=true
Unit=firefox-restart.service

[Install]
WantedBy=timers.target
EOF
ok "firefox-kiosk.timer criado"

# ---- 13. fix-firefox-audio.sh + service ----
log "Criando monitor de áudio..."
cat > "${HOME_DIR}/.local/bin/fix-firefox-audio.sh" <<EOF
#!/bin/bash

export DISPLAY=:0
export XAUTHORITY=${XAUTH}
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${USER_ID}/bus
export XDG_RUNTIME_DIR=/run/user/${USER_ID}

HDMI_SINK='${HDMI_SINK}'

while true; do
    HDMI_INDEX=\$(pactl list short sinks | grep "\$HDMI_SINK" | awk '{print \$1}')
    if [ -n "\$HDMI_INDEX" ]; then
        pactl list sink-inputs 2>/dev/null | awk '
            /^Sink Input #[0-9]+/ { id = \$3; gsub("#","",id) }
            /application.name = ".*[Ff]irefox.*"/ { print id }
        ' | while read -r input_id; do
            if [ -n "\$input_id" ]; then
                pactl move-sink-input "\$input_id" "\$HDMI_INDEX" 2>/dev/null
            fi
        done
    fi
    sleep 5
done
EOF
chmod +x "${HOME_DIR}/.local/bin/fix-firefox-audio.sh"

cat > "${HOME_DIR}/.config/systemd/user/firefox-audio-fix.service" <<EOF
[Unit]
Description=Monitor de audio do Firefox para HDMI
After=graphical-session.target

[Service]
Type=simple
Environment=DISPLAY=:0
Environment=XAUTHORITY=${XAUTH}
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${USER_ID}/bus
Environment=XDG_RUNTIME_DIR=/run/user/${USER_ID}
ExecStart=${HOME_DIR}/.local/bin/fix-firefox-audio.sh
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF
ok "Monitor de áudio criado"

# ---- 14. Limpar \r ----
sed -i 's/\r$//' "${HOME_DIR}/.config/systemd/user/firefox-kiosk.service"
sed -i 's/\r$//' "${HOME_DIR}/.config/systemd/user/firefox-restart.service"
sed -i 's/\r$//' "${HOME_DIR}/.config/systemd/user/firefox-kiosk.timer"
sed -i 's/\r$//' "${HOME_DIR}/.config/systemd/user/firefox-audio-fix.service"

# ---- 15. Criar user.js no perfil do Firefox ----
log "Configurando autoplay no Firefox..."
PROFILE_DIR=$(ls -d "${HOME_DIR}/.mozilla/firefox/"*.default* 2>/dev/null | head -n1)

if [ -z "$PROFILE_DIR" ]; then
    aviso "Perfil do Firefox não encontrado. Rode o Firefox uma vez e execute este script de novo."
else
    log "Perfil: ${PROFILE_DIR}"
    cat > "${PROFILE_DIR}/user.js" <<EOF
// ===== AUTOPLAY =====
user_pref("media.autoplay.default", 0);
user_pref("media.autoplay.blocking_policy", 0);
user_pref("media.autoplay.block-event.enabled", false);
user_pref("media.autoplay.allow-extension-background-pages", true);
user_pref("media.autoplay.block-webaudio", false);
user_pref("media.block-autoplay-until-in-foreground", false);
user_pref("media.autoplay.allow-muted", true);

// ===== WEB AUDIO API =====
user_pref("media.webaudio.enabled", true);
user_pref("dom.webaudio.enabled", true);

// ===== NOTIFICAÇÕES =====
user_pref("dom.push.enabled", true);
user_pref("permissions.default.desktop-notification", 1);

// ===== FORÇA BRUTA =====
user_pref("media.autoplay.enabled.user-gestures-needed", false);
user_pref("media.autoplay.ask-permission", false);
user_pref("media.autoplay.test-utils.enable", true);
user_pref("media.autoplay.test-utils.force-enabled", true);
EOF
    ok "user.js criado em ${PROFILE_DIR}"
fi

# ---- 16. Ativar linger ----
log "Ativando linger (sudo)..."
sudo loginctl enable-linger "${USER_NAME}"
ok "Linger ativado"

# ---- 17. Ativar serviços ----
log "Ativando serviços systemd..."
systemctl --user daemon-reload
systemctl --user enable --now firefox-kiosk.service
systemctl --user enable --now firefox-kiosk.timer
systemctl --user enable --now firefox-audio-fix.service
ok "Serviços ativados"

# ---- 18. Resumo ----
echo ""
echo "===================================================="
echo -e "${VERDE}✅ INSTALAÇÃO CONCLUÍDA!${NC}"
echo "===================================================="
echo "Usuário:       ${USER_NAME}"
echo "UID:           ${USER_ID}"
echo "Firefox:       ${FIREFOX_BIN}"
echo "HDMI Sink:     ${HDMI_SINK}"
echo "URL:           ${URL}"
echo "Reinício:      ${HORARIO_REINICIO}"
echo "Resolução:     ${WIDTH}x${HEIGHT}"
echo "Clique xdotool: ${CLICK_X},${CLICK_Y}"
echo "===================================================="
echo ""
echo "Verificar timer:  systemctl --user list-timers --all | grep firefox"
echo "Testar agora:     systemctl --user start firefox-restart.service"
echo "Ver logs:         journalctl --user -u firefox-kiosk.service -f"
echo ""

# ---- 19. Teste opcional ----
read -p "Deseja iniciar o Firefox kiosk agora? (s/n) " RESP
if [[ "$RESP" =~ ^[Ss]$ ]]; then
    log "Iniciando Firefox kiosk..."
    systemctl --user restart firefox-kiosk.service
    ok "Aguarde ~30s e verifique o som no HDMI."
fi
