-- Menú de acciones de mouse de Waybar — portado de nickjj/dotfriedrice.
--
-- Lee config.jsonc y lista qué hace cada click en cada módulo. Resuelve el problema
-- real de una barra con muchos on-click: no hay forma de descubrirlos sin abrir el
-- archivo. Acá además son ejecutables desde el menú.
--
-- ÚNICO cambio contra el original: el fallback de XDG_CONFIG_HOME (ver abajo).

Name = "waybar"
NamePretty = "Waybar"
Description = "Mouse actions for the bar"
Icon = "cs-mouse"
HideFromProviderlist = true
Action = "%VALUE%"
Cache = false

-- ADAPTADO: mismo caso que keybinds.lua — XDG_CONFIG_HOME no está seteada acá y el
-- original concatena nil.
local config_dir = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local config = io.open(config_dir .. "/waybar/config.jsonc", "r")

function GetEntries()
	if not config then
		return {}
	end

	local content = config:read("*all")
	config:close()

	local entries = {}

	-- Strip single and multi-line comments.
	content = content:gsub("\n%s*//[^\n]*", ""):gsub("/%*.-%*/", ""):gsub("%\n", " ")

	-- These aren't normal commands we can execute, they are internal to Waybar,
	-- we'll still display them but won't run them.
	-- ADAPTADO: se suman mode, shift_up y shift_down, que son las acciones internas del
	-- módulo clock que usa nuestra config.jsonc (`man 5 waybar-clock`, tabla Actions).
	-- Sin esto el menú intenta ejecutar "mode" como si fuera un comando de shell.
	local module_action = {
		tz_up = 1,
		tz_down = 1,
		activate = 1,
		toggle = 1,
		mode = 1,
		shift_up = 1,
		shift_down = 1,
	}

	local on_event_map = {
		["on-click"] = "Left Click",
		["on-click-right"] = "Right Click",
		["on-click-middle"] = "Middle Click",
		["on-click-backward"] = "Backward Click",
		["on-click-forward"] = "Forward Click",
		["on-scroll-up"] = "Scroll Up",
		["on-scroll-down"] = "Scroll Down",
	}

	-- Parse module blocks: "name": { ... }
	for mod, block in content:gmatch('"([^"]+)":%s*(%b{})') do
		if not mod:find("^modules%-") then
			-- Parse keys: "on-click": "command"
			for key, command in block:gmatch('"([^"]+)":%s*"%s*(.-)%s*"[%s,}]') do
				local label = on_event_map[key]

				if not label then
					goto continue
				end

				-- Unescape escaped JSON slashes.
				local cmd_parsed = command:gsub('\\"', '"')

				local text = mod:gsub("^%l", string.upper)
				local sub_text = cmd_parsed
				local value = sub_text
				local icon = Icon

				if module_action[cmd_parsed] ~= nil then
					sub_text = "(Module Action) " .. sub_text
					value = ""
					icon = "cs-details"
				end

				table.insert(entries, {
					Text = text .. ": " .. label,
					Subtext = sub_text,
					Value = value,
					Icon = icon,
				})

				::continue::
			end
		end
	end

	return entries
end
