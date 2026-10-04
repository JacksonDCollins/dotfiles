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

-- Keep return locations on windows: tags survive config reloads and session snapshots.
do
	local prefix, busy = "dotfiles-fullscreen-return:", {}
	-- Without an enabled session controller, baselines last only this config load.
	local fallback_layouts = {}
	local function layouts()
		local session = hyprcachy_window_session
		return session and session.fullscreen_layouts or fallback_layouts
	end
	local function current_tree(name)
		local workspace = hl.get_workspace(name)
		if not workspace or #hl.get_windows({ workspace = workspace, mapped = true, floating = false }) == 0 then
			return "" -- Distinguish an empty workspace from a failed native capture (nil).
		end
		return hl.plugin.window_session.capture(workspace.id)
	end
	local function layout_before(window, origin, entering)
		local native = hl.plugin and hl.plugin.window_session
		if not native or type(native.capture) ~= "function" or type(native.restore) ~= "function" then return end
		local id, layout = tostring(window.stable_id), layouts()[origin]
		if entering and window.floating then return end
		if not entering and (not layout or not layout.away[id]) then return end
		local tree = current_tree(origin)
		if layout then
			-- Never overwrite edits to the remaining tree, or a user's change to floating mode.
			if tree ~= layout.expected or window.floating then layout.tree = nil end
		elseif tree and tree ~= "" then
			layout = { tree = tree, expected = tree, away = {} }
			layouts()[origin] = layout
		end
		if layout and entering then layout.away[id] = true end
		return layout
	end
	local function layout_after(window, origin, entering, layout)
		if not layout then return end
		if not entering then
			if layout.tree then
				local bindings = {}
				for _, member in ipairs(hl.get_windows({ workspace = window.workspace, mapped = true, floating = false })) do
					local id = tostring(member.stable_id)
					bindings[id] = id
				end
				-- Native remapping collapses absent leaves; extra live leaves reject the restore.
				local ok, err = hl.plugin.window_session.restore(window.workspace.id, layout.tree, bindings)
				if not ok then
					layout.tree = nil
					print("Fullscreen layout: " .. tostring(err) .. "; keeping normal placement")
				end
			end
			layout.away[tostring(window.stable_id)] = nil
		end
		layout.expected = current_tree(origin)
		if not layout.expected then layout.tree = nil end
		if not next(layout.away) then layouts()[origin] = nil end
	end
	local function dispatch(action)
		local result = hl.dispatch(action)
		assert(result.ok, result.error or "Hyprland refused the workspace move")
	end
	local function hex(text)
		return (text:gsub(".", function(c) return string.format("%02x", c:byte()) end))
	end
	local function unhex(text)
		assert(#text % 2 == 0, "Invalid fullscreen return tag")
		local value = text:gsub("..", function(c) return string.char(tonumber(c, 16)) end)
		assert(not value:find("\0", 1, true), "Invalid fullscreen return tag")
		return value
	end
	local function suspended()
		local session = hyprcachy_window_session
		-- Require the controller's explicit idle signal; older controllers must be updated first.
		return session and session.status ~= "disabled (opt-in)" and session.restoring ~= false
	end
	local function relocate(window)
		if suspended() or not window.mapped or window.hidden or window.group or window.pinned
			or window.pin_fullscreened or not window.workspace or window.workspace.special or not window.monitor then
			return
		end
		local full = (window.fullscreen & 2) ~= 0 -- Maximized alone is not fullscreen.
		local saved, destination, monitor, origin
		for _, tag in ipairs(window.tags) do
			if tag:sub(1, #prefix) == prefix then
				assert(not saved and #tag <= 256, "Invalid/duplicate fullscreen return tag")
				local workspace_hex, monitor_hex = tag:sub(#prefix + 1):match("^([0-9a-f]+):([0-9a-f]+)$")
				assert(workspace_hex and monitor_hex, "Invalid fullscreen return tag")
				destination, monitor = unhex(workspace_hex), unhex(monitor_hex)
				assert((destination:match("^[1-9]%d*$") and tonumber(destination) < 4294967295)
					or destination:match("^name:.+"), "Invalid return workspace")
				saved = tag
			end
		end
		if full == (saved ~= nil) then
			return -- Already isolated, or an ordinary non-fullscreen window.
		end
		if full then
			if #hl.get_windows({ workspace = window.workspace, mapped = true }) <= 1 then return end
			local highest = 0
			for _, workspace in ipairs(hl.get_workspaces()) do
				if not workspace.special and not workspace.is_empty and workspace.id > highest then
					highest = workspace.id
				end
			end
			assert(highest < 4294967294, "No higher numbered workspace is available")
			destination, monitor, origin = tostring(highest + 1), window.monitor.name, window.workspace.config_name
			saved = prefix .. hex(origin) .. ":" .. hex(monitor)
			assert(#saved <= 256 and #window.tags < 128, "Fullscreen return tag exceeds snapshot limits")
			dispatch(hl.dsp.window.tag({ window = window, tag = "+" .. saved }))
		elseif hl.get_workspace(destination) then
			monitor = nil -- An existing home workspace may have been moved to another monitor.
		end
		origin = origin or destination
		local layout = layout_before(window, origin, full)
		local target_monitor = monitor and hl.get_monitor(monitor)
		dispatch(hl.dsp.window.move({ window = window, workspace = destination, follow = true }))
		if target_monitor and window.monitor.name ~= target_monitor.name then
			dispatch(hl.dsp.workspace.move({ workspace = window.workspace, monitor = target_monitor }))
			dispatch(hl.dsp.focus({ window = window }))
		end
		layout_after(window, origin, full, layout)
		if not full then
			dispatch(hl.dsp.window.tag({ window = window, tag = "-" .. saved }))
		end
	end
	local function queue(window)
		if suspended() then return end
		local id = window.stable_id
		if busy[id] then return end
		busy[id] = true
		-- Workspace moves emit fullscreen events themselves; wait for the outer change to finish.
		hl.timer(function()
			local ok, err = pcall(relocate, window)
			busy[id] = nil
			if not ok then print("Fullscreen workspace: " .. tostring(err)) end
		end, { timeout = 1, type = "oneshot" })
	end
	hl.on("window.close", function(window)
		for origin, layout in pairs(layouts()) do
			layout.away[tostring(window.stable_id)] = nil
			if not next(layout.away) then layouts()[origin] = nil end
		end
	end)
	hl.on("window.fullscreen", queue)
	hl.on("window.open", queue)
end

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
