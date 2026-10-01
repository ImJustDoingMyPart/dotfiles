-- Decoración: redondeo, desenfoque (blur) y miscelánea visual

hl.config({
    decoration = {
        rounding = 4,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        blur = {
            enabled           = true,
            size              = 4,
            passes            = 2,
            noise             = 0.02,
            vibrancy          = 0.1696,
            new_optimizations = true,
            -- Menús contextuales y tooltips de las apps (popups xdg): el mismo blur que la
            -- ventana que los abre, en vez de un rectángulo plano encima de un fondo difuso.
            popups            = true,
        },
    },

    misc = {
        disable_hyprland_logo   = true,
        disable_splash_rendering= true,
        focus_on_activate       = true,
    },

    render = {
        direct_scanout = 1,
    },
})
