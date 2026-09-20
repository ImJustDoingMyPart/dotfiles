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
})
