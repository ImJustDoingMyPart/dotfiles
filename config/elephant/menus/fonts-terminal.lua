-- Familias monoespaciadas instaladas: la fuente de la TERMINAL (2026-08-08).
--
-- Gemelo de fonts-system.lua; lo único que cambia es el ámbito que se le pide a `font-set`.
-- El subtexto de cada fila viene del script e incluye el aviso de si la familia trae glifos
-- Nerd Font, que es la diferencia entre que starship y eza muestren sus íconos o cuadraditos.

Name = "fonts-terminal"
NamePretty = "Fuente de la terminal"
Description = "familia monoespaciada de kitty"
Icon = "utilities-terminal"

-- Comillas simples obligatorias: ver el comentario largo en fonts-system.lua.
Action = "font-set terminal '%VALUE%'"

Cache = false
FixedOrder = true
Parent = "fonts"

function GetEntries()
	local entries = {}

	local activa = ""
	local h = io.popen("font-set --actual terminal 2>/dev/null")
	if h then
		activa = h:read("*l") or ""
		h:close()
	end

	local handle = io.popen("font-set --listar terminal 2>/dev/null")
	if not handle then
		return entries
	end

	for linea in handle:lines() do
		local fam, sub = linea:match("^([^\t]+)\t(.*)$")

		if fam then
			table.insert(entries, {
				Text = fam,
				Subtext = (fam == activa) and (sub .. " · activa") or sub,
				Value = fam,
				State = (fam == activa) and { "current" } or nil,
			})
		end
	end

	handle:close()

	return entries
end
