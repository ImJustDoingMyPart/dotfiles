-- Monitores: DP-3 (principal 180Hz con VRR on-demand), HDMI-A-1 (TV, apagada por defecto)

hl.monitor({
    output   = "DP-3",
    mode     = "1920x1080@179.96",
    position = "0x0",
    scale    = 1,
    vrr      = 2, -- on-demand (pantalla completa)
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
