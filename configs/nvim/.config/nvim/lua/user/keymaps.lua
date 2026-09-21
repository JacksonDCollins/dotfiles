vim.keymap.set('n', '<leader>R', '<cmd>restart<CR>', { desc = 'Restart nvim' })
vim.keymap.set('n', '<leader>ps', '<cmd>lua vim.pack.update()<CR>', { desc = 'Update vim.pack plugins' })
vim.keymap.set('n', '<leader>e', function()
  if vim.bo.filetype == 'netrw' then
    vim.cmd.Rexplore()
    return
  end

  local path = vim.api.nvim_buf_get_name(0)
  local directory = path ~= '' and vim.fs.dirname(path) or vim.fn.getcwd()
  local filename = path ~= '' and vim.fs.basename(path) or nil
  vim.cmd('Explore ' .. vim.fn.fnameescape(directory))

  local netrw_buf = vim.api.nvim_get_current_buf()
  vim.schedule(function()
    if not filename or vim.api.nvim_get_current_buf() ~= netrw_buf or vim.bo.filetype ~= 'netrw' then
      return
    end

    for line_number, line in ipairs(vim.api.nvim_buf_get_lines(netrw_buf, 0, -1, false)) do
      local ok, node = pcall(require('netrw.parse').get_node, line)
      if ok and node and node.node == filename then
        vim.api.nvim_win_set_cursor(0, { line_number, node.col or 0 })
        vim.cmd 'normal! zz'
        return
      end
    end
  end)
end, { desc = 'Toggle netrw for current file' })

vim.keymap.set('v', '<S-Up>', ":m '<-2<CR>gv=gv", { desc = 'Move highlighted rows up' })
vim.keymap.set('v', '<S-Down>', ":m '>+1<CR>gv=gv", { desc = 'Move highlighted rows down' })
vim.keymap.set('v', '<S-Left>', '"sdh"sP`[v`]', { desc = 'Move current selection left' })
vim.keymap.set('v', '<S-Right>', '"sdl"sP`[v`]', { desc = 'Move current selection right' })

vim.keymap.set('n', '>', '>>', { desc = 'Indent line' })
vim.keymap.set('n', '<', '<<', { desc = 'Unindent line' })
vim.keymap.set('v', '>', '>gv', { desc = 'Indent highlighted lines without exiting visual mode' })
vim.keymap.set('v', '<', '<gv', { desc = 'unindent highlighted lines without exiting visual mode' })

vim.keymap.set('n', 'J', 'mzJ`z', { desc = 'Join lines without moving cursor to the end of the line' })
vim.keymap.set({ 'n', 'v' }, '<PageDown>', '<C-d>zz', { desc = 'Scroll down half a page and center' })
vim.keymap.set({ 'n', 'v' }, '<PageUp>', '<C-u>zz', { desc = 'Scroll up half a page and center' })

vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Search next and center' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Search previous and center' })

local file_history = {}
local file_history_index = 0
local navigating_file_history = false

local function is_file_buffer(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr)
    and vim.bo[bufnr].buflisted
    and vim.bo[bufnr].buftype == ''
    and vim.api.nvim_buf_get_name(bufnr) ~= ''
end

local function record_file(bufnr)
  if navigating_file_history or not is_file_buffer(bufnr) or file_history[file_history_index] == bufnr then
    return
  end

  -- Preserve newer entries like the default jumplist, while making this branch the most recent history.
  if file_history_index > 0 and file_history_index < #file_history then
    local current = table.remove(file_history, file_history_index)
    file_history[#file_history + 1] = current
    file_history_index = #file_history
  end
  for i = #file_history, 1, -1 do
    if file_history[i] == bufnr then
      table.remove(file_history, i)
      if i <= file_history_index then
        file_history_index = file_history_index - 1
      end
    end
  end
  file_history[#file_history + 1] = bufnr
  file_history_index = #file_history
end

local function navigate_file_history(direction)
  for i = #file_history, 1, -1 do
    if not is_file_buffer(file_history[i]) then
      table.remove(file_history, i)
      if i <= file_history_index then
        file_history_index = file_history_index - 1
      end
    end
  end

  local moved = false
  for _ = 1, vim.v.count1 do
    local current_is_tracked = file_history[file_history_index] == vim.api.nvim_get_current_buf()
    local target_index = file_history_index + (current_is_tracked and direction or math.max(direction, 0))
    local target = file_history[target_index]
    if not target then
      break
    end

    navigating_file_history = true
    local ok, err = pcall(vim.api.nvim_set_current_buf, target)
    navigating_file_history = false
    if not ok then
      vim.notify(err, vim.log.levels.WARN)
      break
    end
    file_history_index = target_index
    moved = true
  end

  if moved then
    vim.cmd 'normal! zz'
  end
end

vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('file-history', { clear = true }),
  callback = function(event)
    record_file(event.buf)
  end,
})
record_file(vim.api.nvim_get_current_buf())

