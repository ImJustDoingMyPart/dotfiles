-- Submenú "Fuentes" del menú Apariencia (2026-08-08).
--
-- Solo tiene dos entradas y aun así es .lua y no .toml, por el mismo motivo que toggles.lua:
-- cada una MUESTRA EN EL SUBTEXTO la familia que está puesta ahora mismo. Un menú de fuentes
-- que no dice cuál es la actual obliga a entrar a los dos niveles para averiguarlo.
--
-- El estado se lee de la fuente real (gsettings y kitty.conf, vía `font-set --actual`), no de
-- un archivo de estado propio: kitty.conf se edita a mano seguido y una copia paralela se
-- desincronizaría en silencio.

Name = "fonts"
NamePretty = "Fuentes"
Description = "la de la interfaz y la de la terminal"
Icon = "cs-fonts"
Cache = false
FixedOrder = true

-- `Parent` es lo que hace aparecer el hint `back` abajo en walker y lo que hace que la flecha
-- IZQUIERDA vuelva a la categoría. NO es decorativo y NO se hereda: cada menú lo declara.
-- Los dos menús hoja de acá abajo declaran a su vez `Parent = "fonts"`.
Parent = "sys-appearance"

local function actual(ambito)
	local handle = io.popen("font-set --actual " .. ambito .. " 2>/dev/null")
	if not handle then
		return "?"
	end

	-- "*l" y no "*line": el intérprete Lua embebido en elephant rechaza la forma larga
	-- con `bad argument #2 to read (invalid options:i)`.
	local fam = handle:read("*l")
	handle:close()

	return (fam == nil or fam == "") and "?" or fam
end

function GetEntries()
	return {
		{
			Text = "Sistema",
			Subtext = actual("sistema") .. " · proporcional, apps GTK y Qt",
			Icon = "preferences-desktop-font",
			SubMenu = "fonts-system",
			Keywords = { "fuente", "font", "sistema", "interfaz", "gtk", "qt", "tipografia" },
		},
		{
			Text = "Terminal",
			Subtext = actual("terminal") .. " · monoespaciada, kitty",
			Icon = "utilities-terminal",
			SubMenu = "fonts-terminal",
			Keywords = { "fuente", "font", "terminal", "kitty", "mono", "monoespaciada", "tipografia" },
		},
	}
end
