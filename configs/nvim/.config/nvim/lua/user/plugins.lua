vim.pack.add {
  { src = 'https://github.com/lewis6991/gitsigns.nvim' },
  { src = 'https://github.com/j-hui/fidget.nvim' },
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/natecraddock/telescope-zf-native.nvim' },
  { src = 'https://github.com/nvim-telescope/telescope-ui-select.nvim' },
  { src = 'https://github.com/nvim-telescope/telescope.nvim' },
  { src = 'https://github.com/tpope/vim-fugitive' },
  { src = 'https://github.com/ThePrimeagen/harpoon', version = 'harpoon2' },
  { src = 'https://github.com/folke/lazydev.nvim' },
  { src = 'https://github.com/rafamadriz/friendly-snippets' },
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range '^1' },
  { src = 'https://github.com/zbirenbaum/copilot.lua' },
  { src = 'https://github.com/stevearc/conform.nvim' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects', version = 'main' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-context' },
  { src = 'https://github.com/mfussenegger/nvim-lint' },
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  { src = 'https://github.com/prichrd/netrw.nvim' },
  { src = 'https://github.com/kylechui/nvim-surround' },
  { src = 'https://github.com/windwp/nvim-autopairs.git' },
  { src = 'https://github.com/abecodes/tabout.nvim' },
  { src = 'https://github.com/vimpostor/vim-tpipeline' },
  { src = 'https://github.com/christoomey/vim-tmux-navigator' },
  { src = 'https://github.com/catgoose/nvim-colorizer.lua' },
  { src = 'https://github.com/folke/flash.nvim' },
  { src = 'https://github.com/folke/sidekick.nvim' },
}
vim.pack.add({
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
}, {
  load = vim.g.have_nerd_font,
})
require('gitsigns').setup {

  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
}

require('fidget').setup {
  notification = {
    override_vim_notify = true,
  },
}

require('telescope').setup {
  extensions = {
    ['ui-select'] = {
      require('telescope.themes').get_dropdown(),
    },
  },
}
local function load_telescope_extension(name)
  local ok = pcall(require('telescope').load_extension, name)
  if not ok then
    vim.notify(('Telescope extension %q is unavailable'):format(name), vim.log.levels.WARN)
  end
end

load_telescope_extension 'zf-native'
load_telescope_extension 'ui-select'
load_telescope_extension 'fidget'

local harpoon = require 'harpoon'
harpoon:setup { settings = { sync_on_ui_close = true, save_on_toggle = true } }
local harpoon_extensions = require 'harpoon.extensions'
harpoon:extend(harpoon_extensions.builtins.highlight_current_file())

require('lazydev').setup {
  library = {
    -- Load luvit types when the `vim.uv` word is found
    { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
  },
}

require('conform').setup {
  notify_on_error = true,
  format_on_save = function(bufnr)
    -- Disable "format_on_save lsp_fallback" for languages that don't
    -- have a well standardized coding style. You can add additional
    -- languages here or re-enable it for the disabled ones.
    local disable_filetypes = { c = true, cpp = true }
    if disable_filetypes[vim.bo[bufnr].filetype] then
      return nil
    else
      return {
        timeout_ms = 500,
        lsp_format = 'fallback',
      }
    end
  end,
  formatters_by_ft = {
    lua = { 'stylua' },
    php = { 'phpcbf' },
    go = { 'gofumpt', 'goimports' },
    rust = { 'rustfmt' },
    sh = { 'shfmt' },
    python = { 'black' },
    javascript = { 'prettierd' },
    typescriptreact = { 'prettierd' },
    typescript = { 'prettierd' },
    css = { 'prettierd' },
    html = { 'prettierd' },
    json = { 'prettierd' },
  },
}

require 'user.lsp'

require 'user.lints'

require('blink.cmp').setup {
  fuzzy = { implementation = 'prefer_rust_with_warning' },
  signature = { enabled = true },
  keymap = {
    preset = 'default',
    ['<C-f>'] = {
      function()
        local suggestion = require 'copilot.suggestion'
        if suggestion.is_visible() then
          suggestion.accept()
          return true
        end
      end,
      'scroll_documentation_down',
      'fallback',
    },
    ['<Tab>'] = {
      'snippet_forward',
      function()
        return require('sidekick').nes_jump_or_apply()
      end,
      'fallback',
    },
  },

  appearance = {
    use_nvim_cmp_as_default = true,
    nerd_font_variant = 'normal',
  },

  completion = {
    accept = { auto_brackets = { enabled = true } },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
    },
  },

  cmdline = {
    completion = { menu = { auto_show = true } },
  },

  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer', 'lazydev' },
    providers = {
      lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
    },
  },
}

