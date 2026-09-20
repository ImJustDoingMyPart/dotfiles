-- Reglas de ventana y capas (layer-shell)

-- Regla general de opacidad
hl.window_rule({
    name    = "general-opacity",
    match   = { class = ".+" },
    opacity = "0.95",
})

-- Apps con fondo/transparencia propia
hl.window_rule({
    name    = "kitty-opacity",
    match   = { class = "^kitty$" },
    opacity = "1.0 override 1.0 override",
})

hl.window_rule({
    name    = "yazi-opacity",
    match   = { class = "^yazi$" },
    opacity = "1.0 override 1.0 override",
})

-- Juegos: pantalla completa, opacos y en su propio workspace (el 10, Mod+0).
--
-- El workspace propio es lo que hace fluido salir del juego. Con `misc.on_focus_under_fullscreen`
-- en su default (2, "exit_fullscreen" según `hyprctl descriptions`), enfocar otra ventana del
-- MISMO workspace saca al juego de pantalla completa: gamescope se redimensiona, se pierde el
-- direct scanout y al volver hay que re-maximizarlo. Con el juego solo en el 10, cualquier
-- atajo de app cambia de workspace, el juego queda intacto, y `Mod+0` (o el back-and-forth)
-- vuelve a él.
--
-- `idle_inhibit = "fullscreen"`: jugando con joystick no hay input de teclado ni mouse, y sin
-- esto hypridle apagaría la pantalla a los 10 minutos. Doc: wiki 0.56, Window Rules.
hl.window_rule({
    name         = "steam-games",
    match        = { class = "^steam_app_\\d+$" },
    workspace    = "10",
    fullscreen   = true,
    idle_inhibit = "fullscreen",
    opacity      = "1.0 override 1.0 override",
})

hl.window_rule({
    name         = "gamescope",
    match        = { class = "^gamescope$" },
    workspace    = "10",
    fullscreen   = true,
    idle_inhibit = "fullscreen",
    opacity      = "1.0 override 1.0 override",
})

-- Ventanas sin class. En Hyprland gamescope SÍ trae class (verificado en vivo: la ventana
-- llega como `gamescope` y pide pantalla completa ella misma, `fullscreenClient = 2`), así que
-- esta regla ya no es la que atiende a los juegos: queda de red por si Steam le rompe el app-id
-- como hacía bajo niri.
--
-- NO lleva `fullscreen = true`: bajo Hyprland el matcher de class vacía cae sobre cualquier
-- cliente que no declare app-id —vkcube y glxgears por XWayland, entre otros— y los abría a
-- pantalla completa sin pedirlo. Lo único que hace falta acá es la opacidad.
hl.window_rule({
    name    = "empty-class",
    match   = { class = "^$" },
    opacity = "1.0 override 1.0 override",
})

-- mpv siempre flotante
hl.window_rule({
    name  = "mpv-floating",
    match = { class = "^mpv$" },
    float = true,
})

-- Notificaciones de Steam (toasts)
hl.window_rule({
    name             = "steam-notifications",
    match            = { class = "^steam$", title = "^notificationtoasts_\\d+_desktop$" },
    float            = true,
    move             = "monitor_w-window_w-10 monitor_h-window_h-10",
    no_initial_focus = true,
})

-- Cualquier ventana a pantalla completa, opaca. La regla general de arriba le pone alfa a TODO
-- lo que tenga class, y una ventana con alfa < 1 no es candidata a `solitary`: el compositor
-- pierde el direct scanout y compone cada frame. Medido con mpv a pantalla completa —con la
-- regla general sola, `hyprctl monitors` dice `solitaryBlockedBy: not opaque`; con esta regla,
-- `solitaryBlockedBy: null` y `directScanoutTo` apunta a la ventana.
--
-- Va última a propósito: gana la última que matchea.
--
-- El matcher `fullscreen` no distingue modo (probado: una regla escrita con `fullscreen = 1`
-- aplicó sobre una ventana en modo 2), así que alcanza también a la columna maximizada de
-- Mod+F. En maximizado no hay nada que ganar —hay barra, bordes y gaps, nunca es solitary—,
-- solo el cambio de que deja de verse translúcida.
hl.window_rule({
    name    = "fullscreen-opaco",
    match   = { fullscreen = true },
    opacity = "1.0 override 1.0 override",
})

-- ─── Reglas de capas (layer-rules) ───
hl.layer_rule({
    name         = "rofi-blur",
    match        = { namespace = "^rofi$" },
    blur         = true,
    xray         = false,
    ignore_alpha = 0.5,
})

