-- load standard vis module, providing parts of the Lua API
require("vis")

require("plugin-manager")

require("lsp")

require("terminal")

require("file-explorer")

require("keymaps")

require("modal")

require("autoclose")

vis.events.subscribe(vis.events.WIN_OPEN, function()
	-- Your per window configuration options e.g.
	-- vis:command('set number')
	vis:command("set tabwidth 4")
	vis:command("set numbers true")
	vis:command("set autoindent true")
	vis:command("set relativenumbers true")
	vis:command("set numberwidth 4")
end)

vis.events.subscribe(vis.events.INIT, function()
	vis:command("set theme hyprcachy")
end)
