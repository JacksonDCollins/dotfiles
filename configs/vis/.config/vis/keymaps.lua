require("vis")
local file_explorer = {
	open = " e",
}

local terminal = {
	open = " t",
	normal = "<C-\\><C-n>",
	literal_prefix = "<C-\\><C-\\>",
}

vis.events.subscribe(vis.events.WIN_OPEN, function()
	vis:map(vis.modes.NORMAL, "<C-PageDown>", "<C-w>l", "Focus next window")
	vis:map(vis.modes.NORMAL, "<C-PageUp>", "<C-w>h", "Focus previous window")
	vis:map(vis.modes.NORMAL, "<Home>", "j<", "Go to previous jump list position")
	vis:map(vis.modes.NORMAL, "<End>", "j>", "Go to next jump list position")
	vis:map(vis.modes.NORMAL, "<S-Home>", "jf<", "Go to previous jump list file")
	vis:map(vis.modes.NORMAL, "<S-End>", "jf>", "Go to next jump list file")

	-- Vis aliases recurse, so use native actions rather than mapping keys to themselves.
	for _, mode in ipairs({vis.modes.NORMAL, vis.modes.VISUAL}) do
		vis:map(mode, "y", '"+<vis-operator-yank>', "Yank to system clipboard")
		vis:map(mode, "p", '"+<vis-put-after>', "Paste from system clipboard")
		vis:map(mode, "P", '"+<vis-put-before>', "Paste before cursor from system clipboard")
		vis:map(mode, "d", '"_<vis-operator-delete>', "Delete without overwriting yanks")
	end
	vis:map(vis.modes.NORMAL, "x", '"+<vis-delete-char-next>', "Cut character to system clipboard")
	vis:map(vis.modes.NORMAL, "X", '"+<vis-operator-delete>h', "Cut previous character to system clipboard")
	vis:map(vis.modes.VISUAL, "x", '"+<vis-operator-delete>', "Cut selection to system clipboard")
end)

return {
	file_explorer = file_explorer,
	terminal = terminal,
}
