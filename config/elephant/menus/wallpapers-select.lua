-- Fondos de pantalla → SELECTOR: las colecciones (los directorios), no las imágenes.
--
-- Es la primera de las tres ramas que cuelgan de `wallpapers` (Selector · Directorio ·
-- Duración). Sus hermanas eligen DÓNDE se busca (`wallpapers-root`) y CADA CUÁNTO cambia
-- solo (`wallpapers-timer`); esta elige cuál se pone ahora.
--
-- Reemplaza al selector de wallpaper de Noctalia. Aplica con `wallpaper-set`, que
-- además recalcula el tema si el activo es el generado — por eso el menú NO llama a
-- awww directo: cambiar el fondo sin recalcular el color dejaría el sistema a mitad
-- de camino. Quien ejecuta eso es el nivel 2 (`wallpapers-dir.lua`); acá solo se elige
-- en qué carpeta mirar.
--
-- Diferencia grande contra el wallpapers.lua de dotfriedrice: allá los wallpapers están
-- ATADOS al tema (cada tema declara con qué fondos "sinergiza" en su _theme.json). Acá
-- la relación es al revés: el fondo es la fuente y el color se deriva de él, así que la
-- lista es simplemente lo que haya en el directorio.
--
-- ─── Por qué dos niveles (2026-08-08) ───
--
-- Este menú listó las IMÁGENES sueltas hasta hoy. Con `-maxdepth 2` eran 109 y andaba;
-- al sacar el maxdepth para que entraran las subcarpetas de `walls/` pasaron a ser 603 y
-- la pantalla de selección se puso lenta: walker tiene que resolver y rasterizar una
-- miniatura por fila, y ahí el cuello no es elephant (la consulta tarda 33 ms con 603
-- entradas, medido) sino el renderizado en GTK.
--
-- Ahora el nivel 1 son las ~20 colecciones y el nivel 2 las imágenes de la elegida. Se
-- rasterizan 20 miniaturas en vez de 603, y de paso las colecciones son una forma de
-- mirar la biblioteca que antes no existía.
--
-- ─── Y por qué a veces UNO SOLO (2026-08-15) ───
--
-- Si la raíz elegida en `Directorio` NO tiene subcarpetas —o sea, ya es una colección: la
-- persona bajó hasta `~/Imágenes/gruvbox` y eligió esa— este menú listaba una única fila, la
-- carpeta misma, y había que entrar en ella para ver los fondos. Es un nivel que no informa
-- nada: repite la elección que se acaba de hacer un menú más arriba.
--
-- Desde hoy, en ese caso el Selector lista DIRECTAMENTE las imágenes y Return las aplica. El
-- menú tiene dos formas según lo que haya abajo, y las dos se llaman "elegir el fondo":
--
--   raíz con subcarpetas  → colecciones (SubMenu, se entra)  → wallpapers-images
--   raíz sin subcarpetas  → imágenes    (Action, se aplica)
--
-- ─── Cómo se pasa la carpeta al nivel 2, que es lo no obvio ───
--
-- No hace falta un archivo de menú por carpeta. `SubMenu` manda a todas las colecciones al
-- MISMO menú (`wallpapers-dir`), y ese menú averigua cuál se eligió con la global
-- `lastMenuValue("wallpapers")`, que devuelve el `Value` de la última entrada activada de
-- este menú. Verificado el 2026-08-08 activando dos carpetas distintas y viendo cambiar lo
-- que reportaba el nivel 2.
--
-- ⚠ `SubMenu` va en camelCase. `Submenu` y `submenu` se ignoran EN SILENCIO: la entrada
-- queda con `menus:default` en vez de `menus:open`, o sea que Return ejecuta la acción por
-- defecto en vez de entrar, y no hay ningún error que lo avise. Probado con las tres
-- grafías contra `elephant query`. La doc que genera el binario escribe el campo en
-- minúscula porque documenta el TOML, no el Lua.

Name = "wallpapers-select"
NamePretty = "Selector de fondos"
Description = "Elegir el fondo, colección por colección"
Icon = "cs-backgrounds"
Cache = false

