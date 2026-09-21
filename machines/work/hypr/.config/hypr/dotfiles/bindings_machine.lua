hl.unbind("SUPER + ALT + B")
hl.bind("SUPER + ALT + B", hl.dsp.exec_cmd("uwsm app -- firefox"))

hl.unbind("SUPER + SHIFT + E")
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("uwsm app -- betterbird"))

-- Match monitors.lua: each monitor owns workspaces index and index + 4.
local monitors = require("monitors")
--unbund all monitor focus bindings first to avoid duplicates
for code = 10, 19 do
	hl.unbind("SUPER + code:" .. code)
end
for index, output in ipairs(monitors) do
	local key = "SUPER + " .. output[2]
	hl.unbind(key)
	hl.bind(key, function()
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
