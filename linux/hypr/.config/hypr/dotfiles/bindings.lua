-- Native Hyprland bindings: no Omarchy helpers or commands.
hl.bind("SUPER + Return", hl.dsp.exec_cmd("foot"))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + SHIFT + M", hl.dsp.exit())
hl.bind("SUPER + ALT + L", hl.dsp.layout("togglesplit"))

hl.bind("SUPER + H", hl.dsp.focus({ workspace = "m-1" }))
hl.bind("SUPER + Comma", hl.dsp.focus({ workspace = "m+1" }))
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ workspace = "m-1" }))
hl.bind("SUPER + SHIFT + Comma", hl.dsp.window.move({ workspace = "m+1" }))
hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "m-1" }))
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "m+1" }))
hl.bind("SUPER + SHIFT + Page_Down", hl.dsp.window.move({ workspace = "m-1" }))
hl.bind("SUPER + SHIFT + Page_Up", hl.dsp.window.move({ workspace = "m+1" }))

for _, direction in ipairs({ "left", "right", "up", "down" }) do
  hl.bind("SUPER + " .. direction, hl.dsp.focus({ direction = direction }))
end
for i = 1, 10 do
  local key = "code:" .. (i + 9)
  hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = tostring(i) }))
  hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
