# dotfiles

Setup de escritorio Wayland para **[Hyprland](https://hypr.land)** (versión 0.56 modular
configurada íntegramente en **Lua**), armado sobre CachyOS pero pensado para cualquier distro
de la **familia Arch** (ver más abajo qué tan atado está a eso).

Diseñado con dos prioridades: **fluidez absoluta** (atajos inmediatos sin forks ni procesos
pesados, juegos aislados en su propio workspace con direct scanout) y **cohesión visual
estricta** (geometría compartida, degradé bicolor característico `primary → tertiary` a 45°
en superficies flotantes, y un sistema híbrido de temas que sincroniza cada programa desde el
wallpaper con [matugen](https://github.com/InioX/matugen) o permite alternar a temas estáticos
curados como Gruvbox).

## Demo

[Ver el video](https://github.com/ImJustDoingMyPart/dotfiles/releases/download/demo/dotfiles-demo-matugen.mp4) <!-- TODO: reemplazar por el embed real (user-attachments) -->

Terminal (Kitty), Waybar, Rofi (`system-index` + calculadora + atajos), selector de fondos en
GTK4 layer-shell (`fondos-selector`), centro de control SwayNC, SwayOSD, Yazi, Nautilus, Brave
y pantalla de bloqueo (Hyprlock), todos con la misma paleta generada dinámicamente por matugen.

## Instalación

```sh
git clone https://github.com/ImJustDoingMyPart/dotfiles.git
cd dotfiles
./install.sh          # symlinkea config/ -> ~/.config y local/bin/ -> ~/.local/bin
./install.sh --copy   # o copia en vez de symlinkear, si preferís no depender del repo
```

Lo que ya exista en destino se respalda automáticamente (con timestamp en `~/dotfiles-backup-*`)
antes de reemplazarlo, así que nunca pisa nada en silencio. También adapta las rutas absolutas a
tu `$HOME` real si tu usuario no es `anon`.

Instalá las dependencias antes (lista más abajo) — el script no instala paquetes de sistema.

## Estructura

```
config/     → mapea a ~/.config/<mismo nombre>
local/bin/  → mapea a ~/.local/bin (scripts propios ejecutables del entorno)
zshenv      → mapea a ~/.zshenv (zsh lee esa ruta fija siempre)
install.sh  → instalador interactivo o por flags
```

## Piezas principales

| Área | Herramienta | Config |
|---|---|---|
| **Compositor** | Hyprland 0.56.2 | `config/hypr/` (`hyprland.lua`, `cfg/*.lua`, `animations/*.lua`) |
| **Sesión / Entorno** | uwsm | `config/uwsm/env` (variables de entorno de sesión gráfica y Qt) |
| **Barra de estado** | Waybar | `config/waybar/` (`config.jsonc`, `style.css` y módulos propios) |
| **Launcher y Menús** | Rofi (Wayland) | `config/rofi/` (`config.rasi`, `layout.rasi`, `scripts/system-index`) |
| **Notificaciones** | SwayNC | `config/swaync/` (`config.json`, `style.css` con widgets de control) |
| **OSD (vol/brillo)** | SwayOSD | `config/swayosd/` (`style.css` coordinado con los toasts de SwayNC) |
| **Bloqueo / Idle** | Hyprlock + Hypridle | `config/hypr/hyprlock.conf`, `config/hypr/hypridle.conf` |
| **Motor de temas** | Matugen + switcher | `config/matugen/` y `config/themes/` (`theme-set`, `theme-reload`) |
| **Terminal** | Kitty | `config/kitty/` (`kitty.conf`) |
| **Shell** | Fish / Zsh + Starship | `config/fish/`, `config/zsh/`, `config/starship.toml` |
| **Herramientas CLI** | Yazi, Bat, Btop, Micro | `config/yazi/`, `config/bat/`, `config/btop/`, `config/micro/` |
| **Banner de shell** | Fastfetch | `config/fastfetch/` (`config.jsonc` + `ascii_art.txt`) |
| **Gaming / Overlay** | MangoHud | `config/MangoHud/` (`MangoHud.conf`) |
| **Hardware RGB** | OpenRGB | `config/OpenRGB/` (perfiles `synthwave.json`) |
| **Apariencia Qt/GTK** | qt5ct, qt6ct, GTK 3/4 | `config/qt5ct/`, `config/qt6ct/`, `config/gtk-3.0/`, `config/gtk-4.0/` |

`fish/` y `zsh/` son equivalentes e independientes: usá el que prefieras como login shell.

## Arquitectura de Hyprland (Lua modular)

Desde Hyprland 0.56, la configuración se expresa en Lua (`hyprland.lua`), ganando lógica nativa
sin invocar subprocesos:

- **`run_or_cycle` en Lua puro**: Los atajos de aplicación (`Mod+Return` terminal, `Mod+B` navegador,
  `Mod+E` yazi, `Mod+Shift+E` Nautilus, `Mod+Z` Vesktop, `Mod+S` Steam) enfocan la ventana si ya existe
  —ciclando ordenadamente entre sus instancias— o la lanzan si no. Al estar implementado como función
  interna en `cfg/binds.lua`, el cambio de foco ocurre con **latencia cero** (sin forks, sin `hyprctl`
  ni pipes de `jq`).
- **Workspace de juegos (`Mod+0`)**: `cfg/rules.lua` envía automáticamente los juegos al workspace 10,
  permitiendo volver al escritorio y regresar al juego con `Mod+0` instantáneamente sin romper la
  pantalla completa ni perder direct scanout.
- **18 Presets de Animación intercambiables**: `config/hypr/animations/` incluye 18 curvas y ritmos
  optimizados (`vertical`, `classic`, `fast`, `gnome`, `macos`, `moving`, etc.). Se alternan al vuelo
  desde Rofi o con `hypr-animation <preset>`.
- **Estilos de Sombra**: `hypr-window-shadow` conmuta entre sombra negra neutra (`black`) y resplandor
  teñido por el acento del tema (`colorful-glow`).

## Rofi y el índice del sistema (`Mod+Comma`)

Rofi reemplaza launchres pesados y centraliza la interacción modal:
- **`Mod+Space`**: Lanzador de aplicaciones (`drun`).
- **`Mod+C`**: Calculadora interactiva instantánea vía `rofi-calc` (con `libqalculate`).
- **`Mod+V`**: Historial de portapapeles con `cliphist`.
- **`Mod+Comma`**: Menú integral del sistema (`system-index`):
  - Selector de fondos con miniaturas visuales (`fondos-selector`, ventana nativa en GTK4 layer-shell).
  - Selector de temas (`theme-set`).
  - Selector de animaciones (`hypr-animation`).
  - Salidas de audio y perfiles PipeWire.
  - Red WiFi y dispositivos Bluetooth.
  - Cheatsheet de atajos de teclado leídos en vivo de Hyprland.
- **`Mod+Escape`**: Menú de apagado y sesión (`rofi-power-menu`).

## Motor de temas híbrido (Material You + Curados)

El color no está hardcodeado en ningún componente:
1. **Tema generado (`matugen`)**: Al cambiar el fondo (`wallpaper-set <imagen>`), matugen extrae
   la paleta Material You tonal y renderiza 20 plantillas (`config/matugen/templates/`) hacia
   `~/.config/themes/matugen/`.
2. **Temas fijos curados**: Soporte de temas estáticos (como `gruvbox-dark-medium` en
   `config/themes/gruvbox-dark-medium/`).
3. **Switcher (`theme-set <tema>`)**: Reapunta symlinks hacia el tema elegido sin que las apps
   tengan que conocer la existencia del switcher.
4. **Recarga en caliente (`theme-reload`)**: Notifica a los programas en ejecución de forma
   idempotente (`swaync-client --reload-css`, `pkill -SIGUSR1 kitty`, `hyprctl reload config-only`,
   `systemctl --user try-restart swayosd.service`, `starship-palette-apply`, inyección en Obsidian y
   Antigravity IDE).

## Qué es específico de Arch/CachyOS

La gran mayoría de los archivos son estándares de Wayland y proyectos upstream. Los puntos
particulares para familia Arch son:

| Dónde | Qué hace | Adaptación a otras distros |
|---|---|---|
| `fish/config.fish` | `source /usr/share/cachyos-fish-config/cachyos-config.fish` | Comentar si no estás en CachyOS |
| `fish/config.fish`, `zsh/.zshrc` | `alias update='paru -Syu'` | Reemplazar por `dnf`, `apt`, `zypper` o `pacman` |
| `local/bin/desktop-orphans` | Resuelve dueños de `.desktop` huérfanos con `pacman -Qo` | Específico de pacman |

## Dependencias principales

- **Compositor y sesión:** `hyprland` (≥ 0.56.2), `uwsm`, `greetd` (opcional para autologin), `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`.
- **Barra, menús y OSD:** `waybar`, `rofi-wayland`, `rofi-calc`, `swaync`, `swayosd-git` (o binario), `cliphist`.
- **Bloqueo y fondo:** `hyprlock`, `hypridle`, `awww` (o daemon de wallpaper compatible), `imagemagick`.
- **Theming:** `matugen-bin` (v4.x), `python`, `jq`.
- **Terminal y CLI:** `kitty`, `fish` y/o `zsh`, `starship`, `yazi`, `bat`, `btop`, `micro`, `fastfetch`, `eza`, `fzf`, `zoxide`.
- **Audio y hardware:** `pipewire`, `wireplumber`, `libqalculate`, `ddcutil` (para brillo DDC de monitor), `openrgb`.

## Antes de usar

1. **`weather-location.example`**: Copiá a `~/.config/weather-location` con tus coordenadas de latitud/longitud para el widget del clima en Waybar.
2. **Aplicar tema inicial**:
   ```sh
   wallpaper-set ~/Imágenes/walls/tu_fondo.jpg
   # o bien:
   theme-set gruvbox-dark-medium
   ```

## Qué NO está acá (a propósito)

Siguiendo el principio de fotografía curada del sistema, se dejaron deliberadamente afuera:
credenciales, URLs privadas (calendarios ICS), historial de terminal, bases de datos locales,
tokens de autenticación, y binarios personales o scrapers específicos de trabajo.
