-- Menú de temas de cursor (2026-08-19).
--
-- Selector plano: ningún cursor instalado trae variantes de color, así que a
-- diferencia de icon-packs.lua acá no hay nada que preguntarle a matugen. Lista
-- lo que devuelve `cursor-set` (ya trae el activo marcado con "*") y aplica el
-- elegido con `cursor-set %VALUE%`, que conserva el tamaño que ya estaba puesto.

Name = "cursors"
NamePretty = "Cursors"
Description = "Switch the cursor theme"
Icon = "preferences-desktop-cursors"
Action = "cursor-set %VALUE%"
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

	local handle = io.popen("cursor-set 2>/dev/null")
	if not handle then
		return entries
	end

	for line in handle:lines() do
		local marker, name = line:match("^(.)%s+(.+)$")
		if name then
			local active = marker == "*"

			table.insert(entries, {
				Text = PrettyName(name),
				Subtext = active and "activo" or name,
				Value = name,
				State = active and { "current" } or nil,
			})
		end
	end

	handle:close()

	return entries
end
