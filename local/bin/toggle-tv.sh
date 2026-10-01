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

# hl.monitor() parte de la regla existente y pisa solo los campos que recibe
# (hlMonitor en src/config/lua/bindings/LuaBindingsConfigRules.cpp, v0.56.2): modo,
# posición y escala viven únicamente en cfg/monitors.lua.
#
# La confirmación es un OSD de swayosd (efímero, sin historial), no una notificación.
is_disabled=$(hyprctl -j monitors all | jq -r '.[] | select(.name == "HDMI-A-1") | .disabled')
if [[ "$is_disabled" == "true" ]]; then
    hyprctl eval 'hl.monitor({ output = "HDMI-A-1", disabled = false })'
    swayosd-client --custom-message "TV encendida" --custom-icon tv-symbolic -d 2000 >/dev/null 2>&1 || true
else
    hyprctl eval 'hl.monitor({ output = "HDMI-A-1", disabled = true })'
    swayosd-client --custom-message "TV apagada" --custom-icon tv-symbolic -d 2000 >/dev/null 2>&1 || true
fi
sleep 1
