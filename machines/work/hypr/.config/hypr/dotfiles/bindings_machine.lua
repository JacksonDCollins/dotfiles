hl.unbind("SUPER + ALT + B")
o.bind("SUPER + ALT + B", "Browser (Alternative)", { launch = "firefox" })

hl.unbind("SUPER + SHIFT + E")
o.bind("SUPER + SHIFT + E", "Email", { launch = "betterbird" })

-- Match monitors.lua: each monitor owns workspaces index and index + 4.
local monitors = require("hypr.monitors")
--unbund all monitor focus bindings first to avoid duplicates
for code = 10, 19 do
	hl.unbind("SUPER + code:" .. code)
end
for index, output in ipairs(monitors) do
	local key = "SUPER + " .. output[2]
	hl.unbind(key)
	o.bind(key, "Focus monitor " .. index .. " or toggle its workspace", function()
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
