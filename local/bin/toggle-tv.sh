#!/usr/bin/env sh
# Alterna la salida HDMI-A-1 (TV) encendida/apagada en niri.
# Estado apagado: current_mode == null en `niri msg --json outputs`.

state=$(niri msg --json outputs | jq -r '."HDMI-A-1".current_mode')

if [ "$state" = "null" ]; then
    niri msg output HDMI-A-1 on
    notify-send -t 2000 -i "$HOME/.local/share/icons/device-tv.png" "TV" "Encendida"
else
    niri msg output HDMI-A-1 off
    notify-send -t 2000 -i "$HOME/.local/share/icons/device-tv-off.png" "TV" "Apagada"
fi
