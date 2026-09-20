hl.unbind("SUPER + L")
o.bind("SUPER + ALT + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

o.bind("SUPER + H", "Previous workspace on monitor", hl.dsp.focus({ workspace = "m-1" }))
o.bind("SUPER + Comma", "Next workspace on monitor", hl.dsp.focus({ workspace = "m+1" }))
o.bind("SUPER + SHIFT + H", "Move window to previous workspace on monitor", hl.dsp.window.move({ workspace = "m-1" }))
o.bind("SUPER + SHIFT + Comma", "Move window to next workspace on monitor", hl.dsp.window.move({ workspace = "m+1" }))

o.bind("SUPER + Page_Down", "Previous workspace on monitor", hl.dsp.focus({ workspace = "m-1" }))
o.bind("SUPER + Page_Up", "Next workspace on monitor", hl.dsp.focus({ workspace = "m+1" }))
o.bind(
	"SUPER + SHIFT + Page_Down",
	"Move window to previous workspace on monitor",
	hl.dsp.window.move({ workspace = "m-1" })
)
o.bind("SUPER + SHIFT + Page_Up", "Move window to next workspace on monitor", hl.dsp.window.move({ workspace = "m+1" }))
