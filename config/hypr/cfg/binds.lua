-- Atajos de teclado para Hyprland (0.56.2)
local mod = "SUPER"

-- ─── Registro de acciones por descripción ───
--
-- Todo bind pasa por `bind()` y no por `hl.bind()` directo, para que su acción quede
-- alcanzable por nombre. Hace falta porque no hay otra forma de disparar un bind desde afuera:
--   - `hyprctl binds` reporta `dispatcher: "__lua"` para todo bind escrito con hl.bind(): la
--     acción real no se recupera por IPC.
--   - `hl.dsp.send_shortcut` (y `wtype`) le mandan la tecla a la VENTANA enfocada, no al matcher
--     de binds. Probado: Mod+2 por send_shortcut no cambia de workspace, y el "2" le llega a la
--     terminal que tiene el foco.
-- La hoja de atajos de system-index ejecuta `hyprctl eval "_G.ejecutar_bind('<descripción>')"`,
-- que corre en este mismo estado Lua. Sirve también para probar un bind sin tocar el teclado.
_G.acciones_bind = {}

local function bind(keys, action, opts)
    if opts and opts.desc then
        _G.acciones_bind[opts.desc] = action
    end
    return hl.bind(keys, action, opts)
end

function _G.ejecutar_bind(desc)
    local accion = _G.acciones_bind[desc]
    if accion then
        hl.dispatch(accion)
    end
end

local function toggle_rofi(cmd)
    return 'pgrep -x rofi >/dev/null && pkill -x rofi || ' .. cmd
end

-- ─── Menús y Lanzadores (Rofi) ───
bind(mod .. " + space", hl.dsp.exec_cmd(toggle_rofi("rofi -show drun")), { desc = "Launcher" })
bind(mod .. " + ALT + equal", hl.dsp.exec_cmd(toggle_rofi("rofi -show calc -modi calc")), { desc = "Calculadora" })
bind(mod .. " + X", hl.dsp.exec_cmd(toggle_rofi("rofi -show powermenu -modes powermenu:rofi-power-menu")), { desc = "Power Menu" })
bind(mod .. " + ALT + U", hl.dsp.exec_cmd(toggle_rofi("rofimoji")), { desc = "Símbolos/Unicode" })
bind(mod .. " + V", hl.dsp.exec_cmd(toggle_rofi("cliphist list | rofi -dmenu -p Portapapeles | cliphist decode | wl-copy")), { desc = "Portapapeles" })
bind(mod .. " + comma", hl.dsp.exec_cmd(toggle_rofi("/home/anon/.local/bin/menu-sistema")), { desc = "Menú del sistema" })
-- Sin toggle_rofi: el selector de fondos no es rofi (GTK4, ver fondos-selector). El toggle
-- lo hace él mismo: es instancia única por D-Bus, y lanzarlo abierto lo cierra.
bind(mod .. " + Y", hl.dsp.exec_cmd("/home/anon/.local/bin/fondos-selector"), { desc = "Selector de fondos" })
bind(mod .. " + SHIFT + Y", hl.dsp.exec_cmd(toggle_rofi("/home/anon/.local/bin/menu-sistema leaf:wallpapers")), { desc = "Fondos de pantalla" })

-- Overview sustituto con rofi window (D3)
bind(mod .. " + D", hl.dsp.exec_cmd(toggle_rofi("rofi -show window")), { desc = "Overview (Ventanas)" })
bind(mod .. " + O", hl.dsp.exec_cmd(toggle_rofi("rofi -show window")), { desc = "Overview (Ventanas)" })

-- Alt-tab clásico: mantener SUPER y repetir Tab cicla ventanas (cada pulsación mueve foco,
-- sin overlay). `repeating = true` hace que el auto-repeat del teclado dispare el dispatcher
-- de nuevo mientras Tab sigue apretado, igual que las teclas de volumen.
bind(mod .. " + Tab", hl.dsp.window.cycle_next(), { repeating = true, desc = "Ciclar ventanas (alt-tab)" })
bind(mod .. " + SHIFT + Tab", hl.dsp.window.cycle_next({ prev = true }), { repeating = true, desc = "Ciclar ventanas (reverso)" })

-- ─── Notificaciones y Bloqueo ───
bind(mod .. " + N", hl.dsp.exec_cmd("swaync-client -t"), { desc = "Notification Center" })
bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -t"), { desc = "Notification Center" })
bind(mod .. " + ALT + L", hl.dsp.exec_cmd("/home/anon/.local/bin/lock"), { desc = "Bloquear pantalla" })
bind(mod .. " + ALT + SHIFT + L", hl.dsp.exec_cmd("pgrep -x hyprlock >/dev/null || /home/anon/.local/bin/lock"), { locked = true, desc = "Rescate del lock" })

