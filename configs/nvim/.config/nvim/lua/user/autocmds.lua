vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

local netrw_augroup = vim.api.nvim_create_augroup('netrw-custom', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  group = netrw_augroup,
  pattern = 'netrw',
  callback = function(event)
    vim.bo[event.buf].bufhidden = 'wipe' -- Wipe buffer when abandoned
    vim.opt_local.signcolumn = 'yes'
    require('netrw.ui').embelish(event.buf)
    require('netrw.actions').bind(event.buf)
  end,
})
vim.api.nvim_create_autocmd('ColorScheme', {
  group = netrw_augroup,
  callback = function()
    vim.api.nvim_set_hl(0, 'netrwMarkFile', { link = 'PmenuSel' })
  end,
})