-- La acción del modo plano: ahí las filas SON imágenes y Return las aplica. Es la misma que
-- usa `wallpapers-images`, y por el mismo motivo: `wallpaper-set` además recalcula el tema si
-- el activo es el generado, así que llamar a awww directo dejaría el sistema a mitad de camino.
--
-- En modo colecciones no la usa nadie y no molesta: una fila con `SubMenu` recibe SOLO la
-- acción `menus:open` — verificado con `elephant query`, que devuelve `actions:"menus:open"`
-- para las filas del Selector y `actions:"menus:default"` para las de `wallpapers-images`.
Action = "wallpaper-set %VALUE%"

-- `Parent` es lo que hace aparecer el hint `back` abajo en walker y lo que hace que la
-- flecha izquierda vuelva al índice en vez de cerrar el launcher. NO es decorativo y NO se
-- hereda: cada menú que se llegue desde `menus:system` tiene que declararlo. Ver system.toml.
Parent = "wallpapers"

-- Se listan SOLO las subcarpetas de la raíz, no la raíz misma: en ~/Imágenes hay 17
-- imágenes sueltas que son descargas random, no wallpapers. Por eso el find va con
-- -mindepth 2. (La excepción está más abajo, en el fallback para carpetas planas.)
--
-- Y se excluyen las subcarpetas que sí tienen imágenes pero no son fondos: Screenshots
-- (capturas) y Fastfetch (logos).
--
-- La exclusión de ocultas (`-not -path '*/.*/*'`) tampoco es cosmética: `walls` es un clon
-- de git, y sin ella el find se mete en `.git/` y `.github/` a buscar .png.
local excluded = { "Screenshots", "Fastfetch" }

-- ─── La raíz dejó de ser fija (2026-08-14) ───
--
-- Antes esto era `os.getenv("WALLPAPERS_DIR") or ~/Imágenes`, evaluado UNA vez al cargar el
-- archivo. Ahora la elige el nivel 0 (`wallpapers-root.lua`) y la guarda
-- `wallpaper-root-set` en ~/.local/state/wallpaper-root.
--
-- ⚠ Se resuelve DENTRO de GetEntries, no en el cuerpo del archivo: el chunk de Lua se
-- ejecuta al cargar el menú y no hay garantía de que se reevalúe en cada consulta —
-- `Cache = false` asegura que se llame a GetEntries, no que se recargue el archivo. Con la
-- raíz calculada arriba, cambiarla no se vería hasta reiniciar elephant, que es exactamente
-- el problema que este rediseño vino a sacar.
--
-- El default y el caso "la raíz guardada ya no existe" viven en el script, no acá.
local function CurrentRoot()
	local handle = io.popen("wallpaper-root-set --actual 2>/dev/null")
	if not handle then
		return os.getenv("WALLPAPERS_DIR") or (os.getenv("HOME") .. "/Imágenes")
	end

	local dir = handle:read("*l")
	handle:close()

	if not dir or dir == "" then
		return os.getenv("WALLPAPERS_DIR") or (os.getenv("HOME") .. "/Imágenes")
	end

	return dir
end

-- ⚠ Solo se toca la capitalización de las palabras ASCII PURAS: el Lua de elephant compara
-- por BYTE, así que el patrón viejo `(%a)([%w]*)` cortaba "Imágenes" en la "á" y devolvía
-- "ImáGenes". Ver el comentario largo en wallpapers-root.lua.
local function PrettyName(str)
	local pretty = str:gsub("%.%w+$", ""):gsub("[_-]", " ")

	return (pretty:gsub("%S+", function(word)
		if word:match("^%w+$") then
			return word:sub(1, 1):upper() .. word:sub(2):lower()
		end

		return word
	end))
end

local function CurrentWallpaper()
	local handle = io.popen("wallpaper-set --actual 2>/dev/null")
	if not handle then
		return nil
	end

	local current = handle:read("*l")
	handle:close()

	return current
end