-- ─── Aplicaciones (Run-or-Cycle) ───
--
-- Enfoca la app si ya tiene ventanas —ciclando entre ellas en orden de creación— y la lanza
-- si no. Es una función Lua y no un script: corre adentro del compositor, sin fork, sin
-- hyprctl y sin jq por pulsación.
--
-- `hl.get_windows({ class = … })` compara la clase EXACTA (probado: "kit" y "^kit" no
-- devuelven la kitty), así que se filtra a mano para aceptar también `initial_class`, que
-- es lo que conserva una app que cambia de clase después de abrir. `stable_id` da un orden
-- fijo entre pulsaciones, que es lo único que el ciclo necesita para no saltar en zigzag.
--
-- `hl.dsp.focus({ window = <HL.Window> })` cambia de workspace si hace falta. Con un juego
-- en pantalla completa eso importa: los juegos viven en el workspace 10 (cfg/rules.lua), así
-- que saltar a otra app cambia de workspace en vez de sacar al juego de pantalla completa.
local function run_or_cycle(class, cmd)
    return function()
        local wins = {}
        for _, w in ipairs(hl.get_windows()) do
            if w.mapped and (w.class == class or w.initial_class == class) then
                wins[#wins + 1] = w
            end
        end
        if #wins == 0 then
            hl.exec_cmd(cmd)
            return
        end
        table.sort(wins, function(a, b) return a.stable_id < b.stable_id end)
        local active, idx = hl.get_active_window(), 0
        if active then
            for i, w in ipairs(wins) do
                if w.stable_id == active.stable_id then idx = i break end
            end
        end
        hl.dispatch(hl.dsp.focus({ window = wins[idx % #wins + 1] }))
    end
end

bind(mod .. " + Return", run_or_cycle("kitty", "kitty"), { desc = "Kitty (Cycle)" })
bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd("kitty"), { desc = "Kitty (New)" })
bind(mod .. " + B", run_or_cycle("brave-origin", "brave-origin"), { desc = "Brave (Cycle)" })
bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd("brave-origin"), { desc = "Brave (New)" })
bind(mod .. " + E", run_or_cycle("yazi", "kitty --class yazi yazi"), { desc = "Yazi (Cycle)" })
bind(mod .. " + SHIFT + E", run_or_cycle("org.gnome.Nautilus", "nautilus"), { desc = "Nautilus (Cycle)" })
bind(mod .. " + Z", run_or_cycle("vesktop", "vesktop"), { desc = "Vesktop (Cycle)" })
bind(mod .. " + S", run_or_cycle("steam", "steam"), { desc = "Steam (Cycle)" })
bind(mod .. " + M", hl.dsp.exec_cmd("kitty --class btop btop"), { desc = "System Monitor" })

-- ─── Controles Multimedia ───
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("/home/anon/.local/bin/volume-ctl raise"), { locked = true, repeating = true, desc = "Subir volumen" })
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("/home/anon/.local/bin/volume-ctl lower"), { locked = true, repeating = true, desc = "Bajar volumen" })
bind("XF86AudioMute", hl.dsp.exec_cmd("/home/anon/.local/bin/volume-ctl mute-toggle"), { locked = true, repeating = true, desc = "Silenciar audio" })
bind("XF86AudioMicMute", hl.dsp.exec_cmd("/home/anon/.local/bin/volume-ctl mic-mute-toggle"), { locked = true, repeating = true, desc = "Silenciar micrófono" })

bind("XF86AudioNext", hl.dsp.exec_cmd("swayosd-client --playerctl next"), { locked = true, desc = "Siguiente pista" })
bind("XF86AudioPrev", hl.dsp.exec_cmd("swayosd-client --playerctl prev"), { locked = true, desc = "Pista anterior" })
bind("XF86AudioPlay", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), { locked = true, desc = "Play/Pausa" })
bind("XF86AudioPause", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), { locked = true, desc = "Play/Pausa" })

bind(mod .. " + SHIFT + A", hl.dsp.exec_cmd("/home/anon/.local/bin/toggle-audio.sh"), { desc = "Alternar salida de audio" })
bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd("/home/anon/.local/bin/toggle-tv.sh"), { desc = "Alternar TV (HDMI)" })

-- ─── Brillo (DDC/CI) ───
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("/home/anon/.local/bin/brightness-ddc raise"), { locked = true, repeating = true, desc = "Subir brillo" })
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("/home/anon/.local/bin/brightness-ddc lower"), { locked = true, repeating = true, desc = "Bajar brillo" })

-- ─── Foco y Movimiento de Ventanas ───
bind(mod .. " + Q", hl.dsp.window.close(), { desc = "Cerrar ventana" })

