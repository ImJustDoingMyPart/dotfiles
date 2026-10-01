-- Layout scrolling (equivalente a niri)

hl.config({
    general = {
        layout = "scrolling",
        gaps_in = 8,
        gaps_out = 16,
        border_size = 2,
    },

    scrolling = {
        focus_fit_method = 1, -- 1: fit, 0: center
        explicit_column_widths = "0.333, 0.5, 0.667",
        fullscreen_on_one_column = false,
        wrap_swapcol = false,
        -- Sin esto, el foco (hl.dsp.focus) envuelve entre las columnas VISIBLES en vez de
        -- seguir scrolleando el lienzo — niri nunca envuelve en focus-column-left/right.
        wrap_focus = false,
    },

    -- ─── Grupos: varias ventanas apiladas en pestañas dentro de una sola columna ───
    --
    -- Cómo se usan (con los defaults de `group:*` de la 0.56.2, `hyprctl descriptions`):
    --   - Mod+W convierte la ventana enfocada en un grupo (de una pestaña). Mod+W sobre un
    --     grupo lo deshace y las ventanas vuelven a ser columnas sueltas.
    --   - Con el foco en el grupo, toda ventana que se abra entra como pestaña nueva
    --     (`auto_group`), justo después de la actual (`insert_after_current`). Para abrir una
    --     ventana suelta, primero enfocá otra columna.
    --   - Cambiar de pestaña: click en la pestaña, o la rueda sobre la barra (`scrolling`).
    --     Click del medio sobre una pestaña cierra esa ventana (`middle_click_close`).
    --   - El resto de los atajos (Mod+Q, Mod+F, mover columna) actúan sobre la pestaña o la
    --     columna del grupo como sobre cualquier otra.
    --
    -- Los colores de la barra y del borde del grupo son del tema (theme-colors.lua); acá va
    -- la forma, con las medidas del resto del sistema: radio 4 y JetBrainsMono.
    group = {
        groupbar = {
            font_family      = "JetBrainsMono Nerd Font",
            font_size        = 10,
            height           = 18,
            -- `gradients` es lo que pinta cada pestaña como una caja con fondo; sin él solo
            -- existe la rayita indicadora. La rayita se apaga: el tinte de la pestaña activa
            -- ya dice cuál es, y las dos juntas repetirían el mismo color.
            gradients        = true,
            indicator_height = 0,
            gradient_rounding          = 4,
            gradient_round_only_edges  = false,
            rounding                   = 4,
            round_only_edges           = false,
            gaps_in          = 4,
            -- El fondo de las pestañas es translúcido (alfa 0,85, el de rofi y la barra):
            -- con blur se lee con la misma textura que ellos.
            blur             = true,
        },
    },
})
