#!/usr/bin/env bash
# Foto profunda del sistema en el momento de un posible bajón de FPS.
# Lo llama solo fps-drop-log.sh cuando detecta la anomalía; también se puede
# correr a mano:  fps-drop-snapshot.sh "motivo"
# Ver nota Gaming del vault.

set -u

MOTIVO="${1:-manual}"
CARD=/sys/class/drm/card1/device
OUT="$HOME/.local/state/fps-drop/snapshot-$(date +%F_%H-%M-%S).txt"

{
    echo "=== SNAPSHOT $(date '+%F %H:%M:%S')  —  motivo: $MOTIVO ==="
    echo

    echo "--- clocks y DPM (el '*' marca el nivel activo) ---"
    for f in pp_dpm_sclk pp_dpm_mclk pp_dpm_fclk pp_dpm_dcefclk pp_dpm_socclk pp_dpm_pcie; do
        echo "[$f]"; cat "$CARD/$f" 2>/dev/null
    done
    echo "power_dpm_force_performance_level: $(cat "$CARD/power_dpm_force_performance_level" 2>/dev/null)"
    echo "perfil de potencia activo: $(awk '/\*:/{sub(/\*:.*/,"",$0); print $NF}' "$CARD/pp_power_profile_mode" 2>/dev/null)"
    echo "gpu_busy_percent: $(cat "$CARD/gpu_busy_percent" 2>/dev/null)"
    echo

    echo "--- salidas según niri ---"
    niri msg --json outputs 2>/dev/null | jq '.'
    echo

    echo "--- ventanas según niri ---"
    niri msg --json windows 2>/dev/null | jq -c '.[] | {id, app_id, title, pid, is_focused}'
    echo

    # El app-id nulo de gamescope sigue sin explicación: guardamos el entorno del
    # proceso de la ventana con foco para poder diffearlo contra un lanzamiento manual.
    pid=$(niri msg --json windows 2>/dev/null | jq -r 'first(.[] | select(.is_focused)) | .pid // empty')
    if [ -n "$pid" ] && [ -r "/proc/$pid/environ" ]; then
        echo "--- entorno del proceso con foco (pid $pid) ---"
        tr '\0' '\n' < "/proc/$pid/environ" | sort
        echo
        echo "--- cmdline ---"
        tr '\0' ' ' < "/proc/$pid/cmdline"; echo
        echo
    fi

    echo "--- XWayland (lo que ven los juegos X11) ---"
    DISPLAY=:0 xrandr --current 2>/dev/null | grep -E "connected|\*"
    echo

    echo "--- últimos mensajes del kernel ---"
    journalctl -k -n 25 --no-pager 2>/dev/null
    echo

    echo "--- últimas líneas de gamescope/steam ---"
    journalctl -b -n 400 --no-pager 2>/dev/null | grep -iE "gamescope|amdgpu|drm" | tail -25
} > "$OUT" 2>&1

echo "$OUT"
