-- Menú de animaciones de niri.
--
-- Reemplaza al plugin propio de Noctalia "niri-animations" (Mod+A), que queda huérfano
-- al salir de Noctalia. Lista los packs de ~/.config/niri/animations/ y aplica el
-- elegido con `niri-animation`, que reescribe el include y valida antes de dejarlo.

Name = "animations"
NamePretty = "Animations"
Description = "niri animation pack"
Icon = "preferences-desktop-screensaver"
Action = "niri-animation %VALUE%"
Cache = false

-- `Parent` es lo que hace aparecer el hint `back` abajo en walker y lo que hace que Escape
-- vuelva al índice en vez de cerrar el launcher. NO es decorativo y NO se hereda: cada menú
-- que se llegue desde `menus:system` tiene que declararlo. Ver system.toml.
Parent = "sys-appearance"

local config_dir = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local packs_dir = config_dir .. "/niri/animations"
local anim_file = config_dir .. "/niri/animations.kdl"

local function PrettyName(str)
	local pretty = str:gsub("[_-]", " ")

	return (pretty:gsub("(%a)([%w]*)", function(first, rest)
		return first:upper() .. rest:lower()
	end))
end

-- Pack activo = el que apunta la línea include de animations.kdl.
local function ActivePack()
	local f = io.open(anim_file, "r")
	if not f then
		return nil
	end

	local content = f:read("*a")
	f:close()

	return content:match('include%s+"%./animations/([^"]+)%.kdl"')
end

function GetEntries()
	local entries = {}
	local active = ActivePack()

	local handle = io.popen("find " .. packs_dir .. " -maxdepth 1 -name '*.kdl' -printf '%P\\n' 2>/dev/null")
	if not handle then
		return entries
	end

	for file in handle:lines() do
		local pack = file:gsub("%.kdl$", "")

		table.insert(entries, {
			Text = PrettyName(pack),
			Subtext = (pack == active) and "active" or pack,
			Value = pack,
			State = (pack == active) and { "current" } or nil,
		})
	end

	handle:close()

	return entries
end