-- ─── Miniaturas (2026-08-15) ───
--
-- Las portadas y los previews son la copia de 720 px que mantiene `wallpaper-thumbs`, no el
-- fondo original. Walker los carga con `gtk_image_set_from_file`, o sea decodifica el archivo
-- COMPLETO: 79 ms por fila con un 6000x4000 contra 2 ms con la miniatura (medido con
-- gdk-pixbuf, el decodificador de GTK). Ver el comentario largo en wallpapers-images.lua.
local thumbs_dir = (os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")) .. "/wallpaper-thumbs"

local faltan = false

local function Thumb(path)
	local thumb = thumbs_dir .. path .. ".jpg"
	local f = io.open(thumb, "r")

	if f then
		f:close()
		return thumb
	end

	faltan = true

	return path
end

local function GenerarFaltantes(dir)
	if faltan then
		os.execute(string.format("wallpaper-thumbs %q >/dev/null 2>&1 &", dir))
	end
end

-- Las imágenes SUELTAS de una carpeta, que es lo que se muestra cuando la raíz ya es una
-- colección. Es a propósito una copia chica de lo que hace `wallpapers-images`: los menús de
-- elephant son archivos Lua sueltos que el servicio carga uno por uno, no hay un módulo común
-- donde poner esto, y las dos listas tienen que verse igual.
--
-- `-maxdepth 1` y no un barrido hondo: acá se llega solo cuando NO hay subcarpetas con
-- imágenes, así que todo lo que hay cuelga directo de la raíz.
local function Imagenes(dir, current)
	local entries = {}

	local command = "find "
		.. string.format("%q", dir)
		.. " -maxdepth 1 -type f "
		.. [[\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) ]]
		.. " 2>/dev/null | sort"

	local handle = io.popen(command)
	if not handle then
		return entries
	end

	local coleccion = dir:match("([^/]+)$") or dir

	for path in handle:lines() do
		local subtext = coleccion
		if path == current then
			subtext = subtext .. " · active"
		end

		local thumb = Thumb(path)

		table.insert(entries, {
			Text = PrettyName(path:match("([^/]+)$")),
			Subtext = subtext,
			-- El Value es el ORIGINAL: la miniatura es para mirar, el fondo que se pone es el
			-- archivo de verdad. Sin `SubMenu`, así que la fila recibe `menus:default` y Return
			-- ejecuta el `Action` del menú.
			Value = path,
			Icon = thumb,
			Preview = thumb,
			State = (path == current) and { "current" } or nil,
		})
	end

	handle:close()

	return entries
end

