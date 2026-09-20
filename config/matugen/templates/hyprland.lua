-- Template de matugen -> ~/.config/themes/matugen/hyprland.lua
hl.config({
    general = {
        col = {
            active_border   = { colors = { "rgb({{colors.primary.default.hex_stripped}})", "rgb({{colors.tertiary.default.hex_stripped}})" }, angle = 45 },
            inactive_border = "rgba(00000000)",
        },
    },
    decoration = {
        shadow = {
            color = "rgba({{colors.primary.default.hex_stripped}}80)",
        },
    },
    group = {
        col = {
            border_active   = "rgb({{colors.primary.default.hex_stripped}})",
            border_inactive = "rgb({{colors.surface_container.default.hex_stripped}})",
        },
        groupbar = {
            col = {
                active   = "rgb({{colors.primary.default.hex_stripped}})",
                inactive = "rgb({{colors.surface_container.default.hex_stripped}})",
            },
        },
    },
    misc = {
        background_color = "0x{{colors.surface_container_lowest.default.hex_stripped}}",
    },
})
