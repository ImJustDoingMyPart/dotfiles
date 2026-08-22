-- Fondos de pantalla → DIRECTORIO: en qué carpeta se buscan los fondos.
--
-- No es un navegador del sistema de archivos: es una LISTA DE CANDIDATAS que se arma sola,
-- centrada en la raíz vigente. Return fija la elegida; no hay que entrar y salir de carpetas.
--
-- Qué se ofrece, en este orden:
--
--   1. la raíz actual (marcada),
--   2. subir a la carpeta que la contiene,
--   3. las subcarpetas de la actual que tengan imágenes — así "que rote solo entre los nord"
--      es un Return, y de paso la lista se re-centra sola en la carpeta nueva: eligiendo dos
--      veces se baja dos niveles sin que esto sea un navegador,
--   4. las carpetas de ~ con imágenes,
--   5. los puntos de montaje, que se ofrecen SIN explorar (ver abajo).
--
-- ─── Lo que NO se escanea, y es lo importante ───
--
-- `/mnt/archivos_server` es un CIFS del server montado por **autofs**. Un `find` recursivo
-- ahí sería lento por la red y, peor, TOCARLO DISPARA EL MONTAJE: el menú provocaría una
-- conexión al server cada vez que se abre. Por eso los montajes se listan con un `ls` del
-- directorio padre —que no los toca— y aparecen sin contador. El día que se elige uno como
-- raíz, ahí sí se escanea: eso ya es una decisión explícita.
--
-- El barrido de ~ va con `-maxdepth 3` (10 ms medidos; con 4 son 76 ms). Como este menú se
-- recalcula en CADA TECLA que se tipea —`Cache = false`—, el costo por consulta importa más
-- que la exactitud del contador. Un fondo más hondo no se cuenta y la fila igual aparece.

Name = "wallpapers-root"
NamePretty = "Directorio de fondos"
Description = "En qué carpeta se buscan los wallpapers"
Icon = "folder-pictures"
Cache = false
Parent = "wallpapers"

-- El orden es el de la lista de arriba (actual → subir → cerca → lejos), no el alfabético.
FixedOrder = true

-- Return fija la carpeta. Ninguna fila declara `SubMenu`, así que la acción por defecto del
-- menú es la única que hay: no hace falta tocar los binds de walker.
Action = "wallpaper-root-set %VALUE%"

local home = os.getenv("HOME")

-- Carpetas que tienen imágenes pero no son fondos. Es la misma lista que wallpapers-select y
-- que wallpaper-rotate; si cambia una, cambian las tres.
local excluded = { "Screenshots", "Fastfetch" }

-- Debajo de esto una carpeta no se ofrece: con una o dos imágenes es una carpeta cualquiera
-- que tiene un PNG adentro, no una carpeta de fondos.
local minimo = 3

local find_images = [[\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) ]]

-- ⚠ Solo se toca la capitalización de las palabras ASCII PURAS. El Lua de elephant no tiene
-- soporte de UTF-8: sus clases de patrones son por BYTE, así que `(%a)([%w]*)` sobre
-- "Imágenes" corta en la "á" (dos bytes, ninguno es %a) y devuelve "ImáGenes" — pasó el
-- 2026-08-14 en la primera fila de este menú. Una palabra con acento se deja como está: los
-- nombres reales de carpeta ya vienen bien escritos, y no hay forma barata de hacerlo bien.
local function PrettyName(str)
	local pretty = str:gsub("[_-]", " ")

	return (pretty:gsub("%S+", function(word)
		if word:match("^%w+$") then
			return word:sub(1, 1):upper() .. word:sub(2):lower()
		end

		return word
	end))
end

local function Plural(n, singular, plural)
	return string.format("%d %s", n, n == 1 and singular or plural)
end

-- La raíz vigente. Se le pregunta al script en vez de leer el archivo a mano para no duplicar
-- acá la lógica del default y del "la carpeta guardada ya no existe".
local function CurrentRoot()
	local handle = io.popen("wallpaper-root-set --actual 2>/dev/null")
	if not handle then
		return home .. "/Imágenes"
	end

	local dir = handle:read("*l")
	handle:close()

	return (dir and dir ~= "") and dir or (home .. "/Imágenes")
end

-- ─── Miniaturas (2026-08-15) ───
--
-- Las portadas de las filas son la copia de 720 px que mantiene `wallpaper-thumbs`, no el
-- fondo original: walker decodifica el archivo entero para dibujarlas (79 ms por fila con un
-- 6000x4000, 2 ms con la miniatura) y este menú se recalcula en CADA TECLA. Ver el comentario
-- largo en wallpapers-images.lua; la regla de la ruta la implementan las dos mitades por
-- separado y tiene que coincidir con la del script.
local thumbs_dir = (os.getenv("XDG_CACHE_HOME") or (home .. "/.cache")) .. "/wallpaper-thumbs"