-- La barra lleva el mismo blur que las ventanas, para que su fondo translúcido tenga la
-- misma textura en vez de ser una franja plana. Sin `ignore_alpha`: la superficie mide
-- exactamente lo que la barra, no hay velo que excluir, y el alfa del fondo varía por tema
-- (style.css lo baja con `alpha()` sobre el de cada tema).
hl.layer_rule({
    name  = "waybar-blur",
    match = { namespace = "^waybar$" },
    blur  = true,
    xray  = false,
})

-- Entrada/salida por defecto de rofi: cae desde arriba hacia su posición (centrada). Pisa
-- el `popin` del preset activo para este namespace puntual.
hl.layer_rule({
    name      = "rofi-anim",
    match     = { namespace = "^rofi$" },
    animation = "slide top",
})

-- El menú de configuración (rofi) baja al saltar al selector de fondos y sube al volver;
-- en cualquier otro momento, rofi usa `rofi-anim` (arriba). Todo rofi comparte namespace
-- ("rofi" está fijo en el fuente de rofi 2.0.0, wayland/display.c: drun, calc, el menú) y
-- las layer rules solo matchean por namespace, así que no hay regla estática que distinga
-- "el menú durante el salto".
--
-- Por eso la regla nace APAGADA y se prende solo alrededor del salto, con `hyprctl eval`,
-- que comparte este estado Lua: la prende system-index antes de lanzar el selector (y el
-- selector antes de reabrir el menú), y la apaga el selector unos 0,6 s después, cuando
-- el menú ya terminó de animarse. Funciona porque Hyprland lee el estilo de la capa en el
-- momento de abrirla y de cerrarla (LayerSurfaceAnimationController,
-- animateIn/animateOut), y `set_enabled()` reaplica las reglas en vivo (updateAllRules).
--
-- El global `_G` es a propósito: sin él, el handle no es alcanzable desde `eval`.
_G.rofi_fondos_anim = hl.layer_rule({
    name      = "rofi-fondos-slide",
    match     = { namespace = "^rofi$" },
    animation = "slide bottom",
    enabled   = false,
})

-- El selector de fondos (~/.local/bin/fondos-selector, GTK4 sobre layer-shell) tiene
-- namespace propio, así que su animación es una regla fija: entra y sale por abajo. El
-- blur con ignore_alpha es el mismo que tenía la banda cuando era de rofi: difumina lo
-- que hay detrás de la banda translúcida (alfa 0,85, el fondo de Waybar).
hl.layer_rule({
    name         = "fondos-selector",
    match        = { namespace = "^fondos-selector$" },
    animation    = "slide bottom",
    blur         = true,
    xray         = false,
    ignore_alpha = 0.5,
})

-- `blur` + `ignore_alpha` es lo que hace acá el trabajo: la capa cubre toda la pantalla
-- (`layer-shell-cover-screen: true`) y el umbral recorta el desenfoque al panel, que es lo
-- único con alfa suficiente.
--
-- `animation` NO tiene efecto con la capa cubriendo la pantalla: lo que se ve al abrir es
-- el reveal interno de GTK, no la capa. Se deja escrita porque es la que corresponde si
-- alguna vez se vuelve a `layer-shell-cover-screen: false` — con la capa del tamaño del
-- panel, esto lo hace caer desde arriba como una cortina. El precio de volver es que el
-- panel deja de adaptar su alto mientras está abierto (ver la nota Apariencia): la capa
-- se dimensiona al mapearse, y desplegar un grupo o recibir una notificación ya no lo
-- agranda hasta cerrarlo y abrirlo.
hl.layer_rule({
    name         = "swaync-control-center-blur",
    match        = { namespace = "^swaync-control-center$" },
    animation    = "slide top",
    blur         = true,
    xray         = false,
    ignore_alpha = 0.5,
})

-- El toast lleva el blur de rofi. `ignore_alpha` es imprescindible acá: la superficie es
-- una columna de todo el alto de la pantalla, y sin el umbral se difuminaría entera. La
-- sombra chica del toast (alfa 0,45) queda por debajo del umbral y tampoco se difumina.
hl.layer_rule({
    name         = "swaync-notification",
    match        = { namespace = "^swaync-notification-window$" },
    no_anim      = true,
    blur         = true,
    xray         = false,
    ignore_alpha = 0.5,
})
