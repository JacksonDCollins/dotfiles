local lint = require 'lint'
lint.linters_by_ft = {
  markdown = { 'markdownlint' },
  python = { 'ruff' },
  sh = { 'shellcheck' },
  lua = { 'luacheck' },
  php = { 'phpcs' },
}

local luacheck = lint.linters.luacheck
lint.linters.luacheck = function()
  local config = vim.deepcopy(type(luacheck) == 'function' and luacheck() or luacheck)
  local current_dir = vim.fn.expand '%:p:h'
  local cwd_dir = vim.fs.dirname(vim.fn.getcwd())
  local luacheckrc = vim.fs.find('.luacheckrc', { path = current_dir, upward = true, stop = cwd_dir })[1]
  if luacheckrc then
    config.args = config.args or {}
    table.insert(config.args, #config.args, '--config=' .. luacheckrc)
  end
  return config
end

-- Create autocommand which carries out the actual linting
-- on the specified events.
local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
  group = lint_augroup,
  callback = function(args)
    -- Only run the linter in buffers that you can modify in order to
    -- avoid superfluous noise, notably within the handy LSP pop-ups that
    -- describe the hovered symbol using Markdown.
    local buffer = vim.bo[args.buf]
    if buffer.modifiable and (args.event ~= 'InsertLeave' or buffer.filetype ~= 'sh') then
      lint.try_lint()
    end
  end,
})
