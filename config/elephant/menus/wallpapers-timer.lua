-- Fondos de pantalla → DURACIÓN: cada cuántas horas rota solo el fondo.
--
-- Cuatro filas fijas (off · 3 · 6 · 12) y no un valor libre porque un menú de walker no tiene
-- campo numérico ni barrita: lo que se puede hacer es tipear y filtrar, no ingresar un valor.
-- Se podría abusar de la query (una acción Lua recibe `(value, args, query)` y ahí llegaría
-- lo tipeado), pero eso convierte una lista de opciones en un campo de texto invisible que no
-- avisa qué formato espera. Con tres intervalos alcanza; si alguna vez hace falta otro, se
-- agrega una fila acá o se corre `wallpaper-rotate-set 8` en la terminal, que acepta
-- cualquier número de horas.
--
-- Quién ejecuta: `wallpaper-rotate-set`, que escribe ~/.local/state/wallpaper-rotate y
-- prende o apaga `wallpaper-rotate.timer`. El timer tiene un tic FIJO de una hora y el
-- intervalo lo decide el script en cada disparo — así cambiar de 12 h a 3 h desde acá no
-- reescribe ninguna unidad ni pide un `daemon-reload`. El precio es la granularidad: "3 h"
-- cae entre las 3 y las 4 horas.

Name = "wallpapers-timer"
NamePretty = "Duración del fondo"
Description = "Cada cuántas horas cambia solo el fondo"
Icon = "preferences-system-time"
Action = "wallpaper-rotate-set %VALUE%"
Cache = false
Parent = "wallpapers"
FixedOrder = true

local opciones = {
	{ value = "off", text = "Desactivado", subtext = "el fondo solo cambia cuando lo elegís vos" },
	{ value = "3", text = "3 horas", subtext = nil },
	{ value = "6", text = "6 horas", subtext = nil },
	{ value = "12", text = "12 horas", subtext = nil },
}

local function Actual()
	local handle = io.popen("wallpaper-rotate-set --actual 2>/dev/null")
	if not handle then
		return "off"
	end

	local v = handle:read("*l")
	handle:close()

	return (v and v ~= "") and v or "off"
end

-- Cuánto falta para el próximo cambio. La cuenta va desde el mtime de
-- ~/.local/state/wallpaper —el último cambio de fondo, lo escriba el timer o lo elijas vos—,
-- que es la misma referencia que usa `wallpaper-rotate` para decidir. Si acá dijera otra cosa
-- que el script, el menú estaría mintiendo.
local function FaltaPara(horas)
	local handle = io.popen("stat -c %Y " .. string.format("%q", os.getenv("HOME") .. "/.local/state/wallpaper") .. " 2>/dev/null")
	if not handle then
		return nil
	end

	local ultimo = tonumber(handle:read("*l") or "")
	handle:close()

	if not ultimo then
		return nil
	end

	local restante = (ultimo + horas * 3600) - os.time()

	if restante <= 0 then
		return "en el próximo tic"
	end

	local h = math.floor(restante / 3600)
	local m = math.floor((restante % 3600) / 60)

	if h == 0 then
		return string.format("en ~%d min", m)
	end

	return string.format("en ~%d h %d min", h, m)
end

function GetEntries()
	local entries = {}
	local actual = Actual()

	for _, o in ipairs(opciones) do
		local subtext = o.subtext
		local activo = (o.value == actual)

		if o.value ~= "off" then
			subtext = "un fondo al azar de la carpeta actual, cada " .. o.value .. " horas"

			if activo then
				local falta = FaltaPara(tonumber(o.value))
				subtext = falta and ("activo · próximo cambio " .. falta) or "activo"
			end
		elseif activo then
			subtext = subtext .. " · activo"
		end

		table.insert(entries, {
			Text = o.text,
			Subtext = subtext,
			Value = o.value,
			-- `media-playlist-shuffle` venía de `actions/`: dos flechas grises de línea, el
			-- glifo monocromo que el criterio de bluetooth.toml sacó del resto del launcher.
			-- `alarm-timer` (symlink a ktimer.svg en `apps/`) es el reloj azul con la flecha
			-- de cuerda: relleno, a color, y dice "intervalo" mejor que un shuffle. Queda
			-- además contrastando con el reloj naranja de `preferences-system-time`, que se
			-- reserva para la fila "Desactivado" y para el menú mismo.
			Icon = (o.value == "off") and "preferences-system-time" or "alarm-timer",
			State = activo and { "current" } or nil,
			Keywords = { "duracion", "rotacion", "horas", "automatico", o.value },
		})
	end

	return entries
end
