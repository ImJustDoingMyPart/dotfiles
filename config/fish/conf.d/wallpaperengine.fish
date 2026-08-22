# ~/.config/fish/conf.d/wallpaperengine.fish
# ─── Toggle mínimo para Wallpaper Engine (linux-wallpaperengine, AUR) ───
#
# awww y Wallpaper Engine no pueden ocupar la capa de escritorio a la vez, así que
# "prender" WE es "apagar awww" — con `systemctl --user stop/start`, sin borrar ni
# desinstalar nada (revertible con wallpaperengine-off).
#
# --layer background + la layer-rule en cfg/rules.kdl (match namespace=
# "linux-wallpaperengine") es la combinación que documenta el propio proyecto para
# niri: https://github.com/Almamu/linux-wallpaperengine (flag --layer). Sin la
# layer-rule, la escena se clona en cada miniatura del Overview.
#
# No toca matugen, el backdrop del overview ni wallpaper-rotate: eso es lógica de
# wallpaper-set (pensada para imágenes estáticas), y WE queda fuera de ese sistema.

if set -q WALLPAPERENGINE_OUTPUT
    set -g __we_output $WALLPAPERENGINE_OUTPUT
else
    set -g __we_output DP-3
end

function wallpaperengine-on --description 'Prende un fondo de Wallpaper Engine (apaga awww)'
    set -l id $argv[1]
    if test -z "$id"
        echo "uso: wallpaperengine-on <workshop-id-o-ruta>" >&2
        return 1
    end
    systemctl --user stop awww
    systemd-run --user --unit=wallpaperengine --collect -- \
        linux-wallpaperengine --layer background --screen-root $__we_output $id
end

function wallpaperengine-off --description 'Apaga Wallpaper Engine y vuelve a awww'
    systemctl --user stop wallpaperengine 2>/dev/null
    systemctl --user start awww
end
