-- Menú de temas — versión propia del themes.lua de nickjj/dotfriedrice.
--
-- Lista los directorios de ~/.config/themes y activa el elegido vía `theme-set`.
-- El tema "matugen" no está versionado: sus archivos los escribe matugen desde el
-- wallpaper (ver ~/.local/bin/theme-matugen). Por eso el subtexto distingue generado
-- de curado — desde el menú los dos se eligen igual, pero no se comportan igual:
-- el generado cambia cuando cambia el wallpaper, el curado nunca.
--
-- Diferencias contra el original de dotfriedrice:
--   * No usa DOTFRIEDRICE_PATH (no existe acá); usa ~/.config/themes.
--   * Sin contar wallpapers por tema (_theme.json): acá los wallpapers no están
--     atados al tema, los maneja el daemon de fondo aparte.
--   * `refresh_on_change` en vez de `Cache = false`: cachea, pero se invalida sola
--     cuando aparece o desaparece un tema. Es una opción documentada del provider
--     de menús (`elephant generate doc`).

Name = "themes"
NamePretty = "Themes"
Description = "Switch the desktop theme"
Icon = "preferences-desktop-theme"
Action = "theme-set %VALUE%"

-- `Parent` es lo que hace aparecer el hint `back` abajo en walker y lo que hace que Escape
-- vuelva al índice en vez de cerrar el launcher. NO es decorativo y NO se hereda: cada menú
-- que se llegue desde `menus:system` tiene que declararlo. Ver system.toml.
Parent = "sys-appearance"

-- os.getenv("XDG_CONFIG_HOME") es nil en esta máquina (la variable no está seteada) y
-- concatenar nil aborta el script entero. El original de dotfriedrice la usa sin
-- fallback porque su entorno la define.
local config_dir = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local themes_dir = config_dir .. "/themes"

RefreshOnChange = { themes_dir }

local function PrettyName(str)
	local pretty = str:gsub("[_-]", " ")

	return (pretty:gsub("(%a)([%w]*)", function(first, rest)
		return first:upper() .. rest:lower()
	end))
end

local function ActiveTheme()
	local f = io.open(themes_dir .. "/.activo", "r")
	if not f then
		return nil
	end

	-- "*l" y no "*line": el intérprete Lua embebido en elephant rechaza la forma larga
	-- con `bad argument #2 to read (invalid options:i)`.
	local name = f:read("*l")
	f:close()

	return name
end

function GetEntries()
	local entries = {}
	local active = ActiveTheme()

	local handle = io.popen("find " .. themes_dir .. " -mindepth 1 -maxdepth 1 -type d -printf '%P\\n' 2>/dev/null")
	if not handle then
		return entries
	end

	for theme in handle:lines() do
		local subtext
		if theme == "matugen" then
			subtext = "generated from wallpaper"
		else
			subtext = "curated"
		end

		if theme == active then
			subtext = subtext .. " · active"
		end

		table.insert(entries, {
			Text = PrettyName(theme),
			Subtext = subtext,
			Value = theme,
			-- `state` marca la fila como actual; el CSS del tema base la pone en
			-- itálica vía `:not(.calc).current`.
			State = (theme == active) and { "current" } or nil,
		})
	end

	handle:close()

	return entries
end
