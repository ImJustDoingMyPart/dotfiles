# dotfiles

Setup de escritorio para **CachyOS + [Niri](https://github.com/YaLTeR/niri)** (compositor
tiling scrollable en Wayland). Terminal minimalista (Alacritty + Fish + Starship), barra
Waybar/Ironbar, launcher Walker + Elephant, notificaciones Mako, y todo el theming generado
dinámicamente desde el wallpaper con [matugen](https://github.com/InioX/matugen) (Material You).

## Demo

<video src="https://github.com/ImJustDoingMyPart/dotfiles/releases/download/demo/dotfiles-demo-matugen.mp4" controls width="100%"></video>

Terminal, Ironbar + Walker, Yazi, una notificación de Mako, Obsidian, Nautilus y Brave, todos
con la misma paleta generada por matugen.

## Instalación

```sh
git clone https://github.com/ImJustDoingMyPart/dotfiles.git
cd dotfiles
./install.sh          # symlinkea config/ -> ~/.config y local/bin/ -> ~/.local/bin
./install.sh --copy   # o copia en vez de symlinkear, si preferís no depender del repo
```

Lo que ya exista en destino se respalda (con timestamp) antes de reemplazarlo, así que no pisa
nada en silencio. También adapta automáticamente las rutas absolutas (ver más abajo) a tu
usuario real. Instalá las dependencias antes (lista más abajo) — el script no instala paquetes.

## Estructura

```
config/     → mapea a ~/.config/<mismo nombre>
local/bin/  → mapea a ~/.local/bin (scripts propios, deben quedar ejecutables)
install.sh  → instalador (ver arriba)
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

## Qué es específico de Arch/CachyOS

La mayor parte de este repo es config de proyectos upstream (niri, waybar/ironbar, walker,
mako, matugen, alacritty/kitty, starship, bat, yazi, btop, MangoHud, GTK, Qt, swayosd, micro):
no le importa la distro, solo que el paquete esté instalado. Los puntos que sí asumen
Arch/CachyOS son estos cuatro:

| Dónde | Qué hace | Alcance |
|---|---|---|
| `fish/config.fish` | `source /usr/share/cachyos-fish-config/cachyos-config.fish` | Solo CachyOS — en otra distro esa ruta no existe |
| `fish/config.fish` | `alias update='paru -Syu'` | Familia Arch (necesita un AUR helper) |
| `elephant/menus/sys-system.toml` | Entrada "Paquetes de Arch", usa el provider `archlinuxpkgs` de walker | Solo Arch |
| `local/bin/desktop-orphans`, `icon-set`, `mpris-ctl` | Resuelven qué paquete es dueño de un archivo con `pacman -Qo` | Familia Arch |

Para otra distro: comentá o envolvé en un `if test -f ...` la línea de `cachyos-config.fish`, y
cambiá `update`/las llamadas a `pacman -Qo` por el equivalente de tu gestor de paquetes.

## Antes de usar esto

- **`weather-location.example`:** copiá a `~/.config/weather-location` con tus propias
  coordenadas (instrucciones adentro del archivo) — `install.sh` no lo pisa si ya existe.
- **Dependencias:** `niri`, `matugen`, `waybar`/`ironbar`, `walker` + `elephant`, `mako`,
  `alacritty`, `fish`, `starship`, `zoxide`, `atuin`, `eza`, `bat`, `fzf`, `yazi`, `chafa`,
  `wl-clipboard`, `jq`.

## Qué NO está acá (a propósito)

Se dejó afuera todo lo específico de mi red doméstica/homelab (alias SSH, IPs, MACs),
credenciales o URLs privadas (calendario, tokens), historial de shell, bookmarks de archivos
personales, y binarios de terceros que no son configuración.
