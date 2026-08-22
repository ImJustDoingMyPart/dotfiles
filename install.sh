#!/usr/bin/env bash
# Instala esta config en ~/.config, ~/.local/bin y ~/.zshenv.
#
# Por defecto symlinkea (así un `git pull` en este repo actualiza la config en
# caliente, y podés editar en ~/.config y commitear desde ahí). Con --copy
# copia los archivos en vez de symlinkearlos.
#
# Todo lo que ya exista en destino se mueve a un backup con timestamp antes de
# reemplazarlo — no se pisa nada en silencio.
#
# Alcance: familia Arch (Arch, CachyOS, Manjaro, EndeavourOS...). Este script en
# sí no le pide nada a pacman —es bash puro, corre en cualquier lado— pero varias
# de las piezas que instala sí asumen Arch (el alias `update`, la entrada
# "Paquetes de Arch" del launcher, `desktop-orphans` con `pacman -Qo`, y
# fish/config.fish que además pide específicamente CachyOS en una línea). Cada
# uno de esos puntos tiene, al lado, un comentario con el equivalente manual
# para Debian/Fedora/openSUSE — ver también la sección "Qué es específico de
# Arch/CachyOS" del README.
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

# zsh SIEMPRE lee ~/.zshenv de esa ruta fija (no de ZDOTDIR) — por eso va aparte
# del loop de config/ y no dentro de config/zsh/, que sí sigue la regla general
# y termina en ~/.config/zsh/.
echo "-> zshenv en ~/.zshenv (fish no necesita este paso)"
place "$REPO_DIR/zshenv" "$HOME/.zshenv"

# niri (spawn) y matugen no expanden $HOME: algunos archivos traen la ruta
# absoluta de la máquina original. Se adapta al usuario real acá.
if [[ "$HOME" != "/home/anon" ]]; then
    echo "-> adaptando rutas /home/anon a $HOME"
    if [[ "$MODE" == link ]]; then
        targets=("$REPO_DIR/config/matugen/config.toml" "$REPO_DIR/config/niri/cfg/keybinds.kdl" "$REPO_DIR/config/fastfetch/config.jsonc" "$REPO_DIR/config/hypr/hyprlock.conf")
    else
        targets=("$HOME/.config/matugen/config.toml" "$HOME/.config/niri/cfg/keybinds.kdl" "$HOME/.config/fastfetch/config.jsonc" "$HOME/.config/hypr/hyprlock.conf")
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
echo "  - Incluye fish/ Y zsh/ — usá el que tengas como shell, el otro no molesta"
echo "  - Si no estás en Arch/CachyOS: revisar la sección del README sobre"
echo "    fish/config.fish, zsh/.zshrc, el alias 'update' y desktop-orphans"
