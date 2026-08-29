# dotfiles

Setup de escritorio para **[Niri](https://github.com/YaLTeR/niri)** (compositor tiling
scrollable en Wayland), armado sobre CachyOS pero pensado para cualquier distro de
**familia Arch** (ver más abajo qué tan atado está a eso, que es poco). Terminal minimalista
(Kitty + Fish/Zsh + Starship), barra ~~Ironbar~~Waybar, launcher Walker + Elephant,
notificaciones Mako, pantalla de bloqueo Hyprlock/Hypridle, y todo el theming generado
dinámicamente desde el wallpaper con [matugen](https://github.com/InioX/matugen) (Material You).

## Demo

[Ver el video](https://github.com/ImJustDoingMyPart/dotfiles/releases/download/demo/dotfiles-demo-matugen.mp4) <!-- TODO: reemplazar por el embed real (user-attachments) -->

Terminal, Ironbar + Walker, Yazi, una notificación de Mako, Obsidian, Nautilus, Brave y la
pantalla de bloqueo (Hyprlock), todos con la misma paleta generada por matugen.

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
zshenv      → mapea a ~/.zshenv (zsh lee esa ruta fija siempre; ver "Piezas principales")
install.sh  → instalador (ver arriba)
```

## Piezas principales

| Área | Config |
|---|---|
| Compositor | `config/niri/` (`config.kdl` + `cfg/*.kdl` + `animations/`) |
| Barra | `config/waybar/` o `config/ironbar/` (vuelta a Waybar activamente desde 2026-08-25; Ironbar queda instalado pero de referencia) |
| Launcher | `config/walker/` + `config/elephant/` (menús/providers en Lua y TOML) |
| Notificaciones | `config/mako/` |
| Terminal | `config/kitty/`, `config/fish/` y/o `config/zsh/`, `config/starship.toml` |
| Herramientas CLI con tema propio | `config/bat/`, `config/yazi/` |
| Bloqueo de pantalla / idle | `config/hypr/` (`hyprlock.conf` + `hypridle.conf` — sí, con niri; hyprlock/hypridle son standalone) |
| Banner de shell | `config/fastfetch/` (`config.jsonc` + `ascii_art.txt`, el logo de la izquierda) |
| Theming (Material You) | `config/matugen/` — `config.toml` define qué template genera qué archivo |

`fish/` y `zsh/` son equivalentes e independientes — instalá el que uses, el otro no molesta si
queda ahí sin usarse (ninguno se auto-invoca).

Kitty es la terminal en uso (hubo una etapa con Alacritty en paralelo; se descartó porque el
soporte de imágenes en las previews de Yazi/`chafa` rendía peor que en Kitty). No queda config
de Alacritty en este repo.

## Animaciones de niri (elegirlas desde Walker)

`config/niri/animations/` tiene varios packs (`.kdl`) intercambiables — no hay que editar
`config.kdl` a mano para cambiar de animación. El menú **Animations** de Walker
(`config/elephant/menus/animations.lua`) lista los packs de esa carpeta y aplica el elegido
con `local/bin/niri-animation`, que reescribe el `include` de `config/niri/animations.kdl` y
lo valida antes de dejarlo. `config/niri/cfg/animation.kdl` es el pack base (fallback) que se
incluye después.

Los packs no son míos: son de
[niri-animation-collection](https://github.com/jgarza9788/niri-animation-collection) (MIT),
de Justin Garza y colaboradores — cada `.kdl` trae su autoría en el propio header del archivo.

## Theming con matugen

El color de cada app (barra, terminal, `bat`, `yazi`, GTK, Qt, notificaciones, etc.) **no
está hardcodeado**: `matugen/config.toml` define, por cada app, un `input_path` (plantilla en
`matugen/templates/`) y un `output_path` (el archivo real que la app lee). Al cambiar de
wallpaper, matugen recompila todas las plantillas y cada app queda con la misma paleta
derivada de esa imagen.

Ese `output_path` (`~/.config/themes/matugen/...`) es contenido **generado**, así que no
viene incluido en este repo — se recrea corriendo matugen con esta config. Varias apps
(`waybar`, `ironbar`, `mako`, `bat`, `yazi`, `kitty`, `gtk`, `qt5ct`/`qt6ct`,
`swayosd`, `btop`) apuntan a ese archivo generado mediante un symlink en su propia carpeta de
config — symlink que tampoco viene en el repo por lo mismo (apunta a algo que todavía no
existe hasta que corras matugen la primera vez).

## Qué es específico de Arch/CachyOS

La mayor parte de este repo es config de proyectos upstream (niri, waybar/ironbar, walker,
mako, matugen, kitty, starship, bat, yazi, btop, MangoHud, GTK, Qt, swayosd, micro):
no le importa la distro, solo que el paquete esté instalado. Los puntos que sí asumen
Arch/CachyOS son estos cuatro:

| Dónde | Qué hace | Alcance |
|---|---|---|
| `fish/config.fish` | `source /usr/share/cachyos-fish-config/cachyos-config.fish` | Solo CachyOS — en otra distro esa ruta no existe |
| `fish/config.fish`, `zsh/.zshrc` | `alias update='paru -Syu'` | Familia Arch (necesita un AUR helper) |
| `elephant/menus/sys-system.toml` | Entrada "Paquetes de Arch", usa el provider `archlinuxpkgs` de walker | Solo Arch |
| `local/bin/desktop-orphans` | Resuelve qué paquete es dueño de un archivo con `pacman -Qo` | Familia Arch |

`zsh/.zshrc` deliberadamente **no** sourcea `cachyos-zsh-config` (a diferencia de la versión de
fish con la suya): ese paquete trae oh-my-zsh + Powerlevel10k como prompt fijo, que pelea con
starship. Cada uno de los puntos de la tabla tiene, al lado en el archivo, un comentario con el
equivalente manual para Debian/Fedora/openSUSE.

## Antes de usar esto

- **`weather-location.example`:** copiá a `~/.config/weather-location` con tus propias
  coordenadas (instrucciones adentro del archivo) — `install.sh` no lo pisa si ya existe.
- **Dependencias:** `niri`, `matugen`, `waybar`/`ironbar`, `walker` + `elephant`, `mako`,
  `hyprlock`, `hypridle`, `kitty`, `fish` y/o `zsh`, `starship`, `zoxide`, `atuin`, `eza`,
  `bat`, `fzf`, `yazi`, `chafa`, `wl-clipboard`, `jq`, `fastfetch`.

## Qué NO está acá (a propósito)

Se dejó afuera todo lo específico de mi red doméstica/homelab (alias SSH, IPs, MACs),
credenciales o URLs privadas (calendario, tokens), historial de shell, bookmarks de archivos
personales, y binarios de terceros que no son configuración.
