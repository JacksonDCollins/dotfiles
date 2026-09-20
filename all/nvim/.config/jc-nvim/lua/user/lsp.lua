require('mason').setup()
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

require('mason-lspconfig').setup {
  ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
  automatic_enable = false, -- automatically run vim.lsp.enable() for all servers that are installed via Mason
}

---@class LspServersConfig
---@field mason table<string, any> config for language servers that are installed via Mason
---@field others table<string, any> config for language servers that are *not* installed via

vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('lsp-vim-enter', { clear = true }),
  callback = function(event)
    local buffer_path = vim.api.nvim_buf_get_name(event.buf)
    local start_path = vim.fn.getcwd()
    if buffer_path ~= '' then
      local stat = vim.uv.fs_stat(buffer_path)
      start_path = stat and stat.type == 'directory' and buffer_path or vim.fs.dirname(buffer_path)
    end

    ---@type LspServersConfig
    local project_vals = require('user.project').read(start_path).lsp or { mason = {}, others = {} }

    ---@type LspServersConfig
    local config_servers = {
      mason = {
        -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
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
        phpactor = {
          root_markers = { '.phpactor.json', '.phpactor.yml', 'composer.json', '.git' },
        },
        zls = {},
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
            },
          },
        },
      },
      -- This table contains config for all language servers that are *not* installed via Mason.
      -- Structure is identical to the mason table from above.
      others = {
        dartls = {},
      },
    }
    local servers = vim.deepcopy(config_servers)
    for source, overrides in pairs(project_vals) do
      for server, config in pairs(overrides) do
        if config == false then
          servers[source][server] = nil
        else
          servers[source][server] = vim.tbl_deep_extend('force', servers[source][server] or {}, config)
        end
      end
    end

    local ensure_installed = vim.tbl_keys(servers.mason)
    local all_servers = vim.tbl_extend('keep', servers.mason, servers.others)

    local formatter_tools =
      vim.list.unique(vim.iter(vim.tbl_values(require('conform').formatters_by_ft or {})):flatten():totable())
    vim.list_extend(
      ensure_installed,
      vim.tbl_map(function(tool)
        return {
          tool,
          condition = function()
            return vim.tbl_contains(require('mason-registry').get_all_package_names(), tool)
          end,
        }
      end, formatter_tools)
    )
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }
    vim.api.nvim_create_autocmd('User', {
      pattern = 'MasonToolsUpdateCompleted',
      group = vim.api.nvim_create_augroup('lsp-mason-tools-update', { clear = true }),
      callback = function(e)
        local package_to_server = require('mason-lspconfig').get_mappings().package_to_lspconfig
        local handled = {}
        for _, package in ipairs(e.data or {}) do
          local server = package_to_server[package]
          if server and all_servers[server] and not handled[server] then
            handled[server] = true
            local has_active_clients = #vim.lsp.get_clients { name = server } > 0
            pcall(vim.lsp.enable, server)
            if has_active_clients then
              pcall(vim.api.nvim_cmd, { cmd = 'lsp', args = { 'restart', server } }, {})
            end
          end
        end
      end,
    })

    for server, config in pairs(all_servers) do
      if not vim.tbl_isempty(config) then
        vim.lsp.config(server, config)
      end
    end

    if not vim.tbl_isempty(all_servers) then
      vim.lsp.enable(vim.tbl_keys(all_servers))
    end
  end,
})
