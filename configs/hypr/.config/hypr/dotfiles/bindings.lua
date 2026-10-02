-- Descriptions are also displayed by Quickshell's live keybinding reference.
local function bind(keys, description, dispatcher, options)
	options = options or {}
	options.description = description
	hl.bind(keys, dispatcher, options)
end

bind("SUPER + Return", "Open Foot terminal", hl.dsp.exec_cmd("uwsm app -- foot"))
bind("SUPER + space", "Open application launcher", hl.dsp.exec_cmd("uwsm app -- fuzzel"))
bind(
	"SUPER + B",
	"Toggle bar keyboard controls",
	hl.dsp.exec_cmd('quickshell --path "$HOME/.config/quickshell/shell.qml" ipc call bar toggleKeyboard')
)
bind(
	"SUPER + slash",
	"Show Hyprland keybindings",
	hl.dsp.exec_cmd('quickshell --path "$HOME/.config/quickshell/shell.qml" ipc call keybindings toggle')
)
bind("SUPER + Q", "Close window", hl.dsp.window.close())

bind(
	"SUPER + SHIFT + V",
	"Show clipboard history",
	hl.dsp.exec_cmd('quickshell --path "$HOME/.config/quickshell/shell.qml" ipc call -- clipboard show')
)

hl.window_rule({
	match = {
		class = "(Alacritty|kitty|com.mitchellh.ghostty|foot|org\\.codeberg\\.dnkl\\.foot|wezterm|org\\.omarchy\\..*|TUI\\..*)",
	},
	tag = "+terminal",
})
local function send_shortcut_once(mods, key)
	return function()
		hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

		hl.timer(function()
			hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
		end, { timeout = 50, type = "oneshot" })
	end
end
local function active_window_is_terminal()
	local window = hl.get_active_window()
	if not window then
		return false
	end

	for _, tag in ipairs(window.tags or {}) do
		if tag:gsub("%*$", "") == "terminal" then
			return true
		end
	end

	return false
end
local function universal_clipboard_shortcut(default_mods, default_key, terminal_mods, terminal_key)
	return function()
		if active_window_is_terminal() then
			send_shortcut_once(terminal_mods, terminal_key)()
		else
			send_shortcut_once(default_mods, default_key)()
		end
	end
end
bind("SUPER + A", "Select all", send_shortcut_once("CTRL", "A"))
bind("SUPER + C", "Universal copy", universal_clipboard_shortcut("CTRL", "C", "CTRL SHIFT", "C"))
bind("SUPER + V", "Universal paste", universal_clipboard_shortcut("CTRL", "V", "CTRL SHIFT", "V"))
bind("SUPER + X", "Universal cut", send_shortcut_once("CTRL", "X"))

bind("SUPER + T", "Toggle floating / tiled", hl.dsp.window.float({ action = "toggle" }))
bind("SUPER + P", "Toggle floating + pinned / tiled + unpinned", function()
	local window = hl.get_active_window()
	if not window then
		return
	end
	if window.pinned then
		hl.dispatch(hl.dsp.window.pin({ window = window, action = "unset" }))
		hl.dispatch(hl.dsp.window.float({ window = window, action = "unset" }))
	else
		hl.dispatch(hl.dsp.window.float({ window = window, action = "set" }))
		hl.dispatch(hl.dsp.window.pin({ window = window, action = "set" }))
	end
end)
bind("SUPER + F", "Toggle fullscreen", hl.dsp.window.fullscreen())
bind("SUPER + Tab", "Focus next window (tiled or floating)", hl.dsp.window.cycle_next())
bind("SUPER + SHIFT + Tab", "Focus previous window (tiled or floating)", hl.dsp.window.cycle_next({ next = false }))
bind("SUPER + SHIFT + M", "Log out of desktop session", hl.dsp.exec_cmd("uwsm stop"))
bind("SUPER + L", "Lock screen", hl.dsp.exec_cmd('"$HOME/.local/bin/dotfiles-session" lock'))
bind("SUPER + ALT + L", "Toggle horizontal / vertical split", hl.dsp.layout("togglesplit"))

-- Query the resulting state once; Quickshell only displays the supplied snapshot.
local function media_key(key, description, command, action, query)
	local state = query and ('"$(LC_ALL=C ' .. query .. ' 2>/dev/null)"') or '""'
	bind(
		key,
		description,
		hl.dsp.exec_cmd(
			command
				.. '; quickshell --path "$HOME/.config/quickshell/shell.qml" ipc call mediaOsd display '
				.. action
				.. " "
				.. state
		)
	)
end
media_key(
	"XF86AudioRaiseVolume",
	"Raise volume 5% (maximum 100%)",
	"wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+",
	"volume-up",
	"wpctl get-volume @DEFAULT_AUDIO_SINK@"
)
media_key(
	"XF86AudioLowerVolume",
	"Lower volume 5%",
	"wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
	"volume-down",
	"wpctl get-volume @DEFAULT_AUDIO_SINK@"
)
media_key(
	"XF86AudioMute",
	"Toggle mute",
	"wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
	"mute",
	"wpctl get-volume @DEFAULT_AUDIO_SINK@"
)
media_key("XF86AudioPlay", "Play / pause media", "playerctl play-pause", "play-pause", "playerctl status")
media_key("XF86AudioNext", "Next track", "playerctl next", "next")
media_key("XF86AudioPrev", "Previous track", "playerctl previous", "previous")

bind("SUPER + H", "Previous workspace on this monitor", hl.dsp.focus({ workspace = "m-1" }))
bind("SUPER + Comma", "Next workspace on this monitor", hl.dsp.focus({ workspace = "m+1" }))
bind("SUPER + SHIFT + H", "Move window to previous workspace", hl.dsp.window.move({ workspace = "m-1" }))
bind("SUPER + SHIFT + Comma", "Move window to next workspace", hl.dsp.window.move({ workspace = "m+1" }))
bind("SUPER + Page_Down", "Previous workspace on this monitor", hl.dsp.focus({ workspace = "m-1" }))
bind("SUPER + Page_Up", "Next workspace on this monitor", hl.dsp.focus({ workspace = "m+1" }))
bind("SUPER + SHIFT + Page_Down", "Move window to previous workspace", hl.dsp.window.move({ workspace = "m-1" }))
bind("SUPER + SHIFT + Page_Up", "Move window to next workspace", hl.dsp.window.move({ workspace = "m+1" }))
for _, direction in ipairs({ "left", "right", "up", "down" }) do
	bind("SUPER + " .. direction, "Focus window " .. direction, hl.dsp.focus({ direction = direction }))
	bind("SUPER + SHIFT + " .. direction, "Move window " .. direction, hl.dsp.window.move({ direction = direction }))
end
for i = 1, 10 do
	local key = tostring(i % 10)
	bind("SUPER + " .. key, "Switch to workspace " .. i, hl.dsp.focus({ workspace = tostring(i) }))
	bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end
bind("SUPER + mouse:272", "Drag window", hl.dsp.window.drag())
bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize())

-- Machine profiles: local bind = require("dotfiles.bindings")
return bind
