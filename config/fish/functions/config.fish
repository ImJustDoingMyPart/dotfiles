# ~/.config/fish/config.fish
# ─── Migrado de Zsh — Setup minimalista ───

# Cargar la config base de CachyOS (incluye fastfetch, eza aliases, etc.)
source /usr/share/cachyos-fish-config/cachyos-config.fish

# ─── Herramientas CLI ───
# --cmd __z: zoxide define __z/__zi en vez de z/zi, y más abajo envolvemos
# esos dos con nuestras versiones que además listan el destino.
zoxide init fish --cmd __z | source
atuin init fish | source
starship init fish | source

# ─── Aliases personales (migrados de .zshrc) ───

# Sobreescribir los aliases de eza de CachyOS con los tuyos (más limpios)
#
# `eza` a secas = árbol de 2 niveles ordenado por acceso. El man de eza
# documenta este patrón: las opciones se pisan de derecha a izquierda, así que
# lo que agregues a mano gana (p. ej. `eza --level=3`, `eza -l`).
function eza --description "eza con árbol de 2 niveles por defecto"
    command eza --tree --level=2 --icons --sort=accessed $argv
end

alias ls='eza'
# ll/la/tree usan `command eza` a propósito: mantienen el formato de siempre.
alias ll='command eza -lh --icons --group-directories-first'
alias la='command eza -a --icons --group-directories-first'
# `--icons=auto` explícito: si `--icons` queda último, se come el argumento
# (`tree bin` fallaba con "invalid value 'bin' for '--icons'").
alias tree='command eza --tree --icons=auto'

# Bat como cat
if command -q bat
    alias cat='bat --paging=never'
end

# ─── Búsqueda y navegación (fzf + zoxide) ───

# Buscador con preview: Enter imprime la ruta, Ctrl+O la abre en micro.
# El walker por defecto de fzf lista solo archivos, así que bat nunca recibe
# un directorio.
alias f='fzf --height=80% --layout=reverse --border --preview="bat --color=always --style=numbers {}" --preview-window="right,60%,border-left" --bind="ctrl-o:become(micro {})"'

# z / zi: el salto de zoxide + listado del destino, con un solo nivel de árbol
# (el `--level=1` pisa el 2 del wrapper de eza).
function z --wraps __z --description "zoxide + listado del destino"
    __z $argv; and eza --level=1 .
end

function zi --wraps __zi --description "zoxide interactivo (fzf) + listado del destino"
    __zi $argv; and eza --level=1 .
end

# Utilidades rápidas
alias c='clear'
alias reload='source ~/.config/fish/config.fish'
alias fishconf='micro ~/.config/fish/config.fish'  # Antes: microconf
alias update='paru -Syu'

# Portapapeles Wayland  
# Nota: CachyOS define `copy` como función de copia de directorios.
# Usamos wcopy/wpaste para evitar conflicto.
alias wcopy='wl-copy'
alias wpaste='wl-paste'

# ─── IA / Ollama ───
alias ollama-start='cd ~/docker/ollama-ai/ && docker compose up -d'
alias ollama-stop='docker stop ollama'
alias ollama-models='docker exec -it ollama ollama list'
alias ollama-run='docker exec -it ollama ollama run'
alias ollama-pull='docker exec -it ollama ollama pull'
alias ollama-fix='echo "Reiniciando Ollama..." && docker restart ollama && sleep 3 && curl -s http://localhost:11434/api/tags > /dev/null && echo "✅ Ollama recuperado y respondiendo."'

# ─── PATH ───
set -gx PATH "/home/anon/.local/bin" $PATH
