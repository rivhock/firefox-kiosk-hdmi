# 🛠️ Solução de Problemas

Este documento reúne os problemas mais comuns encontrados durante a instalação e uso do Firefox Kiosk, junto com suas soluções.

---

## 📑 Índice

- [Problemas de Áudio](#-problemas-de-áudio)
- [Problemas de Instalação](#-problemas-de-instalação)
- [Problemas com o Firefox](#-problemas-com-o-firefox)
- [Problemas com o systemd](#-problemas-com-o-systemd)
- [Comandos Úteis de Diagnóstico](#-comandos-úteis-de-diagnóstico)

---

## 🔴 Problemas de Áudio

### O áudio não sai no HDMI após reiniciar o Firefox

**Causa:** O Firefox volta para o dispositivo de áudio padrão do sistema após ser reiniciado, ou o autoplay está bloqueado.

**Solução:**
1. Verifique o nome correto do HDMI:
   ```bash
   pactl list short sinks | grep hdmi
