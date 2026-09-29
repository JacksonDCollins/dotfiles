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
