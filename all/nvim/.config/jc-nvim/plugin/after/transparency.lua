-- Make highlight groups transparent while preserving their other attributes
local function make_transparent(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if ok then
    hl.bg = nil
    vim.api.nvim_set_hl(0, name, hl)
  end
end

local groups = {
  -- transparent background
  'Normal',
  'NormalFloat',
  'FloatBorder',
  'Pmenu',
  'Terminal',
  'EndOfBuffer',
  'FoldColumn',
  'Folded',
  'SignColumn',
  'LineNr',
  'CursorLineNr',
  'NormalNC',
  'TelescopeBorder',
  'TelescopeNormal',
  'TelescopePromptBorder',
  'TelescopePromptTitle',
}

local function apply_transparency()
  for _, name in ipairs(groups) do
    make_transparent(name)
  end
end

apply_transparency()

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('Transparency', { clear = true }),
  desc = 'Reapply transparent highlights',
  callback = apply_transparency,
})
