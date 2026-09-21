vim.pack.add { { src = 'https://github.com/catppuccin/nvim', name = 'catppuccin' } }
require('catppuccin').setup {
  flavour = 'mocha',
  transparent_background = false,
  auto_integrations = true,
}
vim.cmd.colorscheme 'catppuccin-mocha'