local ensure_installed = {
  'bash',
  'diff',
  'html',
  'latex',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'vim',
  'vimdoc',
  'php',
  'python',
  'javascript',
  'typescript',
  'tsx',
  'css',
  'json',
  'yaml',
  'go',
  'rust',
  'dart',
}
require('nvim-treesitter').install(ensure_installed)
local available_parsers = require 'nvim-treesitter.parsers'
local function start_treesitter(buf, lang)
  if
    not vim.api.nvim_buf_is_valid(buf)
    or not vim.api.nvim_buf_is_loaded(buf)
    or vim.treesitter.language.get_lang(vim.bo[buf].filetype) ~= lang
  then
    return false
  end

  local started = pcall(vim.treesitter.start, buf, lang)
  if started then
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      vim.wo[win].foldmethod = 'expr'
      vim.wo[win].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      vim.wo[win].foldlevel = 99
    end
  end
  return started
end
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
  pattern = '*',
  callback = function(event)
    local lang = vim.treesitter.language.get_lang(event.match)
    if not lang then
      return
    end

    if not start_treesitter(event.buf, lang) and available_parsers[lang] then
      require('nvim-treesitter').install({ lang }):await(vim.schedule_wrap(function(err, installed)
        if not err and installed then
          start_treesitter(event.buf, lang)
        end
      end))
    end
  end,
})
vim.api.nvim_create_autocmd('PackChanged', {
  group = vim.api.nvim_create_augroup('treesitter-update', { clear = true }),
  callback = function(ev)
    if ev.data.kind == 'update' and ev.data.spec.name == 'nvim-treesitter' then
      require('nvim-treesitter').update()
    end
  end,
})

---@class TOMapping
---@field query string Textobject capture query
---@field query_group? string Optional query group within the capture
---@field desc? string Description for which textobject this is

---@class SelectMapping
---@field [string] string | TOMapping to textobject capture

---@class MOMapping
---@field query string Textobject capture query
---@field query_group? string Optional query group within the capture
---@field desc? string Description for which textobject this is
---@field func? 'goto_next' | 'goto_next_start' | 'goto_next_end' | 'goto_previous' | 'goto_previous_start' | 'goto_previous_end'

---@class MoveMapping
---@field [string] string | MOMapping

---@class TextObjectMappings
---@field select? SelectMapping
---@field move? MoveMapping

---@param mappings TextObjectMappings
local function add_textobject_mappings(mappings)
  for keymap, tobj in pairs(mappings.select or {}) do
    local query, query_group
    if type(tobj) == 'string' then
      query = tobj
    elseif type(tobj) == 'table' then
      query = tobj.query
      query_group = tobj.query_group
    else
      error('Invalid textobject mapping for keymap ' .. keymap)
    end
    vim.keymap.set({ 'x', 'o' }, keymap, function()
      require('nvim-treesitter-textobjects.select').select_textobject(query, query_group or 'textobjects')
    end, { desc = tobj.desc or ('Select textobject ' .. tostring(tobj)) })
  end

  for keymap, tobj in pairs(mappings.move or {}) do
    local query, query_group, func, desc
    query = tobj
    query_group = 'textobjects'
    func = 'go_to_start'
    desc = 'Move to textobject ' .. tostring(tobj)
    if type(tobj) == 'table' then
      query = tobj.query
      query_group = tobj.query_group
      func = tobj.func
      desc = tobj.desc
    elseif type(tobj) ~= 'string' then
      error('Invalid textobject mapping for keymap ' .. keymap)
    end
    vim.keymap.set({ 'n', 'x', 'o' }, keymap, function()
      require('nvim-treesitter-textobjects.move')[func](query, query_group or 'textobjects')
    end, { desc = desc })
  end
end
require('nvim-treesitter-textobjects').setup {
  select = {
    lookahead = true,
    selection_modes = {
      ['@parameter.outer'] = 'v', -- charwise
      ['@function.outer'] = 'V', -- linewise
      ['@class.outer'] = '<c-v>', -- blockwise
    },
    include_surrounding_whitespace = true,
  },
  move = {
    set_jumps = false, -- whether to set jumps in the jumplist
  },
}
add_textobject_mappings {
  select = {
    ['af'] = '@function.outer',
    ['if'] = '@function.inner',
    ['ac'] = '@class.outer',
    ['ic'] = '@class.inner',
    ['aa'] = '@parameter.outer',
    ['ia'] = '@parameter.inner',
    ['as'] = { query = '@local.scope', query_group = 'locals' },
  },
  move = {
    ['[f'] = { query = '@function.outer', func = 'goto_previous_start', desc = 'Go to previous function start' },
    [']f'] = { query = '@function.outer', func = 'goto_next_start', desc = 'Go to next function start' },
    ['[c'] = { query = '@class.outer', func = 'goto_previous_start', desc = 'Go to previous class start' },
    [']c'] = { query = '@class.outer', func = 'goto_next_start', desc = 'Go to next class start' },
  },
}

require('treesitter-context').setup {
  multiwindow = true,
}

