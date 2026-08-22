-- Menú de paquetes de íconos (2026-08-19).
--
-- Lista lo que devuelve `icon-set` (ya trae el activo marcado con "*") y aplica
-- el elegido con `icon-set %VALUE%`. Toda la lógica de qué es "Tela-circle" o
-- "Papirus", cómo se resuelve la variante de color contra matugen, y por qué
-- el recoloreo de Papirus corre en el fondo, vive en ~/.local/bin/icon-set —
-- este menú es una vista fina sobre ese script, igual que themes.lua sobre
-- theme-set y animations.lua sobre niri-animation.
--
-- `Cache = false`: el marcador de "activo" depende del wallpaper (vía matugen),
-- no solo de qué se eligió a mano, así que no puede quedar cacheado entre
-- aperturas del launcher.

Name = "icon-packs"
NamePretty = "Icon packs"
Description = "Switch the icon theme package"
Icon = "preferences-desktop-icons"
Action = "icon-set %VALUE%"
Cache = false

-- Ver sys-appearance.toml: NO se hereda, cada menú que cuelga de `menus:system`
-- lo declara para que Escape/Left vuelvan al nivel correcto.
Parent = "sys-appearance"

local function PrettyName(str)
	local pretty = str:gsub("[_-]", " ")

	return (pretty:gsub("(%a)([%w]*)", function(first, rest)
		return first:upper() .. rest:lower()
	end))
end

function GetEntries()
	local entries = {}

	local handle = io.popen("icon-set 2>/dev/null")
	if not handle then
		return entries
	end

	for line in handle:lines() do
		local marker, name = line:match("^(.)%s+(.+)$")
		if name then
			local active = marker == "*"
			local subtext
			if name == "Tela-circle" or name == "Papirus" then
				subtext = "recolorea con matugen"
			else
				subtext = "sin variantes de color"
			end
			if active then
				subtext = subtext .. " · activo"
			end

			table.insert(entries, {
				Text = PrettyName(name),
				Subtext = subtext,
				Value = name,
				State = active and { "current" } or nil,
			})
		end
	end

	handle:close()

	return entries
end
