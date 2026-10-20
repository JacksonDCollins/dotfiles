require("vis")
local file_explorer = {
open = ' e'
}

local terminal = {
    open = ' t',
    normal = '<C-\\><C-n>',
    literal_prefix = '<C-\\><C-\\>',
}

vis:map(vis.modes.NORMAL, "<C-PageDown>", "<C-w>l", "Focus next window")
vis:map(vis.modes.NORMAL, "<C-PageUp>", "<C-w>h", "Focus previous window")
vis:map(vis.modes.NORMAL, "<Home>", "g<", "Go to previous jump list position")
vis:map(vis.modes.NORMAL, "<End>", "g>", "Go to next jump list position")

return {

file_explorer = file_explorer,
terminal = terminal

}

