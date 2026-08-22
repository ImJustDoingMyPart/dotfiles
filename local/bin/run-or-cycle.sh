#!/bin/bash

# run-or-cycle.sh para Niri (v1.0.0)
# Un script para lanzar o alternar entre ventanas de una aplicación por su app_id.

# Verifica que se hayan pasado los dos argumentos requeridos
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Uso: $0 <app_id> <comando_ejecucion>"
    exit 1
fi

APP_ID=$1
COMANDO=$2

# Obtenemos la información de las ventanas que coinciden con el App ID
# La estructura de Niri es un array de objetos con .id, .app_id y .is_focused
WINDOWS_JSON=$(niri msg -j windows | jq -c --arg app "$APP_ID" '.[] | select(.app_id == $app) | {id: .id, focused: .is_focused}')

# Si no hay ventanas abiertas de esa app, la lanzamos
if [ -z "$WINDOWS_JSON" ]; then
    $COMANDO &
    exit 0
fi

# Extraemos los IDs a un array de Bash
mapfile -t IDS < <(echo "$WINDOWS_JSON" | jq -r '.id')
# Buscamos el índice (1-based) de la ventana que tiene el foco actualmente
FOCUSED_INDEX=$(echo "$WINDOWS_JSON" | jq -r '.focused' | grep -n "true" | cut -d: -f1)

# Lógica de ciclo:
if [ -z "$FOCUSED_INDEX" ]; then
    # Si ninguna ventana de esta app está enfocada, vamos a la primera de la lista
    TARGET_ID=${IDS[0]}
else
    # Si ya hay una enfocada, calculamos el índice de la siguiente (ciclamos al llegar al final)
    # FOCUSED_INDEX es 1-based, así que (FOCUSED_INDEX % total) nos da el siguiente en un array 0-based
    NEXT_INDEX=$((FOCUSED_INDEX % ${#IDS[@]}))
    TARGET_ID=${IDS[$NEXT_INDEX]}
fi

# Ejecutamos la acción de foco en Niri
niri msg action focus-window --id "$TARGET_ID"
