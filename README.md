# dotfiles

Setup de escritorio para **CachyOS + [Niri](https://github.com/YaLTeR/niri)** (compositor
tiling scrollable en Wayland). Terminal minimalista (Alacritty + Fish + Starship), barra
Waybar/Ironbar, launcher Walker + Elephant, notificaciones Mako, y todo el theming generado
dinámicamente desde el wallpaper con [matugen](https://github.com/InioX/matugen) (Material You).

## Estructura

```
config/     → mapea a ~/.config/<mismo nombre>
local/bin/  → mapea a ~/.local/bin (scripts propios, deben quedar ejecutables)
```

## Piezas principales

| Área | Config |
|---|---|
| Compositor | `config/niri/` (`config.kdl` + `cfg/*.kdl` + `animations/`) |
| Barra | `config/waybar/` o `config/ironbar/` (uso Ironbar activamente; Waybar queda de referencia) |
| Launcher | `config/walker/` + `config/elephant/` (menús/providers en Lua y TOML) |
| Notificaciones | `config/mako/` |
| Terminal | `config/alacritty/`, `config/kitty/`, `config/fish/`, `config/starship.toml` |
| Herramientas CLI con tema propio | `config/bat/`, `config/yazi/` |
| Theming (Material You) | `config/matugen/` — `config.toml` define qué template genera qué archivo |

## Theming con matugen

El color de cada app (barra, terminal, `bat`, `yazi`, GTK, Qt, notificaciones, etc.) **no
está hardcodeado**: `matugen/config.toml` define, por cada app, un `input_path` (plantilla en
`matugen/templates/`) y un `output_path` (el archivo real que la app lee). Al cambiar de
wallpaper, matugen recompila todas las plantillas y cada app queda con la misma paleta
derivada de esa imagen.

Ese `output_path` (`~/.config/themes/matugen/...`) es contenido **generado**, así que no
viene incluido en este repo — se recrea corriendo matugen con esta config. Varias apps
(`waybar`, `ironbar`, `mako`, `bat`, `yazi`, `alacritty`, `kitty`, `gtk`, `qt5ct`/`qt6ct`,
`swayosd`, `btop`) apuntan a ese archivo generado mediante un symlink en su propia carpeta de
config — symlink que tampoco viene en el repo por lo mismo (apunta a algo que todavía no
existe hasta que corras matugen la primera vez).

## Antes de usar esto

- **Rutas absolutas:** algunos archivos (`matugen/config.toml`, `niri/cfg/keybinds.kdl`,
  `fastfetch/config.jsonc`) tienen rutas absolutas tipo `/home/anon/...` porque el propio
  programa las requiere así (p. ej. `niri spawn` no pasa por un shell, así que no expande
  `$HOME`). Reemplazá `anon` por tu usuario real donde corresponda.
- **`weather-location.example`:** copiá a `~/.config/weather-location` con tus propias
  coordenadas (instrucciones adentro del archivo).
- **Dependencias:** `niri`, `matugen`, `waybar`/`ironbar`, `walker` + `elephant`, `mako`,
  `alacritty`, `fish`, `starship`, `zoxide`, `atuin`, `eza`, `bat`, `fzf`, `yazi`, `chafa`,
  `wl-clipboard`, `jq`.
- Varios scripts en `local/bin/` llaman a otros de la misma carpeta — copiala completa.

## Qué NO está acá (a propósito)

Se dejó afuera todo lo específico de mi red doméstica/homelab (alias SSH, IPs, MACs),
credenciales o URLs privadas (calendario, tokens), historial de shell, bookmarks de archivos
personales, y binarios de terceros que no son configuración.
