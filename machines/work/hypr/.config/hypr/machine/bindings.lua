local bind = require("dotfiles.bindings")

hl.unbind("SUPER + ALT + B")
bind("SUPER + ALT + B", "Open Firefox", hl.dsp.exec_cmd("uwsm app -- firefox"))

hl.unbind("SUPER + SHIFT + E")
bind("SUPER + SHIFT + E", "Open Betterbird email", hl.dsp.exec_cmd("uwsm app -- betterbird"))

-- Match monitors.lua: each monitor owns workspaces index and index + 4.
local monitors = require("machine.monitors")
-- Replace the default number-row workspace bindings.
for i = 1, 10 do
	hl.unbind("SUPER + " .. (i % 10))
end
for index, output in ipairs(monitors) do
	local key = "SUPER + " .. output[2]
	hl.unbind(key)
	bind(key, "Focus monitor " .. output[1] .. " / toggle workspaces " .. index .. " and " .. (index + 4), function()
		local monitor = hl.get_monitor(output[1])
		if not monitor then
			return
		end

		if not monitor.focused then
			hl.dispatch(hl.dsp.focus({ monitor = output[1] }))
		else
			local workspace = monitor.active_workspace
			local target = workspace and workspace.id == index and index + 4 or index
			hl.dispatch(hl.dsp.focus({ workspace = tostring(target) }))
		end
	end)
end
