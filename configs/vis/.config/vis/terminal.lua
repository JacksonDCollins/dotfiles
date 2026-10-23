require('vis')
local keys = require('keymaps')

if not vis.modes.TERMINAL then return end

vis.events.subscribe(vis.events.WIN_OPEN, function()
	vis:unmap(vis.modes.TERMINAL, keys.terminal.normal)
	vis:map(vis.modes.TERMINAL, keys.terminal.normal, function()
	    vis.mode = vis.modes.NORMAL
	end, 'Leave terminal input without stopping the process')
	vis:map(vis.modes.TERMINAL, keys.terminal.literal_prefix, function()
	    vis:terminal_send('<C-\\>')
	end, 'Send a literal Ctrl-backslash')
	vis:map(vis.modes.NORMAL, keys.terminal.open, function()
	    local ok, err = pcall(vis.terminal, vis, 'exec "${SHELL:-/bin/sh}" -i')
	    if not ok then vis:info(tostring(err)) end
	end, 'Open a terminal buffer')
end)
