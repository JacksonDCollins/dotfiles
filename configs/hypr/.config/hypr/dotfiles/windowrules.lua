-- ponytail: assumes one RuneLite main window per PID; use a native parent lookup if that changes.
hl.on("window.open", function(window)
	local class = "net-runelite-client-RuneLite"
	if not window.xwayland or not window.floating or window.initial_class ~= class
		or not window.initial_title:match("^win%d+$") or window.pid <= 0 then
		return
	end
	for _, parent in ipairs(hl.get_windows()) do
		if parent.mapped and parent.initial_class == class and parent.pid == window.pid
			and parent.initial_title:match("^RuneLite") and parent.pinned then
			assert(hl.dispatch(hl.dsp.window.pin({ window = window, action = "enable" })))
			return
		end
	end
end)

hl.window_rule({
	name = "floating-player",
	match = {
		initial_title = "^Picture-in-Picture$",
	},
	float = 1,
	pin = true,
	keep_aspect_ratio = true,
	-- 16:9, with height at 20% of the monitor's shorter dimension.
	size = {
		"min(monitor_w,monitor_h)*0.2*16/9",
		"min(monitor_w,monitor_h)*0.2",
	},
})
