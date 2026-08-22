-- Historial de notificaciones.
--
-- Reemplaza al panel de centro de notificaciones de swaync. mako NO tiene panel: es solo
-- daemon. En vez de resignar el historial, se lo trae al launcher — que además es lo que
-- se buscaba al migrar, porque el panel de swaync era la pieza que más desentonaba con la
-- estética del resto.
--
-- Lee `makoctl history -j` (el flag -j está documentado en `man 1 makoctl`; sin él la
-- salida es texto para humanos y no se puede parsear de forma confiable).
--
-- Encaja con el criterio de división de superficies del plan: revisar una lista y elegir
-- una entrada es una acción atómica sobre una lista descubierta, o sea menú, no TUI.

Name = "notifications"
NamePretty = "Notifications"
Description = "Dismissed notification history"
Icon = "preferences-system-notifications"
Action = "%VALUE%"
Cache = false

-- `Parent` es lo que hace aparecer el hint `back` abajo en walker y lo que hace que Escape
-- vuelva al índice en vez de cerrar el launcher. NO es decorativo y NO se hereda: cada menú
-- que se llegue desde `menus:system` tiene que declararlo. Ver system.toml.
Parent = "sys-utilities"

local function sh(cmd)
	local h = io.popen(cmd .. " 2>/dev/null")
	if not h then
		return ""
	end
	local out = h:read("*a") or ""
	h:close()
	return out
end

-- El parseo del JSON lo hace python, no Lua.
--
-- Primer intento: `jsonDecodes`, el global que documenta elephant. Cargaba el menú pero
-- devolvía 0 entradas, o sea que fallaba en silencio. En vez de averiguar por qué, se
-- saca la dependencia: python emite TSV y Lua solo corta por tabulaciones. Se controlan
-- las dos puntas y no hay una librería de por medio que pueda cambiar de forma.
--
-- El orden se invierte acá (más nuevas primero) y los saltos de línea del cuerpo se
-- aplanan, porque en una lista de una fila por notificación arruinan la alineación.
local PARSER = [[makoctl history -j 2>/dev/null | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for n in reversed(data):
    body = " ".join((n.get("body") or "").split())
    app  = (n.get("app_name") or "?").replace("\t", " ")
    summ = (n.get("summary")  or "").replace("\t", " ")
    urg  = n.get("urgency") or "normal"
    print("\t".join([summ, app, body, urg]))
']]

function GetEntries()
	local entries = {}

	for line in sh(PARSER):gmatch("[^\n]+") do
		local summary, app, body, urgency = line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$")

		if summary and summary ~= "" then
			local subtext = app
			if body ~= "" then
				subtext = app .. " · " .. body
			end

			table.insert(entries, {
				Text = summary,
				Subtext = subtext,
				-- Sin acción propia: no hay nada útil que "ejecutar" sobre una
				-- notificación ya descartada. `true` es un no-op que cierra el menú.
				Value = "true",
				Icon = (urgency == "cs-notifications") and "dialog-warning" or "preferences-system-notifications",
				State = (urgency == "cs-notifications") and { "current" } or nil,
			})
		end
	end

	if #entries == 0 then
		table.insert(entries, {
			Text = "Sin notificaciones",
			Subtext = "el historial está vacío",
			Value = "true",
			Icon = "preferences-system-notifications",
		})
	end

	return entries
end
