#!/usr/bin/env bash
# Instala esta config en ~/.config y ~/.local/bin.
#
# Por defecto symlinkea (así un `git pull` en este repo actualiza la config en
# caliente, y podés editar en ~/.config y commitear desde ahí). Con --copy
# copia los archivos en vez de symlinkearlos.
#
# Todo lo que ya exista en destino se mueve a un backup con timestamp antes de
# reemplazarlo — no se pisa nada en silencio.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE=link
[[ "${1:-}" == "--copy" ]] && MODE=copy

BACKUP_DIR="$HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
backed_up=0

# place SRC DST — symlinkea o copia SRC a DST, respaldando lo que hubiera antes.
place() {
    local src="$1" dst="$2"
    if [[ -e "$dst" || -L "$dst" ]]; then
        if [[ "$MODE" == link && "$(readlink -f "$dst" 2>/dev/null)" == "$(readlink -f "$src")" ]]; then
            return  # ya instalado, nada que hacer
        fi
        mkdir -p "$BACKUP_DIR/$(dirname "${dst#"$HOME"/}")"
        mv "$dst" "$BACKUP_DIR/${dst#"$HOME"/}"
        backed_up=1
    fi
    mkdir -p "$(dirname "$dst")"
    if [[ "$MODE" == link ]]; then
        ln -s "$src" "$dst"
    else
        cp -r "$src" "$dst"
    fi
}

echo "Modo: $MODE"

echo "-> config/ en ~/.config"
for path in "$REPO_DIR"/config/*; do
    name="$(basename "$path")"
    [[ "$name" == "weather-location.example" ]] && continue
    place "$path" "$HOME/.config/$name"
done

echo "-> local/bin/ en ~/.local/bin"
mkdir -p "$HOME/.local/bin"
for path in "$REPO_DIR"/local/bin/*; do
    name="$(basename "$path")"
    place "$path" "$HOME/.local/bin/$name"
    chmod +x "$HOME/.local/bin/$name" 2>/dev/null || true
done

# niri (spawn) y matugen no expanden $HOME: algunos archivos traen la ruta
# absoluta de la máquina original. Se adapta al usuario real acá.
if [[ "$HOME" != "/home/anon" ]]; then
    echo "-> adaptando rutas /home/anon a $HOME"
    if [[ "$MODE" == link ]]; then
        targets=("$REPO_DIR/config/matugen/config.toml" "$REPO_DIR/config/niri/cfg/keybinds.kdl" "$REPO_DIR/config/fastfetch/config.jsonc")
    else
        targets=("$HOME/.config/matugen/config.toml" "$HOME/.config/niri/cfg/keybinds.kdl" "$HOME/.config/fastfetch/config.jsonc")
    fi
    for f in "${targets[@]}"; do
        [[ -f "$f" ]] && sed -i "s#/home/anon#$HOME#g" "$f"
    done
fi

[[ -f "$HOME/.config/weather-location" ]] || cp "$REPO_DIR/config/weather-location.example" "$HOME/.config/weather-location"

echo
if [[ $backed_up -eq 1 ]]; then
    echo "Config previa respaldada en: $BACKUP_DIR"
fi
echo "Listo. Pendiente a mano:"
echo "  - Coordenadas reales en ~/.config/weather-location"
echo "  - Instalar las dependencias listadas en el README"
echo "  - Si no estás en Arch/CachyOS: revisar la sección del README sobre"
echo "    fish/config.fish, el alias 'update' y los scripts que usan pacman"
