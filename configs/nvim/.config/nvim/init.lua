-- Resolve mise-managed runtimes and editor tools in GUI/non-interactive launches too.
local mise_data = vim.env.MISE_DATA_DIR or ((vim.env.XDG_DATA_HOME or (vim.env.HOME .. '/.local/share')) .. '/mise')
vim.env.PATH = mise_data .. '/shims:' .. (vim.env.PATH or '')

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require 'user.opts'
require 'user.plugins'
require 'user.keymaps'
require 'user.statusline'
require 'user.autocmds'
require 'user.theme'
