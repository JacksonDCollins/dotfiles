-- load standard vis module, providing parts of the Lua API
require('vis')

require('plugin-manager')

require('lsp')

vis.events.subscribe(vis.events.INIT, function()
	-- Your global configuration options
end)

vis.events.subscribe(vis.events.WIN_OPEN, function()
	-- Your per window configuration options e.g.
	-- vis:command('set number')
end)