local faltan = false

local function Thumb(path)
	if not path then
		return nil
	end

	local thumb = thumbs_dir .. path .. ".jpg"
	local f = io.open(thumb, "r")

	if f then
		f:close()
		return thumb
	end

	faltan = true

	return path
end

-- Acá se generan las de la RAÍZ VIGENTE nada más, aunque el menú muestre también carpetas de ~
-- y montajes. Es deliberado: barrer /mnt o el home entero por una portada que se ve un segundo
-- costaría más que el problema que resuelve, y esas filas caen al original sin romperse.
local function GenerarFaltantes(dir)
	if faltan then
		os.execute(string.format("wallpaper-thumbs %q >/dev/null 2>&1 &", dir))
	end
end

-- Un solo find por carpeta base, y el agrupado por subcarpeta de primer nivel se hace acá.
-- Devuelve, por subcarpeta: cuántas imágenes cuelgan y cuál es la PRIMERA (la portada). Más
-- el mismo par para las imágenes sueltas de la base.
--
-- El `| sort` no es cosmético: sin él, el orden que devuelve find depende del sistema de
-- archivos, así que la portada de cada fila cambiaría de una apertura a la otra. Es el mismo
-- motivo por el que el Selector ordena.
local function Escanear(base, maxdepth)
	local por_sub, sueltas, muestra_base = {}, 0, nil

	local prune = " -not -path '*/.*/*' -not -path '*/.*'"
	for _, dir in ipairs(excluded) do
		prune = prune .. string.format(" -not -path '*/%s/*'", dir)
	end

	local command = "find "
		.. string.format("%q", base)
		.. string.format(" -mindepth 1 -maxdepth %d -type f ", maxdepth)
		.. find_images
		.. prune
		.. " 2>/dev/null | sort"

	local handle = io.popen(command)
	if not handle then
		return por_sub, sueltas, muestra_base
	end

	local prefijo = #base + 2

	for path in handle:lines() do
		local rel = path:sub(prefijo)
		local sub = rel:match("^([^/]+)/")

		if sub then
			if not por_sub[sub] then
				por_sub[sub] = { cantidad = 0, muestra = path }
			end

			por_sub[sub].cantidad = por_sub[sub].cantidad + 1
		else
			sueltas = sueltas + 1
			muestra_base = muestra_base or path
		end
	end

	handle:close()

	return por_sub, sueltas, muestra_base
end

-- Las claves de una tabla Lua no tienen orden de iteración definido: sin esto las filas
-- salen distintas en cada apertura.
local function Ordenadas(tabla)
	local claves = {}

	for k in pairs(tabla) do
		table.insert(claves, k)
	end

	table.sort(claves)

	return claves
end

-- Listado NO recursivo, que es lo que hace seguro mirar /mnt: un `ls` del padre no toca los
-- montajes de autofs que cuelgan de él.
local function HijosDirectos(base)
	local dirs = {}

	local handle = io.popen("find " .. string.format("%q", base) .. " -mindepth 1 -maxdepth 1 -type d -not -name '.*' 2>/dev/null | sort")
	if not handle then
		return dirs
	end

	for path in handle:lines() do
		table.insert(dirs, path)
	end

	handle:close()

	return dirs
end

