# ~/.config/zsh/.zshrc — equivalente en zsh de fish/config.fish.
#
# A propósito NO se sourcea /usr/share/cachyos-zsh-config/cachyos-config.zsh (a
# diferencia de la versión de fish, que sí sourcea su cachyos-config.fish): el
# paquete de zsh trae oh-my-zsh + Powerlevel10k como prompt fijo, que pelea con
# starship — el prompt único y consistente entre shells de este setup — y con la
# idea de "sin gestores de plugins" del resto del repo. Si la querés igual,
# sourceala ANTES de las líneas de abajo y sacá el `eval "$(starship init zsh)"`
# para no terminar con dos prompts peleando.
#
# Solo tiene sentido en familia Arch (paru para `update`), igual que la versión
# de fish — ver la sección "Qué es específico de Arch/CachyOS" del README.

# ─── Herramientas CLI ───
eval "$(zoxide init zsh --cmd __z)"
eval "$(atuin init zsh)"
eval "$(starship init zsh)"

# ─── Aliases personales ───

# `eza` a secas = árbol de 2 niveles ordenado por acceso (mismo criterio que en
# fish: las opciones se pisan de derecha a izquierda, así que `eza --level=3` o
# `eza -l` a mano siguen funcionando).
eza() {
    command eza --tree --level=2 --icons --sort=accessed "$@"
}

alias ls='eza'
# ll/la/tree usan `command eza` a propósito: mantienen el formato de siempre.
alias ll='command eza -lh --icons --group-directories-first'
alias la='command eza -a --icons --group-directories-first'
alias tree='command eza --tree --icons=auto'

if command -v bat >/dev/null; then
    alias cat='bat --paging=never'
fi

# ─── Búsqueda y navegación (fzf + zoxide) ───

alias f='fzf --height=80% --layout=reverse --border --preview="bat --color=always --style=numbers {}" --preview-window="right,60%,border-left" --bind="ctrl-o:become(micro {})"'

# z / zi: el salto de zoxide + listado del destino con un nivel de árbol.
# `zoxide init zsh --cmd __z` define __z/__zi, igual que en fish.
z() {
    __z "$@" && eza --level=1 .
}
zi() {
    __zi "$@" && eza --level=1 .
}

# ─── Utilidades rápidas ───
alias c='clear'
alias reload='source "$ZDOTDIR/.zshrc"'
alias zshconf='micro "$ZDOTDIR/.zshrc"'
# Asume familia Arch (necesita un AUR helper). En Debian/Ubuntu: 'sudo apt update
# && sudo apt upgrade'; en Fedora: 'sudo dnf upgrade'; en openSUSE: 'sudo zypper up'.
alias update='paru -Syu'

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
export PATH="$HOME/.local/bin:$PATH"
