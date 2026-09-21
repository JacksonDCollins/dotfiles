-- Standalone configuration for Hyprland's native Lua API (tested with 0.56.2).
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
hl.config({
	general = { gaps_in = 5, gaps_out = 10, border_size = 2, layout = "dwindle" },
	decoration = { rounding = 8 },
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
require("dotfiles")
optional_module("machine", "machine.lua")
