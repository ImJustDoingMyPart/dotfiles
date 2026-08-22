#!/usr/bin/env bash
# Toggle de grabación manual con GPU Screen Recorder.
# Primera pulsación: empieza a grabar el monitor activo (vídeo HW + audio de escritorio).
# Segunda pulsación: para y guarda el clip en ~/Vídeos/Grabaciones/.
# Usa su propio pidfile para NO interferir con el búfer de replay (Mod+G y compañía).

set -u

PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/gsr-manual-recording.pid"
OUTDIR="$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Vídeos")/Grabaciones"
APP="GPU Screen Recorder"

# ¿Hay ya una grabación manual viva? -> parar y guardar.
if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    PID="$(cat "$PIDFILE")"
    kill -INT "$PID"            # SIGINT = parar y guardar (modo grabación)
    rm -f "$PIDFILE"
    notify-send -a "$APP" -u normal "⏹ Grabación detenida" "Guardada en ~/Vídeos/Grabaciones/"
    exit 0
fi

# Pidfile huérfano (proceso ya muerto): limpiar.
rm -f "$PIDFILE"

# Monitor a grabar: el primero que liste GSR (se adapta si cambias de salida/TV).
MON="$(gpu-screen-recorder --list-monitors 2>/dev/null | head -1 | cut -d'|' -f1)"
MON="${MON:-DP-3}"

mkdir -p "$OUTDIR"
OUT="$OUTDIR/$(date +%Y-%m-%d_%H-%M-%S).mp4"

# Arranca en segundo plano, totalmente desacoplado de niri.
setsid gpu-screen-recorder -w "$MON" -f 60 -a default_output \
    -k hevc -q very_high -c mp4 -o "$OUT" >/dev/null 2>&1 &
echo $! > "$PIDFILE"

notify-send -a "$APP" -u low "⏺ Grabando $MON…" "Pulsa Mod+Shift+R otra vez para parar y guardar"
