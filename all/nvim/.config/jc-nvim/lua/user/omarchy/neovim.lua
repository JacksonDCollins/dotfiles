local theme_path = vim.fn.expand '~/.local/state/omarchy/current/theme/neovim.lua'

if vim.uv.fs_stat(theme_path) then
  local ok, theme = pcall(dofile, theme_path)
  if ok and type(theme) == 'table' then
    return theme
  end
end

return {}
