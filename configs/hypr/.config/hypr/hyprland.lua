-- Standalone configuration for Hyprland's native Lua API (tested with 0.56.2).
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 2 })
-- hyprctl eval 'hl.monitor({ output = "Virtual-1", mode =
-- "1920x1080@60", position = "auto", scale = 1 })'
hl.config({
	general = { gaps_in = 5, gaps_out = 10, border_size = 2, layout = "dwindle" },
	decoration = { rounding = 8 },
	dwindle = { preserve_split = true },
})

-- UWSM manages the graphical session and systemd user services.
-- Hyprcachy enables hyprpolkitagent; no service autostart is needed here.

-- A profile may provide monitors.lua and extra bindings; default needs neither.
local config = (os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/hypr/"
-- Hyprland resolves the Stow symlink; search HOME so profile modules are visible.
package.path = config .. "?.lua;" .. config .. "?/init.lua;" .. package.path
local function optional_module(name, path)
	local file = io.open(config .. path, "r")
	if file then
		file:close()
		require(name)
	end
end
dofile("/usr/share/hyprcachy/window-session/init.lua")({
	enabled = true,

	-- Seconds; these are the defaults.
	launch_delay = 20, -- Wait before launching missing apps/fallback matching.
	restore_timeout = 80, -- Stop waiting for missing windows.
	stability_delay = 15, -- Wait for stable topology before saving.

	launch = {
		-- Explicit command and arguments:
		foot = { "foot", "tmux", "new-session", "-A", "-s", "main" },

		-- Desktop entry:
		-- firefox = "firefox.desktop",

		-- Restore placement, but let autostart launch it:
		vesktop = false,
	},

	-- Initial window classes to exclude:
	ignore = {}, -- Example: { "private-app" }
})

require("dotfiles")
optional_module("machine", "machine.lua")
