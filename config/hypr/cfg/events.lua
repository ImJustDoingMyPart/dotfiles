-- Reacciones a eventos del compositor. Reemplazan procesos vigilantes: corren adentro de
-- Hyprland, sin nada escuchando un socket.

-- ─── Fondo en las pantallas que se conectan ───
--
-- awww crea su capa en una salida nueva pero NO le pinta nada: queda en `color: 000000`. Su
-- caché es por salida, así que una pantalla que nunca tuvo fondo no tiene qué restaurar.
--
-- `monitor.added` cubre los dos casos que importan acá: el enchufe físico y la TV prendida
-- con Mod+Shift+T. Verificado en el fuente de v0.56.2: `CMonitor::onConnect()` emite el
-- evento (src/output/Monitor.cpp), y reaplicar una regla que pasa de `disabled` a habilitada
-- llama a `onConnect(true)` (src/config/shared/monitor/MonitorRuleManager.cpp). El callback
-- recibe el HL.Monitor (src/config/lua/LuaEventHandler.cpp).
--
-- El timer de 1 s le da tiempo a awww de crear la capa: repintar antes no hace nada. Se pinta
-- solo esa salida (`-o`) y sin transición: sobre una pantalla que recién se enciende, un
-- fundido se ve como un parpadeo. No llama a `wallpaper-set`, que además regenera el tema
-- entero: enchufar una pantalla no cambia la paleta.
hl.on("monitor.added", function(mon)
    local name = mon.name
    hl.timer(function()
        hl.exec_cmd(
            "img=$(head -1 \"$HOME/.local/state/wallpaper\" 2>/dev/null); "
            .. "[ -r \"$img\" ] && awww img -o " .. name .. " \"$img\" --transition-type none"
        )
    end, { timeout = 1000, type = "oneshot" })
end)
