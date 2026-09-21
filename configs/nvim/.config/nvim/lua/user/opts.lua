vim.o.autoread = true --auto reload files edited outside of nvim
vim.g.have_nerd_font = true --nerd font installed
vim.g.editorconfig = true --use editorconfig files in project dirs

vim.g.tpipeline_autoembed = 0 --disable tpipeline auto embed (we use manual commands)

vim.g.tmux_navigator_no_mappings = 1 --disable tmux navigator default mappings (we use our own)

-- Netrw configuration
vim.g.netrw_localcopydircmd = 'cp -r' --change netrw copy command to recursive copy
vim.g.netrw_liststyle = 1 --open netrw in long list mode
vim.g.netrw_banner = 0 --hide netrw banner (press I to toggle if needed)
vim.g.netrw_mousemaps = 0 --disable mouse mappings
vim.g.netrw_keepj = 'keepj' --preserve jump list while browsing
vim.api.nvim_set_hl(0, 'netrwMarkFile', { link = 'PmenuSel' })

vim.o.number = true --show line numbers
vim.o.relativenumber = true --relative line numbers
vim.o.mouse = 'a' --enable mouse for resizing panes etc
vim.o.showmode = true --show mode in status bar
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus' --sync with system clipboard
end)

vim.o.breakindent = true --enable break indent

vim.o.shiftwidth = 4 --tabs are 4 spaces
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.expandtab = true --as above

vim.o.wrap = true --wrap lines

vim.o.undofile = true --track undofile for files
vim.o.undodir = (os.getenv 'HOME' or os.getenv 'USERPROFILE') .. '/.vim/undodir' --undofile location

vim.o.swapfile = false --disable swapfile

vim.o.ignorecase = true --ignore case in search patterns unless specified
vim.o.smartcase = true --override ignore case if capitals used

vim.o.signcolumn = 'yes' --show sign column

vim.o.updatetime = 250 -- Balanced update time for LSP/diagnostics (was 50ms)

vim.o.timeoutlen = 300 -- Decrease mapped sequence wait time

vim.o.splitright = true -- Configure how new splits should be opened
vim.o.splitbelow = true -- Configure how new splits should be opened

vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' } -- Sets how neovim will display certain whitespace characters in the editor.
vim.o.list = true --enable showing list chars

vim.o.inccommand = 'split' -- Preview substitutions live, as you type!
vim.o.hlsearch = false --stop highlighting after search is stopped
vim.o.incsearch = true --highlight as you type chars

vim.opt.termguicolors = true --better colours

vim.o.cursorline = true --highlight current line

vim.o.scrolloff = 10 --ensure 10 lines at bottom of view

vim.o.confirm = true --ask for confirmation if file would fail instead

vim.o.smoothscroll = true --scroll works with screen lines
