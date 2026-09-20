#!/usr/bin/env bash

# Script para alternar dispositivos de audio y forzar la migración de los streams activos

# 1. Obtener la lista de nombres de sink (ej. alsa_output.pci...)
#
# DEDUPLICADO por nombre: PipeWire deja nodos ALSA duplicados con el mismo nombre y distinto
# ID cada vez que el HDMI se apaga/prende (toggle-tv.sh, Meta+Shift+T) — visto el
# 2026-09-03 con 5 nodos "hdmi-stereo-extra4" vivos a la vez (`pactl list short sinks`).
# Sin deduplicar, el ciclo se queda pegado saltando entre clones del mismo sink en vez de
# llegar a Auriculares, y la notificación de abajo repite la descripción una vez por clon.
sinks=($(pactl list short sinks | awk '!seen[$2]++{print $2}'))

if [ ${#sinks[@]} -eq 0 ]; then
    exit 1
fi

current_sink=$(pactl get-default-sink)
current_index=-1

# 2. Encontrar cuál está activo actualmente
for i in "${!sinks[@]}"; do
    if [[ "${sinks[$i]}" == "$current_sink" ]]; then
        current_index=$i
        break
    fi
done

# 3-4. Probar cada candidato en orden hasta que el servidor acepte el cambio DE VERDAD.
#
# No alcanza con calcular "el siguiente índice" y pedirle a pactl que lo setee: uno de los
# nodos duplicados (ver comentario de arriba) es un zombie — `pactl set-default-sink` lo
# acepta sin devolver error, pero `pactl get-default-sink` después sigue mostrando el
# anterior. Verificado a mano el 2026-09-03: "alsa_output.pci-0000_03_00.1.hdmi-stereo"
# (SIN el sufijo -extra4) no toma nunca, mientras que -extra4 y Auriculares sí. Como el
# cálculo de índice siempre arrancaba del mismo lugar, el ciclo quedaba pegado mostrando
# HDMI aunque el sink real nunca cambiara. Acá se avanza y se VERIFICA con
# get-default-sink; si no tomó, se prueba el siguiente candidato en vez de darlo por hecho.
next_sink=""
for (( step = 1; step <= ${#sinks[@]}; step++ )); do
    candidate=${sinks[$(( (current_index + step) % ${#sinks[@]} ))]}
    pactl set-default-sink "$candidate"
    if [[ "$(pactl get-default-sink)" == "$candidate" ]]; then
        next_sink="$candidate"
        break
    fi
done

if [[ -z $next_sink ]]; then
    echo "toggle-audio.sh: ningún sink candidato aceptó el cambio" >&2
    exit 1
fi

# 5. MUDAR TODOS LOS STREAMS ACTIVOS (juegos, música) al nuevo dispositivo
for input in $(pactl list short sink-inputs | awk '{print $1}'); do
    pactl move-sink-input "$input" "$next_sink" 2>/dev/null
done

# 6. MUDAR STREAMS DE WIREPLUMBER NATIVOS
# Hay juegos que usan ALSA/Pipewire directo y no aparecen en pactl.
# Intentamos moverlos usando pw-cli o wpctl si es posible, pero Wireplumber 
# debería manejarlos tras el cambio de default. Para asegurar, reiniciamos el nodo si es necesario,
# pero con pactl suele ser suficiente para el 99% de los casos.

# 7. Obtener nombre legible para la notificación.
#
# Match EXACTO de la línea (`$0 == "\tName: " sink`), no `~` (substring): con dos sinks
# donde uno es prefijo del otro ("...hdmi-stereo" y "...hdmi-stereo-extra4"), la regex sin
# anclar podía engancharse con el bloque equivocado. `exit` después del print: con nodos
# duplicados (ver comentario de arriba) el mismo nombre aparece varias veces en `pactl list
# sinks` y sin cortar acá la descripción se repetía una vez por cada clon.
next_name=$(pactl list sinks | awk -v sink="$next_sink" '$0 == "\tName: " sink {f=1} f && $1=="Description:" {print substr($0, index($0,$2)); exit}')

# 8. Elegir ícono según el tipo de dispositivo
icons_dir="$HOME/.local/share/icons"
case "$next_sink $next_name" in
    *hdmi*|*HDMI*)
        icon="$icons_dir/device-tv.png"
        ;;
    *[Aa]uricular*|*headset*|*headphone*)
        icon="$icons_dir/headset.png"
        ;;
    *)
        icon="$icons_dir/device-speaker.png"
        ;;
esac

# 9. Mostrar la notificación
notify-send -a "Audio" -t 2000 -i "$icon" "Salida de audio" "Cambiado a: $next_name"