function GetEntries()
	local entries = {}
	local current = CurrentWallpaper()
	local wallpapers_dir = CurrentRoot()

	faltan = false

	local prune = " -not -path '*/.*/*'"
	for _, dir in ipairs(excluded) do
		prune = prune .. string.format(" -not -path '*/%s/*'", dir)
	end

	-- Un solo find sobre el árbol entero, y el agrupado por carpeta se hace acá. La
	-- alternativa —listar directorios y después un find por cada uno— son 20 procesos en
	-- vez de 1 para la misma información.
	--
	-- `orden` existe además de `carpetas` porque en Lua un table con claves string no tiene
	-- orden de iteración definido: sin esto las colecciones salen distintas cada vez.
	local function Escanear(mindepth)
		local command = "find "
			.. string.format("%q", wallpapers_dir)
			.. string.format(" -mindepth %d -type f ", mindepth)
			.. [[\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) ]]
			.. prune
			.. " 2>/dev/null | sort"

		local carpetas, orden = {}, {}

		local handle = io.popen(command)
		if not handle then
			return carpetas, orden
		end

		for path in handle:lines() do
			local dir = path:match("^(.*)/[^/]+$")

			if dir then
				if not carpetas[dir] then
					-- `muestra` es la primera imagen en orden alfabético: sirve de portada y de
					-- preview de la colección. Alcanza con la primera; abrir la carpeta para
					-- elegir "la más linda" costaría un find por carpeta y no lo vale.
					carpetas[dir] = { cantidad = 0, muestra = path, tiene_actual = false }
					table.insert(orden, dir)
				end

				local c = carpetas[dir]
				c.cantidad = c.cantidad + 1
				if path == current then
					c.tiene_actual = true
				end
			end
		end

		handle:close()

		return carpetas, orden
	end

	local carpetas, orden = Escanear(2)

	-- ─── Carpeta plana: las imágenes, sin nivel intermedio (2026-08-14, rehecho el 2026-08-15) ───
	--
	-- El -mindepth 2 asume una raíz organizada en subcarpetas, que es como está ~/Imágenes.
	-- Desde que la raíz la elige el usuario en `wallpapers-root`, eso dejó de estar
	-- garantizado: apuntarla a una carpeta llena de imágenes SUELTAS mostraba "no hay ninguna
	-- colección" con 300 fondos adentro.
	--
	-- El primer arreglo fue reescanear con -mindepth 1 y presentar la raíz como una colección
	-- de una sola fila. Andaba, pero obligaba a entrar a la carpeta que se acababa de elegir en
	-- `Directorio` — un nivel que solo repite la elección anterior. Ahora se listan las
	-- imágenes directo: Return las aplica, sin entrar a ningún lado.
	--
	-- ~/Imágenes no pasa por acá y sigue sin listar sus 17 descargas random: con subcarpetas, el
	-- primer barrido devuelve las 20 colecciones y este bloque no corre.
	if #orden == 0 then
		local planas = Imagenes(wallpapers_dir, current)

		if #planas > 0 then
			GenerarFaltantes(wallpapers_dir)

			return planas
		end
	end

	for _, dir in ipairs(orden) do
		local c = carpetas[dir]

		-- La ruta RELATIVA a wallpapers_dir, no el nombre de la carpeta: hay `walls/nature`
		-- y también `nord`, y un subtexto que dijera solo "nature" no diría de dónde salió.
		-- Se recorta por posición (largo del prefijo + la barra) y no con un patrón, porque
		-- wallpapers_dir es una ruta arbitraria y podría traer mayúsculas de Lua.
		--
		local rel = dir:sub(#wallpapers_dir + 2)
		local nombre = rel:match("([^/]+)$") or rel

		local subtext = string.format("%s · %d fondos", rel, c.cantidad)
		if c.tiene_actual then
			subtext = subtext .. " · active"
		end

		table.insert(entries, {
			Text = PrettyName(nombre),
			Subtext = subtext,
			-- El Value es la carpeta, y es lo que el nivel 2 lee con lastMenuValue().
			Value = dir,
			-- La portada de la colección. El preview es la misma imagen: una lista de
			-- nombres de carpeta no dice nada de qué hay adentro.
			Icon = Thumb(c.muestra),
			Preview = Thumb(c.muestra),
			-- ⚠ camelCase, ver el comentario de arriba.
			SubMenu = "wallpapers-images",
			State = c.tiene_actual and { "current" } or nil,
			-- La ruta relativa entera como keyword para que "walls" traiga las 17
			-- colecciones del repo y "gruvbox" traiga la suya, desde el índice de `Mod+,`.
			Keywords = { "fondo", "wallpaper", "coleccion", rel },
		})
	end

	-- Con la lista vacía la única salida útil es cambiar de carpeta, así que esa fila LLEVA el
	-- submenú y se devuelve sola: agregarle abajo la fila "Cambiar la carpeta…" sería ofrecer
	-- dos veces lo mismo.
	if #entries == 0 then
		return {
			{
				Text = "No hay fondos en esta carpeta",
				Subtext = "se buscan imágenes en " .. wallpapers_dir .. " — probá con otra carpeta",
				Value = wallpapers_dir,
				Icon = "cs-backgrounds",
				SubMenu = "wallpapers-root",
			},
		}
	end

	GenerarFaltantes(wallpapers_dir)

	-- Acá NO va ninguna fila de "cambiar la carpeta": eso es el menú hermano `Directorio`, a
	-- un nivel para arriba. Esta lista es solo colecciones.
	return entries
end
