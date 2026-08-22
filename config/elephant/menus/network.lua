-- Menú de red (NetworkManager).
--
-- Existe para que el click en el widget de red abra la MISMA clase de superficie que
-- volumen y bluetooth: un menú de walker, no una terminal. nmtui sigue disponible en el
-- click del medio para lo que un menú de acciones atómicas no cubre — escanear, tipear
-- una clave nueva, reintentar.
--
-- Encaja con el criterio de división de superficies del plan: conectarse a una red YA
-- guardada es una acción atómica sobre una lista descubierta -> menú. Dar de alta una red
-- nueva es una sesión -> TUI.
--
-- Igual que en notifications.lua, el parseo lo hace el shell y Lua solo corta por
-- tabulaciones: nmcli con -t ya emite campos separados por ':', así que ni hace falta
-- python.

Name = "network"
NamePretty = "Network"
Description = "Connect and disconnect networks"
-- `network-wireless` vive en devices/ de Papirus-Dark y sale gris, como glifo de línea.
-- El resto del providerlist usa íconos a color de apps/; `cs-network` es el globo azul
-- de esa misma familia. Ver el criterio en ~/.config/elephant/bluetooth.toml.
Icon = "cs-network"
Action = "%VALUE%"
Cache = false

-- `Parent` es lo que hace aparecer el hint `back` abajo en walker y lo que hace que Escape
-- vuelva al índice en vez de cerrar el launcher. NO es decorativo y NO se hereda: cada menú
-- que se llegue desde `menus:system` tiene que declararlo. Ver system.toml.
Parent = "sys-network"

local function sh(cmd)
	local h = io.popen(cmd .. " 2>/dev/null")
	if not h then
		return ""
	end
	local out = h:read("*a") or ""
	h:close()
	return out
end

function GetEntries()
	local entries = {}

	-- El radio wifi primero: si está apagado, ninguna red inalámbrica va a conectar y
	-- conviene que eso se vea antes que la lista.
	local radio = sh("nmcli radio wifi"):gsub("%s+", "")
	local wifi_on = radio == "enabled"

	table.insert(entries, {
		Text = wifi_on and "Wi-Fi: on" or "Wi-Fi: off",
		Subtext = wifi_on and "click to disable the radio" or "click to enable the radio",
		Value = wifi_on and "nmcli radio wifi off" or "nmcli radio wifi on",
		-- El estado apagado NO tiene ícono a color en Papirus: `network-wireless-offline`
		-- solo existe en `panel/` y `symbolic/`, o sea el abanico gris con la X — el mismo
		-- defecto que arregló el criterio de bluetooth.toml. Ninguna variante de `apps/`
		-- dice "wifi apagado" (las de red son todas el globo azul; `network-firewall` es un
		-- muro de ladrillos). Así que el ícono es propio y vive en
		-- ~/.local/share/icons/hicolor/scalable/apps/network-wireless-offline-color.svg:
		-- el círculo y las sombras salen recortados de `cs-network.svg`, el glifo del
		-- abanico+X es el de `panel/network-wireless-offline.svg` escalado, y el rojo es el
		-- #f44336 que la propia Papirus usa como NegativeText. hicolor es el fallback que
		-- GTK mira después del tema, así que el nombre lleva sufijo `-color` para no chocar
		-- con el `network-wireless-offline` de Papirus, que ganaría siempre.
		Icon = wifi_on and "cs-network" or "network-wireless-offline-color",
		State = wifi_on and { "current" } or nil,
		Keywords = { "wifi", "radio", "wireless", "inalambrica" },
	})

	-- `-t` da salida separada por ':' pensada para scripts. Se piden solo los campos que
	-- se usan, en orden fijo.
	for line in sh("nmcli -t -f NAME,TYPE,DEVICE connection show"):gmatch("[^\n]+") do
		local name, ctype, device = line:match("^(.-):([^:]*):([^:]*)$")

		-- Se filtran loopback y bridges: `lo`, `docker0` y los `br-*` de Docker aparecen
		-- como conexiones pero no son redes que uno elija. Dejarlas convierte la lista en
		-- ruido.
		if name and ctype ~= "loopback" and ctype ~= "bridge" then
			local activa = device ~= nil and device ~= ""
			local wireless = ctype:find("wireless") ~= nil

			table.insert(entries, {
				Text = name,
				Subtext = activa and ("conectada · " .. device) or (wireless and "Wi-Fi" or "cableada"),
				-- Sobre la activa, la acción útil es desconectar; sobre el resto, conectar.
				Value = activa
					and string.format("nmcli connection down %q", name)
					or string.format("nmcli connection up %q", name),
				Icon = wireless and "cs-network" or "network-wired",
				State = activa and { "current" } or nil,
			})
		end
	end

	return entries
end