function GetEntries()
	local entries = {}
	local root = CurrentRoot()

	faltan = false

	-- `vistas` evita que una misma carpeta aparezca dos veces: la raíz suele ser hija de ~, y
	-- sus subcarpetas pueden volver a salir en el barrido del home.
	local vistas = { [root] = true }

	-- ─── 1. La raíz actual ───
	local por_sub_root, sueltas_root, muestra_root = Escanear(root, 3)
	local subcarpetas, total = 0, sueltas_root

	for _, c in pairs(por_sub_root) do
		subcarpetas = subcarpetas + 1
		total = total + c.cantidad
	end

	-- La portada de la carpeta actual sale de su PRIMERA SUBCARPETA, y las imágenes sueltas
	-- son el fallback — no al revés. En ~/Imágenes las sueltas son las 17 descargas random que
	-- el Selector ni siquiera lista, así que usarlas de portada sería representar la carpeta
	-- con lo único que no son fondos.
	local primeras = Ordenadas(por_sub_root)

	if primeras[1] then
		muestra_root = por_sub_root[primeras[1]].muestra
	end

	-- Se habla de "imágenes" y "subcarpetas", NO de "fondos" y "colecciones": este menú cuenta
	-- archivos crudos hasta 3 niveles, mientras que el Selector agrupa por carpeta hoja a
	-- cualquier profundidad. Los dos números no coinciden y no tienen por qué — acá se
	-- responde "¿hay algo en esta carpeta?", no "¿qué colecciones voy a ver?". Con el
	-- vocabulario separado, la diferencia no se lee como un error.
	local resumen
	if total == 0 then
		resumen = "sin imágenes"
	elseif subcarpetas == 0 then
		resumen = Plural(total, "imagen suelta", "imágenes sueltas")
	else
		resumen = Plural(total, "imagen", "imágenes") .. " en " .. Plural(subcarpetas, "subcarpeta", "subcarpetas")
	end

	table.insert(entries, {
		Text = "Carpeta actual · " .. PrettyName(root:match("([^/]+)$") or root),
		Subtext = root .. " · " .. resumen,
		Value = root,
		Icon = Thumb(muestra_root) or "cs-backgrounds",
		Preview = Thumb(muestra_root),
		State = { "current" },
		Keywords = { "actual", "current", "raiz" },
	})

	-- ─── 2. Subir ───
	local padre = root:match("^(.*)/[^/]+$")

	if padre and padre ~= "" and not vistas[padre] then
		vistas[padre] = true

		-- Fila DELIBERADAMENTE GENÉRICA: nombre fijo, ícono fijo, subtexto fijo. No lleva ni el
		-- nombre de la carpeta destino ni una portada suya.
		--
		-- El motivo es que esta fila no es un destino más de la lista: es el control de
		-- navegación. Si cambiara de nombre y de miniatura según dónde estés parado, dejaría de
		-- reconocerse de un golpe de vista, que es lo único que tiene que hacer. Todas las
		-- demás filas son carpetas concretas y por eso sí llevan su portada.
		--
		-- `folder-open` resuelve a `places/48x48` (verificado renderizando con GtkIconTheme, que
		-- es la regla de H5) y es la carpeta abierta de Papirus: misma familia visual que el
		-- resto, y se distingue a simple vista de las miniaturas de fotos. NO se usa `go-up` ni
		-- `go-parent-folder`: los dos caen en `actions/24x24@2x`, que es la familia que H5 sacó
		-- de todos los menús por fea.
		table.insert(entries, {
			Text = "Subir un nivel…",
			Subtext = "la carpeta que contiene a la actual",
			Value = padre,
			Icon = "folder-open",
			Keywords = { "subir", "arriba", "padre", "up", "nivel" },
		})
	end

	-- ─── 3. Subcarpetas de la actual ───
	for _, nombre in ipairs(Ordenadas(por_sub_root)) do
		local path = root .. "/" .. nombre
		local c = por_sub_root[nombre]

		if c.cantidad >= minimo and not vistas[path] then
			vistas[path] = true

			table.insert(entries, {
				Text = PrettyName(nombre),
				Subtext = Plural(c.cantidad, "imagen", "imágenes") .. " · dentro de la carpeta actual",
				Value = path,
				-- La portada, igual que en el Selector: una lista de nombres de carpeta no
				-- dice nada de qué hay adentro, y un ícono de carpeta genérico repetido 12
				-- veces dice todavía menos.
				Icon = Thumb(c.muestra),
				Preview = Thumb(c.muestra),
				Keywords = { nombre, "subcarpeta", "coleccion" },
			})
		end
	end

	-- ─── 4. Carpetas de ~ ───
	local por_sub_home = Escanear(home, 3)

	for _, nombre in ipairs(Ordenadas(por_sub_home)) do
		local path = home .. "/" .. nombre
		local c = por_sub_home[nombre]

		if c.cantidad >= minimo and not vistas[path] then
			vistas[path] = true

			table.insert(entries, {
				Text = PrettyName(nombre),
				Subtext = Plural(c.cantidad, "imagen", "imágenes") .. " · en tu carpeta personal",
				Value = path,
				Icon = Thumb(c.muestra),
				Preview = Thumb(c.muestra),
				Keywords = { nombre, "home", "personal" },
			})
		end
	end

	-- ─── 5. Montajes, sin explorar ───
	local bases = { "/mnt", "/run/media/" .. (os.getenv("USER") or "") }

	for _, base in ipairs(bases) do
		for _, path in ipairs(HijosDirectos(base)) do
			if not vistas[path] then
				vistas[path] = true

				table.insert(entries, {
					Text = PrettyName(path:match("([^/]+)$") or path),
					Subtext = path .. " · disco o montaje · no se explora solo",
					Value = path,
					Icon = "drive-harddisk",
					Keywords = { "disco", "montaje", "mount", "usb", "server" },
				})
			end
		end
	end

	GenerarFaltantes(root)

	return entries
end
