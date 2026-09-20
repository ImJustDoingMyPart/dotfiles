#!/usr/bin/env bash
# Alterna la salida HDMI-A-1 (TV) encendida/apagada.
set -euo pipefail

# Throttle de 1 segundo con flock: conectar y desconectar una salida a ritmo de tecla
# crashea Waybar (ver [[La barra (Waybar)]]). Va acá y no en el bind para proteger a
# cualquier llamador, no solo a Mod+Shift+T.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/toggle-tv.lock"
if ! flock -n 9; then
    exit 0
fi

is_disabled=$(hyprctl -j monitors all | jq -r '.[] | select(.name == "HDMI-A-1") | .disabled')
if [[ "$is_disabled" == "true" ]]; then
    hyprctl eval 'hl.monitor({ output = "HDMI-A-1", disabled = false, mode = "1920x1080@60", position = "0x-1080", scale = 1 })'
    notify-send -t 2000 -i "$HOME/.local/share/icons/device-tv.png" "TV" "Encendida"
else
    hyprctl eval 'hl.monitor({ output = "HDMI-A-1", disabled = true, mode = "1920x1080@60", position = "0x-1080", scale = 1 })'
    notify-send -t 2000 -i "$HOME/.local/share/icons/device-tv-off.png" "TV" "Apagada"
fi
sleep 1
