-- Clima: el pronóstico de la semana.
--
-- Abre con click derecho en el widget de clima de la barra, o desde el índice de `Mod+,`
-- en la categoría Utilidades.
--
-- Es el hermano de `calendar.lua` y está armado igual a propósito: una lista plana, sin
-- panel de preview, con el día en el texto y el detalle en el subtexto. Las dos son
-- "mirá lo que viene" y tienen que verse como la misma superficie.
--
-- Los datos salen de `weather-forecast --menu`, que devuelve TSV ya formateado y cachea la
-- descarga. Si no hay ubicación configurada o la red está caída sin cache, el menú queda
-- con una sola entrada y no rompe nada.

Name = "weather"
NamePretty = "Clima"
Description = "Pronóstico de la semana"
Icon = "weather-clear"
Action = "%VALUE%"
Cache = false

-- `Parent` es lo que hace aparecer el hint `atrás` abajo en walker y lo que hace que la
-- flecha izquierda vuelva a la categoría en vez de cerrar el launcher. NO se hereda: cada
-- menú que se llegue desde `menus:system` tiene que declararlo. Ver sys-utilities.toml.
Parent = "sys-utilities"

-- El orden lo define `weather-forecast`, que devuelve los días cronológicamente. Sin esto
-- elephant reordena por score y un pronóstico desordenado no es un pronóstico.
FixedOrder = true

local function sh(cmd)
	local h = io.popen(cmd .. " 2>/dev/null")
	if not h then
		return ""
	end
	local out = h:read("*a") or ""
	h:close()
	return out
end

function GetEntries()
	local entries = {}

	for linea in sh("weather-forecast --menu"):gmatch("[^\n]+") do
		local dia, detalle, icono, hoy = linea:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$")

		if dia and dia ~= "" then
			-- Se marca HOY con `State` y NO con markup: walker no habilita `use-markup`
			-- en el texto de los items y un "<b>" se ve LITERAL en la fila. El estado se
			-- convierte en clase CSS; el peso lo pone style.css. Mismo mecanismo que la
			-- fila del evento de hoy en la agenda.
			table.insert(entries, {
				Text = dia,
				Subtext = detalle,
				-- No hay nada que ejecutar sobre un día: abrir el pronóstico completo en
				-- el navegador es lo único útil, y es lo mismo que hace la última fila.
				Value = "xdg-open 'https://www.google.com/search?q=clima'",
				-- Íconos de Papirus-Dark `status/`: redondos, rellenos y a color, del
				-- mismo estilo que el `office-calendar` de la agenda. Verificados
				-- renderizándolos con GtkIconTheme de GTK4, el motor que usa walker.
				Icon = icono,
				State = (hoy == "hoy") and { "today" } or nil,
				Keywords = { "clima", "tiempo", "pronostico", "weather", "lluvia", "temperatura" },
			})
		end
	end

	-- Siempre al final. Le da piso a la lista cuando no hay datos —red caída, o falta el
	-- archivo `~/.config/weather-location`— y en el caso normal es la puerta al pronóstico
	-- por hora, que una lista de 7 filas no puede dar.
	table.insert(entries, {
		Text = (#entries == 0) and "Sin datos del clima" or "Ver el pronóstico completo",
		Subtext = (#entries == 0) and "revisar la red o ~/.config/weather-location"
			or "por hora, en el navegador",
		Value = "xdg-open 'https://www.google.com/search?q=clima'",
		Icon = (#entries == 0) and "weather-none-available" or "weather-clear",
		Keywords = { "clima", "tiempo", "pronostico", "weather", "navegador" },
	})

	return entries
end
