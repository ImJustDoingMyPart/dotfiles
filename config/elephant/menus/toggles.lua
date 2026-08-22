-- Menú de toggles del escritorio.
--
-- Es .lua y no .toml porque cada entrada tiene que MOSTRAR SU ESTADO actual: un toggle que
-- no dice si está prendido obliga a activarlo para averiguarlo, y con "no molestar" eso es
-- justo lo que no querés hacer.
--
-- Los tres estados se leen de la fuente real, no de un archivo propio que podría
-- desincronizarse: makoctl para DND, `nightlight status` (pgrep de wlsunset) para la luz
-- nocturna, y `caffeine status` (systemd/hypridle) para caffeine.

Name = "toggles"
NamePretty = "Toggles"
Description = "Do not disturb, night light, caffeine"
Icon = "preferences-desktop"
Action = "%VALUE%"
Cache = false

-- `Parent` es lo que hace aparecer el hint `back` abajo en walker y lo que hace que Escape
-- vuelva al índice en vez de cerrar el launcher. NO es decorativo y NO se hereda: cada menú
-- que se llegue desde `menus:system` tiene que declararlo. Ver system.toml.
Parent = "sys-system"

local function sh(cmd)
	local handle = io.popen(cmd .. " 2>/dev/null")
	if not handle then
		return ""
	end

	local out = handle:read("*a") or ""
	handle:close()

	return (out:gsub("%s+$", ""))
end

function GetEntries()
	-- DND lo maneja MAKO, no swaync (arreglado el 2026-08-05). Este menú seguía llamando
	-- a `swaync-client -D -sw` de antes de la migración: swaync ya no corre, así que el
	-- comando moría con "NameHasNoOwner" y el estado se leía SIEMPRE como desactivado, y
	-- el Value tampoco alternaba nada. Es el mismo mecanismo que ya usaba bien el módulo
	-- custom/notification de la barra.
	--
	-- `makoctl mode` imprime un modo por línea (`man 1 makoctl`); do-not-disturb aparece
	-- en la lista solo cuando está activo, de ahí el match de línea completa.
	local dnd = false
	for modo in sh("makoctl mode"):gmatch("[^\n]+") do
		if modo == "do-not-disturb" then
			dnd = true
		end
	end

	local night = sh("nightlight status") == "on"
	local caffeine = sh("caffeine status") == "on"

	local function estado(on)
		return on and "activado" or "desactivado"
	end

	return {
		{
			Text = "Do not disturb",
			Subtext = estado(dnd),
			Value = "makoctl mode -t do-not-disturb",
			Icon = dnd and "cs-notifications" or "preferences-system-notifications",
			State = dnd and { "current" } or nil,
			Keywords = { "dnd", "notificaciones", "silencio", "notifications" },
		},
		{
			Text = "Night light",
			Subtext = estado(night),
			Value = "nightlight toggle",
			Icon = "cs-nightlight",
			State = night and { "current" } or nil,
			Keywords = { "luz", "nocturna", "temperatura", "gamma", "warm" },
		},
		{
			Text = "Caffeine",
			Subtext = estado(caffeine) .. (caffeine and " · no se bloquea" or " · bloqueo automático"),
			Value = "caffeine toggle",
			Icon = "caffeine",
			State = caffeine and { "current" } or nil,
			Keywords = { "cafeina", "idle", "bloqueo", "lock", "insomnia", "awake" },
		},
	}
end
