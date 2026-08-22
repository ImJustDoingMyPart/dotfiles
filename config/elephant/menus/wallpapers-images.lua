-- Fondos de pantalla → Selector → IMÁGENES de la colección elegida.
--
-- Es UN solo menú para TODAS las colecciones, no uno por carpeta. Qué carpeta mostrar se
-- averigua con `lastMenuValue("wallpapers-select")`, la global de elephant que devuelve el
-- `Value` de la última entrada activada de ese menú — y el `Value` de una entrada del
-- selector es justamente la ruta absoluta de la carpeta.
--
-- La alternativa era generar un archivo de menú por carpeta con un script. Se descartó:
-- serían 20 archivos que hay que regenerar cada vez que aparece una colección nueva, y
-- además **elephant no descubre un menú nuevo sin reiniciar el servicio**, así que agregar
-- una carpeta a ~/Imágenes pasaría a requerir un `systemctl --user restart elephant`. Con
-- lastMenuValue, una carpeta nueva aparece sola en el nivel 1 y funciona sin tocar nada.
--
-- `Parent = "wallpapers-select"` es lo que hace que la flecha IZQUIERDA vuelva a la lista de
-- colecciones. Es la mitad que hace que esto se sienta un navegador de carpetas y no dos
-- menús sueltos.
--
-- Acá sí se ejecuta `wallpaper-set`, que además de poner el fondo recalcula el tema si el
-- activo es el generado. Por eso el menú NO llama a awww directo: cambiar el fondo sin
-- recalcular el color dejaría el sistema a mitad de camino.

Name = "wallpapers-images"
NamePretty = "Colección"
Description = "Los fondos de la colección elegida"
Icon = "cs-backgrounds"
Action = "wallpaper-set %VALUE%"
Cache = false
Parent = "wallpapers-select"

-- No aparece en el providerlist (`;` dentro de walker): solo tiene sentido con una carpeta
-- ya elegida, así que llegar por su cuenta muestra la fila de ayuda de más abajo y nada más.
HideFromProviderlist = true

-- ⚠ Solo se toca la capitalización de las palabras ASCII PURAS: el Lua de elephant compara
-- por BYTE y el patrón viejo partía las palabras con acento. Ver wallpapers-root.lua.
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
-- El ícono y el preview de cada fila NO son el fondo original sino la copia de 720 px que
-- mantiene `wallpaper-thumbs`. Walker carga la imagen con `gtk_image_set_from_file`, o sea
-- decodifica el archivo COMPLETO: con los fondos de esta máquina (6000x4000) son 79 ms por
-- fila, 1,65 s para las 21 de gruvbox, en el hilo de la interfaz — medido con gdk-pixbuf, que
-- es el decodificador que usa GTK. Con la miniatura son 2 ms. Ese era todo el tirón del menú;
-- elephant no tenía nada que ver (la consulta de 603 imágenes tarda 8 ms).
--
-- La regla de la ruta —la del original colgada debajo del cache, más ".jpg"— la implementan
-- por separado este archivo y el script, así que si cambia una hay que cambiar la otra. Es
-- trivial a propósito: el Lua de elephant no tiene MD5 para hacerlo como el cache freedesktop.
local thumbs_dir = (os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")) .. "/wallpaper-thumbs"

-- Se prende cuando alguna fila se tuvo que dibujar con el original. Solo entonces se llama al
-- generador, y en segundo plano: con el cache caliente el menú no lanza ni un proceso, y con
-- el cache frío el `flock -n` del script deja correr uno solo aunque esto se recalcule en cada
-- tecla (`Cache = false`).
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

function GetEntries()
	local entries = {}
	local dir = lastMenuValue("wallpapers-select")

	faltan = false

	-- Pasa cuando se abre este menú sin haber entrado nunca a una colección: por el
	-- providerlist, o después de reiniciar elephant, que se lleva el último valor. Sin esta
	-- fila la lista queda vacía y parece roto.
	if not dir or dir == "" then
		return {
			{
				Text = "Elegí primero una colección",
				Subtext = "Mod+Y, o Mod+, → Apariencia → Fondos de pantalla → Selector",
				Value = "true",
				Icon = "cs-backgrounds",
			},
		}
	end

	local current = CurrentWallpaper()

	-- `-maxdepth 1`: las subcarpetas de esta carpeta son colecciones POR SEPARADO en el
	-- nivel 1 (así aparecen `walls/nature` y `walls/retro` como dos filas). Si acá se
	-- recorriera el árbol, una colección contendría a las otras y el nivel 1 mentiría.
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
		local file = path:match("([^/]+)$")

		local subtext = coleccion
		if path == current then
			subtext = subtext .. " · active"
		end

		local thumb = Thumb(path)

		table.insert(entries, {
			Text = PrettyName(file),
			Subtext = subtext,
			-- El Value sigue siendo el ORIGINAL: la miniatura es para mirar, el fondo que se
			-- pone es el archivo de verdad.
			Value = path,
			-- El preview es la propia imagen: elegir wallpaper de una lista de nombres
			-- no tiene sentido.
			Icon = thumb,
			Preview = thumb,
			State = (path == current) and { "current" } or nil,
		})
	end

	handle:close()

	GenerarFaltantes(dir)

	return entries
end