-- Foco
--
-- hl.dsp.focus({direction=...}) NO respeta scrolling.wrap_focus: probado con wrap_focus
-- true y false, en la última columna la siguiente pulsación rebota a la anterior en vez
-- de quedarse quieta (o dar la vuelta). hl.dsp.layout("focus l/r") sí lo respeta —
-- probado con 8 pulsaciones seguidas en el borde, se queda clavado — y con
-- focus_fit_method = 1 tampoco centra la columna, queda pegada al borde igual que con
-- hl.dsp.focus.
bind(mod .. " + Left", hl.dsp.layout("focus l"), { desc = "Foco izquierda" })
bind(mod .. " + H", hl.dsp.layout("focus l"), { desc = "Foco izquierda" })
bind(mod .. " + Right", hl.dsp.layout("focus r"), { desc = "Foco derecha" })
bind(mod .. " + L", hl.dsp.layout("focus r"), { desc = "Foco derecha" })
bind(mod .. " + Up", hl.dsp.layout("focus u"), { desc = "Foco arriba" })
bind(mod .. " + K", hl.dsp.layout("focus u"), { desc = "Foco arriba" })
bind(mod .. " + Down", hl.dsp.layout("focus d"), { desc = "Foco abajo" })
bind(mod .. " + J", hl.dsp.layout("focus d"), { desc = "Foco abajo" })

-- Mover columna (Shift)
bind(mod .. " + SHIFT + Left", hl.dsp.layout("swapcol l"), { desc = "Mover columna izquierda" })
bind(mod .. " + SHIFT + H", hl.dsp.layout("swapcol l"), { desc = "Mover columna izquierda" })
bind(mod .. " + SHIFT + Right", hl.dsp.layout("swapcol r"), { desc = "Mover columna derecha" })
bind(mod .. " + SHIFT + L", hl.dsp.layout("swapcol r"), { desc = "Mover columna derecha" })
bind(mod .. " + SHIFT + Up", hl.dsp.window.move({ workspace = "r-1" }), { desc = "Mover ventana workspace arriba" })
bind(mod .. " + SHIFT + K", hl.dsp.window.move({ workspace = "r-1" }), { desc = "Mover ventana workspace arriba" })
bind(mod .. " + SHIFT + Down", hl.dsp.window.move({ workspace = "r+1" }), { desc = "Mover ventana workspace abajo" })
bind(mod .. " + SHIFT + J", hl.dsp.window.move({ workspace = "r+1" }), { desc = "Mover ventana workspace abajo" })
bind(mod .. " + SHIFT + I", hl.dsp.window.move({ workspace = "r-1" }), { desc = "Mover ventana workspace arriba" })
bind(mod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "r+1" }), { desc = "Mover ventana workspace abajo" })

-- Foco y mover entre monitores (Ctrl / Ctrl+Shift)
bind(mod .. " + CTRL + Left", hl.dsp.focus({ monitor = "l" }), { desc = "Foco monitor izquierda" })
bind(mod .. " + CTRL + H", hl.dsp.focus({ monitor = "l" }), { desc = "Foco monitor izquierda" })
bind(mod .. " + CTRL + Right", hl.dsp.focus({ monitor = "r" }), { desc = "Foco monitor derecha" })
bind(mod .. " + CTRL + L", hl.dsp.focus({ monitor = "r" }), { desc = "Foco monitor derecha" })
bind(mod .. " + CTRL + Up", hl.dsp.focus({ monitor = "u" }), { desc = "Foco monitor arriba" })
bind(mod .. " + CTRL + K", hl.dsp.focus({ monitor = "u" }), { desc = "Foco monitor arriba" })
bind(mod .. " + CTRL + Down", hl.dsp.focus({ monitor = "d" }), { desc = "Foco monitor abajo" })
bind(mod .. " + CTRL + J", hl.dsp.focus({ monitor = "d" }), { desc = "Foco monitor abajo" })

bind(mod .. " + CTRL + SHIFT + Left", hl.dsp.window.move({ monitor = "l" }), { desc = "Mover ventana monitor izquierda" })
bind(mod .. " + CTRL + SHIFT + H", hl.dsp.window.move({ monitor = "l" }), { desc = "Mover ventana monitor izquierda" })
bind(mod .. " + CTRL + SHIFT + Right", hl.dsp.window.move({ monitor = "r" }), { desc = "Mover ventana monitor derecha" })
bind(mod .. " + CTRL + SHIFT + L", hl.dsp.window.move({ monitor = "r" }), { desc = "Mover ventana monitor derecha" })
bind(mod .. " + CTRL + SHIFT + Up", hl.dsp.window.move({ monitor = "u" }), { desc = "Mover ventana monitor arriba" })
bind(mod .. " + CTRL + SHIFT + K", hl.dsp.window.move({ monitor = "u" }), { desc = "Mover ventana monitor arriba" })
bind(mod .. " + CTRL + SHIFT + Down", hl.dsp.window.move({ monitor = "d" }), { desc = "Mover ventana monitor abajo" })
bind(mod .. " + CTRL + SHIFT + J", hl.dsp.window.move({ monitor = "d" }), { desc = "Mover ventana monitor abajo" })

