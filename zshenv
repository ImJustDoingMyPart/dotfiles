# Va en $HOME/.zshenv (install.sh lo pone ahí, no en ~/.config).
#
# zsh SIEMPRE lee ~/.zshenv primero, sin importar ZDOTDIR — es el único archivo
# que se lee de una ubicación fija, precisamente para poder redirigir el resto
# de la config a otro lado. Con esto, zsh busca .zshrc en ~/.config/zsh/ en vez
# de directamente en $HOME.
export ZDOTDIR="$HOME/.config/zsh"
