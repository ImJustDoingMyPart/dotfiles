-- Audio POR APLICACIÓN: mandar cada programa a una salida distinta.
--
-- Spotify por los parlantes y Discord por los auriculares al mismo tiempo. Es lo que el
-- provider `wireplumber` NO puede hacer: ese solo cambia el dispositivo por DEFECTO, o sea
-- adónde va todo.
--
-- Antes esto solo estaba en wiremix, una TUI que se abría en una terminal y desentonaba con
-- bluetooth, red y volumen, que son todos menús de walker. Este menú existe para que la
-- operación frecuente —mover una app de salida— viva en la misma superficie que el resto.
-- wiremix sigue en el click del medio del widget de volumen, para lo que un menú de acciones
-- atómicas no cubre: volumen por aplicación, medidores de pico, entradas de grabación.
--
-- La lista es el PRODUCTO CRUZADO de (apps que suenan × salidas disponibles), o sea una fila
-- por destino posible. Se eligió eso y no "una fila por app que cicla al siguiente destino"
-- porque con tres salidas ciclar obliga a adivinar cuántas veces apretar, y porque así se
-- puede tipear "auri" y saltar directo.
--
-- El parseo de PipeWire lo hace `audio-streams` (~/.local/bin), igual que `calendar-events`
-- con el .ics: acá solo se formatea.

Name = "audio"
NamePretty = "Audio por aplicación"
Description = "Send each app to a different output"
Icon = "applications-multimedia"
Action = "%VALUE%"
Cache = false

-- `Parent` es lo que hace aparecer el hint `back` abajo en walker y lo que hace que Escape
-- vuelva al índice en vez de cerrar el launcher. NO es decorativo y NO se hereda: cada menú
-- que se llegue desde `menus:system` tiene que declararlo. Ver system.toml.
Parent = "sys-multimedia"

-- Las filas vienen agrupadas por aplicación desde el script. Sin esto elephant las reordena
-- por score y se mezclan los destinos de una app con los de otra, que es justo lo que hay
-- que poder leer de un vistazo.
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

	for linea in sh("audio-streams"):gmatch("[^\n]+") do
		local idx, app, icono, sink, salida, actual, detalle =
			linea:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$")

		if idx and idx ~= "" then
			local es_actual = actual == "1"

			-- El subtexto dice qué va a pasar, no qué es la fila: "ya está acá" contra
			-- "mover". Sin eso hay que comparar el estado marcado con la fila seleccionada.
			local sub = es_actual and "acá está sonando ahora" or ("mover a " .. salida)
			if detalle ~= "" and detalle ~= "Playback" then
				sub = sub .. " · " .. detalle
			end

			table.insert(entries, {
				Text = app .. " → " .. salida,
				Subtext = sub,
				-- pactl mueve UN stream por índice; el resto de las apps no se toca, que es
				-- toda la diferencia con `toggle-audio.sh` (Mod+Shift+A), que las muda todas.
				Value = string.format("pactl move-sink-input %s %s", idx, sink),
				-- El ícono que declara el propio programa. Muchos no declaran ninguno, y ahí
				-- se cae al genérico del menú en vez de dejar el hueco.
				Icon = (icono ~= "" and icono) or "applications-multimedia",
				State = es_actual and { "current" } or nil,
				Keywords = { "audio", "salida", "output", "sink", "mover", "move", salida },
			})
		end
	end

	-- Un stream solo existe mientras algo REPRODUCE. Sin esta entrada, abrir el menú con
	-- todo en silencio da una lista vacía y parece que está roto.
	if #entries == 0 then
		table.insert(entries, {
			Text = "No hay ninguna aplicación reproduciendo",
			Subtext = "poné play y volvé a abrir · el volumen general está en Mod+, → Wireplumber",
			Value = "true",
			Icon = "applications-multimedia",
			Keywords = { "audio", "vacio", "empty" },
		})
	end

	return entries
end