vim.keymap.set('n', '<Home>', function()
  navigate_file_history(-1)
end, { desc = 'Go to previous file in history' })
vim.keymap.set('n', '<End>', function()
  navigate_file_history(1)
end, { desc = 'Go to next file in history' })

vim.keymap.set('c', '<CR>', function()
  return (vim.fn.getcmdtype() == '/' or vim.fn.getcmdtype() == '?') and '<CR>zzzv' or '<CR>'
end, { expr = true, desc = 'Search and center' })

vim.keymap.set('v', 'p', [["_dP]], { desc = 'Paste without overwriting the default yank register' })
vim.keymap.set({ 'n', 'v' }, 'd', [["_d]], { desc = 'Delete without overwriting the default yank register' })
vim.keymap.set(
  { 'n', 'v' },
  'D',
  [["_D]],
  { desc = 'Delete to end of line without overwriting the default yank register' }
)
vim.keymap.set({ 'n', 'v' }, 'c', [["_c]], { desc = 'Change without overwriting the default yank register' })
vim.keymap.set(
  { 'n', 'v' },
  'C',
  [["_C]],
  { desc = 'Change to end of line without overwriting the default yank register' }
)

vim.keymap.set('i', '<C-c>', '<Esc>', { desc = 'Exit insert mode' })

vim.keymap.set('n', '<leader>n', '<cmd>lnext<CR>zz', { desc = 'Go to next item in [L]ocation [N]ext' })
vim.keymap.set('n', '<leader>p', '<cmd>lprev<CR>zz', { desc = 'Go to previous item in [L]ocation [P]revious' })

vim.keymap.set(
  'n',
  '<leader>r',
  [[:%s/\(\<<C-r><C-w>\>\)//gI<Left><Left><Left>]],
  { desc = '[R]eplace word under cursor in entire file' }
)

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set('n', '<leader>q', function()
  if vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 then
    vim.cmd.lclose()
  else
    vim.diagnostic.setloclist()
  end
end, { desc = 'Toggle diagnostic location list' })

local config_picker_opts = {
  grep_string = {
    additional_args = { '--hidden' },
  },
  find_files = {
    hidden = true,
  },
  live_grep = {
    additional_args = { '--hidden' },
  },
}
require('telescope').setup {
  pickers = vim.tbl_deep_extend(
    'force',
    {},
    vim.fs.basename(vim.fn.getcwd()) == 'dotfiles' and config_picker_opts or {}
  ),
}
local builtin = require 'telescope.builtin'
vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sp', builtin.git_files, { desc = '[S]earch Git [P]roject Files' })
vim.keymap.set('n', '<leader>sn', require('telescope').extensions.fidget.fidget, { desc = '[S]earch [N]otifications' })
vim.keymap.set('n', '<leader>st', builtin.builtin, { desc = '[S]earch [T]elescope Builtins' })
vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
  builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 9,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })
vim.keymap.set('n', '<leader>s/', function()
  builtin.live_grep {
    grep_open_files = true,
    prompt_title = 'Live Grep in Open Files',
  }
end, { desc = '[S]earch [/] in Open Files' })
vim.keymap.set('n', '<leader>sc', function()
  builtin.find_files { cwd = vim.fn.stdpath 'config' }
end, { desc = '[S]earch Neovim [C]onfig Files' })

vim.keymap.set('n', '<leader>gf', vim.cmd.Git, { desc = 'Open Git [F]ugitive' })

local harpoon = require 'harpoon'
vim.keymap.set('n', '<leader>ma', function()
  harpoon:list():add()
end)
vim.keymap.set('n', '<leader>mf', function()
  harpoon.ui:toggle_quick_menu(harpoon:list())
end)
for i = 1, 9 do
  vim.keymap.set('n', '<M-' .. i .. '>', function()
    harpoon:list():select(i)
  end)
end

vim.keymap.set('n', '<leader>f', function()
  require('conform').format { async = true, lsp_format = 'fallback' }
end, {
  desc = '[F]ormat buffer',
})

vim.keymap.set({ 'v', 'i', 'n', 't' }, '<C-Left>', '<cmd>TmuxNavigateLeft<CR>', { desc = 'Move to left tmux pane' })
vim.keymap.set({ 'v', 'i', 'n', 't' }, '<C-Down>', '<cmd>TmuxNavigateDown<CR>', { desc = 'Move to down tmux pane' })
vim.keymap.set({ 'v', 'i', 'n', 't' }, '<C-Up>', '<cmd>TmuxNavigateUp<CR>', { desc = 'Move to up tmux pane' })
vim.keymap.set({ 'v', 'i', 'n', 't' }, '<C-Right>', '<cmd>TmuxNavigateRight<CR>', { desc = 'Move to right tmux pane' })
vim.keymap.set(
  { 'v', 'i', 'n', 't' },
  '<C-\\>',
  '<cmd>TmuxNavigatePrevious<CR>',
  { desc = 'Move to previous tmux pane' }
)
