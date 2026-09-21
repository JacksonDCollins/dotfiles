local document_highlight_method = vim.lsp.protocol.Methods.textDocument_documentHighlight
local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = true })

local function buffer_supports_document_highlight(bufnr, excluded_client_id)
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    if client.id ~= excluded_client_id and client:supports_method(document_highlight_method, bufnr) then
      return true
    end
  end
  return false
end

vim.api.nvim_create_autocmd('LspDetach', {
  group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
  callback = function(event)
    vim.lsp.util.buf_clear_references(event.buf)
    if not buffer_supports_document_highlight(event.buf, event.data.client_id) then
      vim.api.nvim_clear_autocmds { group = highlight_augroup, buffer = event.buf }
    end
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

    map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

    map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

    map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

    map('grd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

    map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')

    map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')

    map('grt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method(document_highlight_method, event.buf) then
      vim.api.nvim_clear_autocmds { group = highlight_augroup, buffer = event.buf }
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })
    end

    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
      map('<leader>th', function()
        local filter = { bufnr = event.buf }
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter), filter)
      end, '[T]oggle Inlay [H]ints')
    end
  end,
})

vim.diagnostic.config {
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = vim.diagnostic.severity.ERROR },
  signs = vim.g.have_nerd_font and {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  } or {},
  virtual_text = {
    source = 'if_many',
    spacing = 2,
    format = function(diagnostic)
      local diagnostic_message = {
        [vim.diagnostic.severity.ERROR] = diagnostic.message,
        [vim.diagnostic.severity.WARN] = diagnostic.message,
        [vim.diagnostic.severity.INFO] = diagnostic.message,
        [vim.diagnostic.severity.HINT] = diagnostic.message,
      }
      return diagnostic_message[diagnostic.severity]
    end,
  },
}

-- Executables are installed by dotfiles setup and resolved through mise shims.
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('lsp-vim-enter', { clear = true }),
  callback = function(event)
    local buffer_path = vim.api.nvim_buf_get_name(event.buf)
    local start_path = vim.fn.getcwd()
    if buffer_path ~= '' then
      local stat = vim.uv.fs_stat(buffer_path)
      start_path = stat and stat.type == 'directory' and buffer_path or vim.fs.dirname(buffer_path)
    end

    local project_vals = require('user.project').read(start_path).lsp or {}
    local servers = {
      clangd = {
        cmd = {
          'clangd',
          '--background-index',
          '--clang-tidy',
          '--header-insertion=iwyu',
          '--completion-style=detailed',
          '--function-arg-placeholders',
          '--fallback-style=llvm',
          '--query-driver=/usr/bin/x86_64-w64-mingw32-g++',
        },
      },
      gopls = {},
      rust_analyzer = {},
      ts_ls = {},
      zls = {},
      lua_ls = {
        settings = { Lua = { completion = { callSnippet = 'Replace' } } },
      },
      dartls = {},
      qmlls = {
        cmd = { 'qmlls6' },
      },
    }
    for server, config in pairs(project_vals) do
      if config == false then
        servers[server] = nil
      else
        servers[server] = vim.tbl_deep_extend('force', servers[server] or {}, config)
      end
    end

    for server, config in pairs(servers) do
      if not vim.tbl_isempty(config) then
        vim.lsp.config(server, config)
      end
    end

    if not vim.tbl_isempty(servers) then
      vim.lsp.enable(vim.tbl_keys(servers))
    end
  end,
})
