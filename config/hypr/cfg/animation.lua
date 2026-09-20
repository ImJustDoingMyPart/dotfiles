-- Interruptor maestro de animaciones. Nada más.
--
-- Todo el contenido —curvas, leaves, tiempos— lo pone el preset activo, que es un archivo de
-- la colección de HyDE en ../animations/ enlazado desde cfg/active-animation.lua. Los presets
-- son autocontenidos: cada uno define las curvas que usa (`default` es la bezier interna de
-- Hyprland), así que este módulo no tiene que sembrar ninguna.
--
-- Acá NO se traduce nada de niri. El pack de niri —los resortes con la conversión
-- `dampening = ζ · 2 · √(stiffness · mass)`, los 200 ms de window-open— se abandonó a
-- propósito: la base son las animaciones de Hyprland tal como las escribe cada preset, con sus
-- tiempos, no los de antes. Mientras estuvo, era además código muerto: el preset redefine
-- todos los leaves y ganaba siempre (visto en `hyprctl animations`).
--
-- Si falta el symlink del preset, `hyprland.lua` lo carga con pcall y el escritorio queda con
-- las animaciones default de Hyprland, que es exactamente el fallback que se quiere.
hl.config({
    animations = {
        enabled = true,
    },
})
