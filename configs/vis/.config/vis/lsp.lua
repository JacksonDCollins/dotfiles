-- Use vis-plug's module name so the client is not loaded twice.
local lsp = require('plugins/vis-lspc')
lsp.ls_map.c.formatting_options = {
	tabSize = 4,
	insertSpaces = true,
}
lsp.ls_map.lua = {
	name = 'lua-language-server',
	cmd = 'lua-language-server',
	settings = {
		Lua = {
			diagnostics = { globals = {'vis'} },
			telemetry = { enable = false }
		}
	},
	formatting_options = {
		tabSize = 4,
		insertSpaces = true,
	},
}


