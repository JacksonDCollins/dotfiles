-- load standard vis module, providing parts of the Lua API
require("vis")

require("plugin-manager")

require("lsp")

require("file-explorer")

vis.events.subscribe(vis.events.WIN_OPEN, function()
	-- Your per window configuration options e.g.
	-- vis:command('set number')
end)
