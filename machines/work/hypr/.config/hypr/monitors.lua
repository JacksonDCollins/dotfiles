local m1 = "HDMI-A-2"
local m2 = "DP-2"
local m3 = "DVI-D-1"
local m4 = "HDMI-A-1"

hl.env("GDK_SCALE", "1")
hl.monitor({ output = m1, mode = "1920x1080@60", position = "0x0", scale = 1 })
hl.monitor({ output = m4, mode = "1920x1080@60", position = "1920x0", scale = 1 })
hl.monitor({ output = m3, mode = "1920x1080@60", position = "0x-1080", scale = 1 })
hl.monitor({ output = m2, mode = "1920x1080@60", position = "-1080x-352", scale = 1, transform = 1 })

hl.workspace_rule({ workspace = "1", monitor = m1, persistent = true, default = true })
hl.workspace_rule({ workspace = "5", monitor = m1, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = m2, persistent = true, default = true })
hl.workspace_rule({ workspace = "6", monitor = m2, persistent = true })
hl.workspace_rule({ workspace = "3", monitor = m3, persistent = true, default = true })
hl.workspace_rule({ workspace = "7", monitor = m3, persistent = true })
hl.workspace_rule({ workspace = "4", monitor = m4, persistent = true, default = true })
hl.workspace_rule({ workspace = "8", monitor = m4, persistent = true })

return { { m1, "5" }, { m2, "4" }, { m3, "8" }, { m4, "6" } }
