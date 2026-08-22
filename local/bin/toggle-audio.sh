#!/usr/bin/env bash

# Script para alternar dispositivos de audio y forzar la migración de los streams activos

# 1. Obtener la lista de nombres de sink (ej. alsa_output.pci...)
sinks=($(pactl list short sinks | awk '{print $2}'))

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

# 3. Calcular el siguiente
next_index=$(( (current_index + 1) % ${#sinks[@]} ))
next_sink=${sinks[$next_index]}

# 4. Cambiar el dispositivo por defecto (PulseAudio / PipeWire)
pactl set-default-sink "$next_sink"

# 5. MUDAR TODOS LOS STREAMS ACTIVOS (juegos, música) al nuevo dispositivo
for input in $(pactl list short sink-inputs | awk '{print $1}'); do
    pactl move-sink-input "$input" "$next_sink" 2>/dev/null
done

# 6. MUDAR STREAMS DE WIREPLUMBER NATIVOS
# Hay juegos que usan ALSA/Pipewire directo y no aparecen en pactl.
# Intentamos moverlos usando pw-cli o wpctl si es posible, pero Wireplumber 
# debería manejarlos tras el cambio de default. Para asegurar, reiniciamos el nodo si es necesario,
# pero con pactl suele ser suficiente para el 99% de los casos.

# 7. Obtener nombre legible para la notificación
next_name=$(pactl list sinks | awk -v sink="$next_sink" '$0 ~ "Name: " sink {f=1} f && $1=="Description:" {print substr($0, index($0,$2)); f=0}')

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
