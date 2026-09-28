-- Native Hyprland bindings: no Omarchy helpers or commands.
hl.bind("SUPER + Return", hl.dsp.exec_cmd("uwsm app -- foot"))
hl.bind("SUPER + space", hl.dsp.exec_cmd("uwsm app -- fuzzel"))
hl.bind("SUPER + B", hl.dsp.exec_cmd('quickshell --path "$HOME/.config/quickshell/shell.qml" ipc call bar toggleKeyboard'))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("uwsm stop"))
hl.bind("SUPER + L", hl.dsp.exec_cmd('"$HOME/.local/bin/dotfiles-session" lock'))
hl.bind("SUPER + ALT + L", hl.dsp.layout("togglesplit"))

-- Query the resulting state once; Quickshell only displays the supplied snapshot.
local function media_key(key, command, action, query)
  local state = query and ('"$(LC_ALL=C ' .. query .. ' 2>/dev/null)"') or '\"\"'
  hl.bind(key, hl.dsp.exec_cmd(command
    .. '; quickshell --path "$HOME/.config/quickshell/shell.qml" ipc call mediaOsd display '
    .. action .. ' ' .. state))
end
media_key("XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", "volume-up", "wpctl get-volume @DEFAULT_AUDIO_SINK@")
media_key("XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", "volume-down", "wpctl get-volume @DEFAULT_AUDIO_SINK@")
media_key("XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", "mute", "wpctl get-volume @DEFAULT_AUDIO_SINK@")
media_key("XF86AudioPlay", "playerctl play-pause", "play-pause", "playerctl status")
media_key("XF86AudioNext", "playerctl next", "next")
media_key("XF86AudioPrev", "playerctl previous", "previous")

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
