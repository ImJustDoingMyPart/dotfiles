-- Giro del degradé del borde al cambiar el foco.
--
-- `borderangle` anima el ÁNGULO del degradé de `general.col.active_border` (primary ->
-- tertiary a 45°). Con `style = "once"` da una vuelta completa cada vez que el borde de la
-- ventana cambia de color —o sea, al ganar el foco— y se detiene en los 45° de siempre.
-- `loop` lo haría girar sin parar: redibuja el borde en cada cuadro, a 300 Hz, aunque no
-- pase nada en pantalla, y por eso no se usa.
--
-- Se carga DESPUÉS del preset de animaciones (ver hyprland.lua) y pisa lo que el preset
-- diga de `borderangle`: la mayoría de los presets de HyDE lo apagan (`border` deshabilitado
-- lo arrastra, porque es su hijo en el árbol) o lo ponen en `loop`. Así el giro queda igual
-- con cualquier preset.
--
-- `speed` está en decisegundos: 8 = 800 ms por vuelta. La curva sale rápida y frena al
-- llegar, para que el borde se asiente en vez de pararse de golpe.

hl.curve("borde_giro", { type = "bezier", points = { { 0.33, 1 }, { 0.68, 1 } } })

hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "borde_giro", style = "once" })

-- La sombra hace lo mismo: `shadowangle` gira el degradé de `decoration.shadow.color` y lo
-- dispara el mismo cambio de foco que a `borderangle`. Con el glow (degradé primary ->
-- tertiary, como el borde) la luz gira junto con el borde; con la sombra negra, un solo
-- color, el giro no se ve.
hl.animation({ leaf = "shadowangle", enabled = true, speed = 8, bezier = "borde_giro", style = "once" })
