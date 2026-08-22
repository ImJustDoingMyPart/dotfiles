-- Agenda: próximos eventos de Google Calendar.
--
-- Abre con click derecho en el reloj de la barra.
--
-- HUBO una versión con navegación por meses (una entrada por mes, con la grilla en el
-- panel de preview). Se sacó el 2026-08-05: mezclar "navegar meses" con "mis eventos" en
-- una sola lista enterraba los eventos entre cinco entradas que no aportaban nada, y
-- elephant las ordenaba por score, así que salían en desorden (Julio, Noviembre, Octubre).
-- Para mirar un mes está el tooltip del reloj, que ya muestra la grilla al pasar el mouse.
--
-- Los datos salen de `calendar-events`, que baja la URL secreta en formato iCal. Si no hay
-- URL configurada el menú queda con una sola entrada y no rompe nada.

Name = "calendar"
NamePretty = "Agenda"
Description = "Próximos eventos"
Icon = "office-calendar"
Action = "%VALUE%"
Cache = false

-- `Parent` es lo que hace aparecer el hint `back` abajo en walker y lo que hace que Escape
-- vuelva al índice en vez de cerrar el launcher. NO es decorativo y NO se hereda: cada menú
-- que se llegue desde `menus:system` tiene que declararlo. Ver system.toml.
Parent = "sys-utilities"

-- El orden lo define `calendar-events`, que ya devuelve los eventos cronológicamente.
-- Sin esto elephant los reordena por score y se pierde la única propiedad que importa en
-- una agenda: que lo más próximo esté arriba.
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

	for linea in sh("calendar-events"):gmatch("[^\n]+") do
		local iso, cuando, resumen, lugar = linea:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$")

		if resumen and resumen ~= "" then
			local sub = cuando
			if lugar ~= "" then
				sub = cuando .. " · " .. lugar
			end

			-- Lo de HOY se destaca. `calendar-events` ya devuelve la etiqueta relativa
			-- ("hoy 21:00", "mañana", "17/08"), así que alcanza con mirar el prefijo.
			--
			-- Se marca con `State` y NO con Pango markup: walker no habilita `use-markup`
			-- en el texto de los items y un "<b>" se ve LITERAL en la fila (probado en
			-- pantalla). El estado se convierte en clase CSS; el peso lo pone style.css.
			local es_hoy = cuando:sub(1, 3) == "hoy"

			-- SIN Preview (sacado el 2026-08-05). El panel lateral aparecía solo en las
			-- filas de evento y no en "Abrir Google Calendar", así que la VENTANA CAMBIABA
			-- DE TAMAÑO al navegar la lista. Lo que mostraba —fecha larga y lugar— ya está
			-- en el subtexto de la fila, en corto: no justificaba el salto.
			--
			-- El ícono es el MISMO para todos, incluido el de hoy. Antes el de hoy usaba
			-- `appointment-soon`, que en el tema de íconos actual sale como línea monocroma
			-- mientras el resto sale a color: dos estilos en una misma lista. El destaque
			-- de HOY queda entonces solo en `State`, que es lo que corresponde — el color
			-- es del tema, el énfasis es del CSS.
			table.insert(entries, {
				Text = resumen,
				Subtext = sub,
				-- No hay nada que ejecutar sobre un evento: abrir Google es lo único útil.
				Value = "xdg-open https://calendar.google.com",
				Icon = "office-calendar",
				State = es_hoy and { "today" } or nil,
				Keywords = { "evento", "event", "agenda", "google" },
			})
		end
	end

	-- Siempre al final: es la única forma de CREAR o editar un evento, que el menú no
	-- puede hacer (la URL iCal es de solo lectura). Además le da piso a la lista cuando no
	-- hay nada agendado.
	table.insert(entries, {
		Text = (#entries == 0) and "Sin eventos próximos" or "Abrir Google Calendar",
		Subtext = (#entries == 0) and "abrir Google Calendar" or "para crear o editar",
		Value = "xdg-open https://calendar.google.com",
		Icon = "office-calendar",
		Keywords = { "google", "gcal", "agenda", "nuevo", "crear" },
	})

	return entries
end
