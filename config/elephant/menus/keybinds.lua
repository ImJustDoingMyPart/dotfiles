-- Menú de atajos de niri — portado de nickjj/dotfriedrice (.config/elephant/menus/keybinds.lua).
--
-- Parsea los KDL de niri siguiendo los `include`, y lista SOLO los binds que tienen
-- hotkey-overlay-title. Reemplaza el overlay de atajos como lista buscable.
--
-- Se adopta el parser tal cual: ya sigue includes recursivamente, que es justo lo que
-- necesita esta config (config.kdl es solo includes hacia ./cfg/*.kdl).
--
-- ÚNICO cambio contra el original: el fallback de XDG_CONFIG_HOME (ver abajo).

Name = "keybinds"
NamePretty = "Keybinds"
Description = "niri keyboard shortcuts"
Icon = "cs-keyboard"
HideFromProviderlist = true
Action = "niri msg action %VALUE%"
Cache = false

-- Root location of niri configs.
-- ADAPTADO: en esta máquina XDG_CONFIG_HOME no está seteada. El original la concatena
-- sin fallback -> "attempt to concatenate a nil value" y el menú sale vacío sin
-- explicar por qué.
local config_dir = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/niri/"

-- Binds may exist in multiple configs, later definitions overwrite earlier ones.
local binds = {}

-- We'll be regex searching for this in a few spots, we only include binds
-- that have a hotkey title on purpose.
local hotkey_title_attribute = "hotkey%-overlay%-title"

local function ParseConfig(filename)
	local buffer = ""

	local ok, lines = pcall(io.lines, config_dir .. filename)
	if not ok then
		return
	end

	for line in lines do
		-- Strip comments (single and multi-line).
		local clean = line:gsub("//.*$", ""):gsub("/%*.-%*/", "")
		if clean:match("^%s*$") then
			goto continue
		end

		-- Add lines into a buffer to handle multi-line KDL nodes.
		buffer = (buffer == "" and clean or buffer .. " " .. clean)

		-- Recursively handle include directives.
		local include_file = clean:match('^%s*include%s+"([^"]+)"')
		if include_file then
			ParseConfig(include_file)

			-- Prevent include line from corrupting the next bind's buffer.
			buffer = ""

			goto continue
		end

		-- Do we have a hotkey overlay title?
		if buffer:find(hotkey_title_attribute .. '="') then
			local action_block = buffer:match(".*(%b{})")

			if action_block then
				-- Strip KDL wrapper nodes.
				local temp = buffer:gsub("^%s*[%a%-]+%s*{%s*", ""):gsub("^%s*", "")
				local key = temp:match("([^%s={}]+)")
				local title = buffer:match(hotkey_title_attribute .. '="([^"]+)"')

				if key and title and key ~= "binds" then
					-- Collapse whitespace and remove trailing semi-colons.
					local raw = action_block:sub(2, -2):gsub(";%s*$", ""):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")

					-- Handle spawning commands.
					if raw:sub(1, 5) == "spawn" and not raw:find("%-%-") then
						raw = raw:gsub("^spawn%s+", "spawn -- ")
					end

					binds[key] = { title = title, action = raw }
					buffer = ""
				end
			end
		end

		-- Reset buffer if we hit a closing brace without a title.
		if clean:find("}") and not buffer:find(hotkey_title_attribute) then
			buffer = ""
		end

		::continue::
	end
end

function GetEntries()
	binds = {}
	local entries = {}

	-- Start with the main config file.
	ParseConfig("config.kdl")

	for k, v in pairs(binds) do
		table.insert(entries, {
			Text = k,
			Subtext = v.title,
			Value = v.action,
		})
	end

	return entries
end