require('netrw').setup {
  icons = {
    symlink = '',
    directory = '',
    file = '',
  },
  use_devicons = vim.g.have_nerd_font,
  mappings = {
    ['<C-c>'] = '<cmd>bd<CR>', -- Close the current Netrw buffer
    ['<C-h>'] = '<C-o>zz', -- Go back in jump list and center
    ['<C-l>'] = '<C-i>zz', -- Go forward in jump list and center
    ['<Tab>'] = 'mf', -- Mark the file/directory to the mark list
    ['<S-Tab>'] = 'mF', -- Unmark all the files/directories
    ['<leader>r'] = '<cmd>e!<CR>', -- Refresh netrw
    ['N'] = function()
      vim.notify('Creating new file...', vim.log.levels.INFO)
      local dir = vim.b.netrw_curdir or vim.fn.expand '%:p:h'
      vim.ui.input({ prompt = 'Enter filename: ' }, function(input)
        if input and input ~= '' then
          local filepath = vim.fs.normalize(dir .. '/' .. input)
          -- Create parent directories if they don't exist (for paths like "subdir/file.txt")
          local parent_dir = vim.fn.fnamemodify(filepath, ':h')
          if vim.fn.isdirectory(parent_dir) == 0 then
            vim.fn.mkdir(parent_dir, 'p')
          end
          local fd, err = vim.uv.fs_open(filepath, 'wx', 438)
          if fd then
            vim.uv.fs_close(fd)
            -- Refresh netrw using edit command
            vim.schedule(function()
              vim.cmd('edit ' .. vim.fn.fnameescape(dir))
            end)
          else
            vim.notify(('Failed to create file: %s (%s)'):format(filepath, err), vim.log.levels.ERROR)
          end
        end
      end)
    end, -- Improved file creation
  },
}

vim.g.nvim_surround_no_normal_mappings = true
vim.g.nvim_surround_no_insert_mappings = true
vim.g.nvim_surround_no_visual_mappings = true
require('nvim-surround').setup {}
vim.keymap.set('i', '<C-l>', '<Plug>(nvim-surround-insert)', { desc = 'Surround in insert mode' })
vim.keymap.set('i', '<C-l><C-l>', '<Plug>(nvim-surround-insert-line)', { desc = 'Surround line in insert mode' })
vim.keymap.set('n', 's', '<Plug>(nvim-surround-normal)', { desc = 'Surround in normal mode' })

require('nvim-autopairs').setup {
  check_ts = true,
}

require('tabout').setup {
  tabkey = '<Tab>',
  backwards_tabkey = '<S-Tab>',
  act_as_tab = true,
  act_as_shift_tab = false,
  enable_backwards = true,
  completion = true,
  ignore_beginning = true,
  exclude = {},
}

require('colorizer').setup {}

require('flash').setup {
  labels = 'arstgmneioqwfpbjluyzxcdvkh',
  search = {
    exclude = {
      'blink-cmp-menu',
      'blink-cmp-documentation',
      'blink-cmp-signature',
    },
  },
  modes = {
    search = {
      enabled = true,
    },
    char = {
      jump_labels = true,
    },
  },
}

vim.keymap.set({ 'n', 'x', 'o' }, 'zk', function()
  require('flash').jump()
end, { desc = 'Flash' })
vim.keymap.set({ 'n', 'x', 'o' }, 'zt', function()
  require('flash').treesitter()
end, { desc = 'Flash Treesitter' })
vim.keymap.set({ 'o', 'x' }, 'zr', function()
  require('flash').remote()
end, { desc = 'Remote Flash' })
vim.keymap.set({ 'o', 'x' }, 'zs', function()
  require('flash').treesitter_search()
end, { desc = 'Treesitter Search' })
vim.keymap.set({ 'n', 'x', 'o' }, '<c-space>', function()
  require('flash').treesitter {
    actions = {
      ['<c-space>'] = 'next',
      ['<BS>'] = 'prev',
    },
  }
end, { desc = 'Treesitter incremental selection' })

require('sidekick').setup {
  nes = {
    enabled = true,
    jumplist = false,
  },
  copilot = { status = { enabled = true, level = vim.log.levels.OFF } },
}

vim.keymap.set('n', '<C-i>', function()
  -- if there is a next edit, jump to it, otherwise apply it if any
  if not require('sidekick').nes_jump_or_apply() then
    return '<C-i>' -- fallback to normal tab
  end
end, { desc = 'Goto/Apply Next Edit Suggestion', expr = true })

require('copilot').setup {
  panel = { enabled = false },
  suggestion = {
    auto_trigger = true,
    trigger_on_accept = false,
    keymap = {
      accept = false,
      accept_line = '<C-d>',
      accept_word = '<C-s>',
      next = '<C-g>',
      prev = false,
      dismiss = false,
    },
  },
  nes = { enabled = false },
}

vim.api.nvim_create_autocmd('User', {
  group = vim.api.nvim_create_augroup('copilot-blink', { clear = true }),
  pattern = { 'BlinkCmpMenuOpen', 'BlinkCmpMenuClose' },
  callback = function(event)
    vim.b[event.buf].copilot_suggestion_hidden = event.match == 'BlinkCmpMenuOpen'
  end,
})