-- Workspaces relativos (U/I y rueda)
bind(mod .. " + I", hl.dsp.focus({ workspace = "r-1" }), { desc = "Workspace anterior" })
bind(mod .. " + U", hl.dsp.focus({ workspace = "r+1" }), { desc = "Workspace siguiente" })
bind(mod .. " + Page_Up", hl.dsp.focus({ workspace = "r-1" }), { desc = "Workspace anterior" })
bind(mod .. " + Page_Down", hl.dsp.focus({ workspace = "r+1" }), { desc = "Workspace siguiente" })
bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "r-1" }), { desc = "Workspace anterior (rueda)" })
bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "r+1" }), { desc = "Workspace siguiente (rueda)" })
bind(mod .. " + SHIFT + mouse_up", hl.dsp.focus({ direction = "left" }), { desc = "Columna izquierda (rueda)" })
bind(mod .. " + SHIFT + mouse_down", hl.dsp.focus({ direction = "right" }), { desc = "Columna derecha (rueda)" })

-- Workspaces numéricos 1 al 9
for i = 1, 9 do
    bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }), { desc = "Workspace " .. i })
    bind(mod .. " + CTRL + " .. i, hl.dsp.window.move({ workspace = i }), { desc = "Mover a workspace " .. i })
    bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }), { desc = "Mover ventana a workspace " .. i })
end

-- El 10 es el de los juegos (cfg/rules.lua los abre ahí). Con workspace_back_and_forth,
-- Mod+0 desde el juego vuelve a donde se estaba.
bind(mod .. " + 0", hl.dsp.focus({ workspace = 10 }), { desc = "Workspace de juegos" })
bind(mod .. " + CTRL + 0", hl.dsp.window.move({ workspace = 10 }), { desc = "Mover a workspace de juegos" })

-- ─── Layout Scrolling ───
bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }), { desc = "Maximizar columna (scrolling)" })
bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen(), { desc = "Pantalla completa" })
bind(mod .. " + T", hl.dsp.window.float(), { desc = "Alternar flotante" })
bind(mod .. " + W", hl.dsp.group.toggle(), { desc = "Alternar pestaña/grupo" })
bind(mod .. " + C", hl.dsp.layout("center"), { desc = "Centrar columna" })
bind(mod .. " + CTRL + C", hl.dsp.layout("fit visible"), { desc = "Ajustar columnas visibles" })
bind(mod .. " + CTRL + F", hl.dsp.layout("fit expand"), { desc = "Expandir columna a espacio disponible" })
bind(mod .. " + minus", hl.dsp.layout("colresize -0.1"), { desc = "Reducir ancho columna" })
bind(mod .. " + equal", hl.dsp.layout("colresize +0.1"), { desc = "Aumentar ancho columna" })
bind(mod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { desc = "Reducir alto ventana" })
bind(mod .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { desc = "Aumentar alto ventana" })

-- ─── Captura de pantalla (hyprshot) ───
bind("Print", hl.dsp.exec_cmd("hyprshot -m region -o ~/Imágenes/Screenshots"), { desc = "Captura región" })
bind("CTRL + Print", hl.dsp.exec_cmd("hyprshot -m output -o ~/Imágenes/Screenshots"), { desc = "Captura pantalla" })
bind("ALT + Print", hl.dsp.exec_cmd("hyprshot -m window -m active -o ~/Imágenes/Screenshots"), { desc = "Captura ventana activa" })

-- ─── Sesión y Monitores ───
bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("uwsm stop"), { desc = "Cerrar sesión" })

-- ─── Grabación de pantalla (GPU Screen Recorder) ───
bind(mod .. " + G", hl.dsp.exec_cmd("gsr-ui-cli toggle-record"), { desc = "Grabar pantalla: arrancar/parar" })
bind(mod .. " + SHIFT + G", hl.dsp.exec_cmd("gsr-ui-cli replay-save"), { desc = "Guardar Replay (la jugada)" })
bind(mod .. " + ALT + G", hl.dsp.exec_cmd("gsr-ui-cli toggle-replay"), { desc = "Replay: arrancar/parar búfer" })
bind(mod .. " + ALT + SHIFT + G", hl.dsp.exec_cmd("gsr-ui-cli toggle-show"), { desc = "GPU Screen Recorder (overlay)" })
