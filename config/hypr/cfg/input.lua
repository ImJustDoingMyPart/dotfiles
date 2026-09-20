-- Configuración de entrada (teclado latam, mouse, touchpad)

hl.config({
    input = {
        kb_layout = "latam",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",

        numlock_by_default = true,

        -- 0 = el cursor NO mueve el foco. Es lo que hacía niri, que no tenía
        -- focus-follows-mouse, y acá además es necesario: con `2` (detached) el enfoque por
        -- script se vuelve errático en el layout scrolling. Al enfocar una ventana el lienzo
        -- scrollea, bajo el cursor quieto queda OTRA ventana, y el foco se va ahí. Medido con
        -- run-or-cycle sobre dos kitty: con `2` el ciclo rebotaba y hasta saltaba a Brave; con
        -- `0`, cuatro pulsaciones seguidas alternan exacto entre las dos.
        follow_mouse = 0,

        sensitivity = 0,

        scroll_method = "on_button_down",
        scroll_button = 276,

        touchpad = {
            tap_to_click = true,
            natural_scroll = true,
        },
    },

    binds = {
        workspace_back_and_forth = true,
        scroll_event_delay = 300,
    },
})
