-- Monitores: DP-3 (principal KTC 27" 1440p 300Hz con VRR on-demand), HDMI-A-1 (TV, apagada por defecto)

hl.monitor({
    output   = "DP-3",
    mode     = "2560x1440@300",
    position = "0x0",
    scale    = 1,
    vrr      = 2, -- on-demand (pantalla completa)
    -- Sin bitdepth = 10 a propósito: con la salida en XR30, cada entrada y salida del direct
    -- scanout (buffer del juego en XR24) cambia el formato y dispara un modeset de ~60 ms.
    -- Jugando CS2 eso era stuttering.
})

hl.monitor({
    output   = "HDMI-A-1",
    disabled = true,
    mode     = "1920x1080@60",
    position = "0x-1080",
    scale    = 1,
})

-- Fallback para cualquier otra salida (ej. ventana anidada WL-1 en pruebas)
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})
