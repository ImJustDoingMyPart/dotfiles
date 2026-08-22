#!/usr/bin/env bash
# Escalera de diagnóstico para el bajón de FPS que se arregla con Mod+Shift+T.
# Cuando pase el bajón, correr los pasos EN ORDEN y mirar los FPS después de cada uno.
# El primero que lo arregle identifica al culpable:
#
#   1  re-commit de VRR en DP-3 (sin modeset, sin tocar la lista de salidas)
#        -> si arregla: el problema está en el path de VRR / pacing de niri
#   2  modeset en DP-3 (baja a 144 Hz y vuelve a nativo, ~1 s de parpadeo)
#        -> si arregla (y el 1 no): amdgpu recalculando clocks/DPM con el modeset
#   3  toggle de la TV, lo de siempre (agrega/saca una salida del sistema)
#        -> si solo arregla este: es la lista de salidas (niri/XWayland), no DP-3
#
# Cada paso deja una marca en el log de fps-drop-log.sh para poder correlacionar.

set -u

OUT=DP-3
LOG="$HOME/.local/state/fps-drop/$(date +%F).tsv"
mkdir -p "$(dirname "$LOG")"

mark() { printf '### PASO %s: %s (%s)\n' "$1" "$2" "$(date +%H:%M:%S)" | tee -a "$LOG"; }

case "${1:-}" in
    1)
        mark 1 "re-commit VRR en $OUT"
        niri msg output "$OUT" vrr off
        sleep 1
        niri msg output "$OUT" vrr on --on-demand
        ;;
    2)
        mark 2 "modeset en $OUT (144 Hz -> auto)"
        niri msg output "$OUT" mode 1920x1080@143.981
        sleep 2
        niri msg output "$OUT" mode auto
        ;;
    3)
        mark 3 "toggle TV (HDMI-A-1)"
        "$HOME/.local/bin/toggle-tv.sh"
        ;;
    *)
        sed -n '2,13p' "$0" | sed 's/^# \?//'
        exit 1
        ;;
esac
