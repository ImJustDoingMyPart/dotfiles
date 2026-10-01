-- Gruvbox Dark Medium - Colores de Hyprland
hl.config({
    general = {
        col = {
            active_border   = { colors = { "rgb(83a598)", "rgb(d3869b)" }, angle = 45 },
            inactive_border = "rgba(00000000)",
        },
    },
    decoration = {
        shadow = {
            color = "rgba(00000070)",
        },
    },
    -- Grupos (pestañas, Mod+W). El borde es el mismo degradé que el de cualquier ventana
    -- activa, y el inactivo transparente como el resto: un grupo se reconoce por su barra de
    -- pestañas, no por un marco distinto. En la barra, la pestaña activa lleva el tinte de
    -- selección de todo el sistema (primary al 25 %, como la fila elegida de rofi y el hover
    -- de swaync) y las demás el fondo de tarjeta al 85 %, como rofi y la barra.
    group = {
        col = {
            border_active   = { colors = { "rgb(83a598)", "rgb(d3869b)" }, angle = 45 },
            border_inactive = "rgba(00000000)",
        },
        groupbar = {
            col = {
                active   = "rgba(83a59840)",
                inactive = "rgba(32302fd9)",
            },
            text_color          = "rgb(d4be98)",
            text_color_inactive = "rgb(a89984)",
        },
    },
    misc = {
        background_color = "0x1d2021",
    },
})
