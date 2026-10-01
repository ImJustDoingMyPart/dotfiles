-- Estilo de sombra: Glow ceñido del color del tema
-- Mismo alcance que la sombra negra (6): `range` en px lógicos, así que en Hyprland 24 era un halo
-- gigante. `render_power 3` concentra la luz pegada al borde en vez de difuminarla.
hl.config({
    decoration = {
        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color_inactive = "rgba(00000000)",
            offset       = { 0, 0 },
        },
    },
})
