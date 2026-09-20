-- ~/.config/hypr/hyprland.lua
-- Configuración modular de Hyprland (0.56.2) en Lua

-- Escala de velocidad de animación global (1.0 = normal)
_G.anim_speed_scale = 1.0

-- 1. Módulos base de configuración
require("cfg.monitors")
require("cfg.input")
require("cfg.layout")
require("cfg.decoration")
require("cfg.rules")
require("cfg.binds")
require("cfg.animation")
require("cfg.events")

-- 2. Módulos intercambiables cargados con pcall (tolerantes si falta el symlink)
--
-- El orden importa: el estilo de sombra va DESPUÉS del tema. El tema pone el color del glow
-- (primary con alfa) y `shadow-styles/black.lua` lo pisa con negro; `colorful-glow.lua` no
-- declara color y deja el del tema. Así cambiar de estilo es reapuntar un symlink y recargar,
-- sin regenerar la paleta ni guardar estado aparte (ver hypr-window-shadow).
pcall(require, "cfg.theme-colors")
pcall(require, "cfg.shadow-style")

-- 3. Preset de animación activo (HyDE en Lua)
pcall(require, "cfg.active-animation")
