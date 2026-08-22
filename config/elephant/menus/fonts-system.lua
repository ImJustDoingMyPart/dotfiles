-- Familias proporcionales instaladas: la fuente de la INTERFAZ (2026-08-08).
--
-- La lista y el filtrado los hace `font-set --listar sistema` (una sola llamada a fc-list,
-- con el porqué de cada exclusión comentado ahí). Este archivo solo la pinta: si mañana
-- cambia el criterio de qué fuente es candidata, se toca el script y los dos menús lo
-- heredan.
--
-- Formato de cada línea: familia <TAB> subtexto.

Name = "fonts-system"
NamePretty = "Fuente del sistema"
Description = "familia proporcional de las apps GTK y Qt"
Icon = "preferences-desktop-font"

-- Las comillas simples alrededor de %VALUE% no son opcionales: TODA familia de esta lista
-- tiene espacios ("Adwaita Sans", "Times New Roman"). Los comandos de los menús pasan por
-- una shell, así que sin comillas `font-set` recibiría tres argumentos.
--
-- Y si algún día el quoting se rompiera, falla RUIDOSO y sin tocar nada: font-set valida
-- contra su propia lista y sale con "no está entre las familias instaladas".
Action = "font-set sistema '%VALUE%'"

Cache = false
FixedOrder = true
Parent = "fonts"

function GetEntries()
	local entries = {}

	local activa = ""
	local h = io.popen("font-set --actual sistema 2>/dev/null")
	if h then
		activa = h:read("*l") or ""
		h:close()
	end

	local handle = io.popen("font-set --listar sistema 2>/dev/null")
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
				-- `State` marca la fila como actual; el CSS del tema base la pone en
				-- itálica vía `:not(.calc).current`.
				State = (fam == activa) and { "current" } or nil,
			})
		end
	end

	handle:close()

	return entries
end
