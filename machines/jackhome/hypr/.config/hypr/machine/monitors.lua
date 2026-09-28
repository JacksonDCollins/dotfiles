local scale = 1
hl.env("GDK_SCALE", tostring(scale))
hl.monitor({ output = "", mode = "5120x1440@240", position = "auto", scale = scale })
