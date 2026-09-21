local function resolve_tmux_command(cmd)
  local handle = io.popen(cmd)
  local result = ''
  if handle ~= nil then
    result = handle:read('*a'):gsub('\n', '')
    handle:close()
  end
  return result
end

local function get_tmux_option(option_name)
  local handle = io.popen('tmux show-option -gqv ' .. option_name)
  local option_value = ''
  if handle ~= nil then
    option_value = handle:read('*a'):gsub('\n', '')
    handle:close()
  end
  if string.sub(option_value, 0, 2) == '#(' then
    option_value = resolve_tmux_command(string.sub(option_value, 3, -2))
    vim.notify('Resolved tmux option ' .. option_name .. ' to ' .. option_value)
  end
  return option_value
end

local tmux_status_bar_bg = get_tmux_option '@tmux-dotbar-bg'
local tmux_status_bar_fg = get_tmux_option '@tmux-dotbar-fg'
local tmux_status_bar_fg_current = get_tmux_option '@tmux-dotbar-fg-current'

local function apply_statusline_highlights()
  vim.api.nvim_set_hl(
    0,
    'TmuxStatusLineDim',
    tmux_status_bar_bg ~= '' and tmux_status_bar_fg ~= '' and { bg = tmux_status_bar_bg, fg = tmux_status_bar_fg }
      or { link = 'StatusLineNC' }
  )
  vim.api.nvim_set_hl(
    0,
    'TmuxStatusLineCurrent',
    tmux_status_bar_bg ~= ''
        and tmux_status_bar_fg_current ~= ''
        and { bg = tmux_status_bar_bg, fg = tmux_status_bar_fg_current }
      or { link = 'StatusLine' }
  )
  vim.api.nvim_set_hl(
    0,
    'CopilotActiveStatusLine',
    tmux_status_bar_bg ~= ''
        and { fg = vim.api.nvim_get_hl(0, { name = 'DiagnosticInfo', link = false }).fg, bg = tmux_status_bar_bg }
      or { link = 'DiagnosticInfo' }
  )
end

apply_statusline_highlights()

local config = {
  dim = 'TmuxStatusLineDim',
  active = 'TmuxStatusLineCurrent',
}

local function hl(group, text)
  return string.format('%%#%s#%s%%*', group, text)
end

local function statusline_escape(text)
  return (text:gsub('%%', '%%%%'))
end

local function git()
  local git_info = vim.b.gitsigns_status_dict
  if not git_info or git_info.head == '' then
    return ''
  end

  local head = statusline_escape(git_info.head)
  local added = git_info.added and (' +' .. git_info.added) or ''
  local changed = git_info.changed and (' ~' .. git_info.changed) or ''
  local removed = git_info.removed and (' -' .. git_info.removed) or ''
  if git_info.added == 0 then
    added = ''
  end
  if git_info.changed == 0 then
    changed = ''
  end
  if git_info.removed == 0 then
    removed = ''
  end

  return hl(
    config.dim,
    table.concat {
      '[', -- branch icon
      head,
      added,
      changed,
      removed,
      ']',
    }
  )
end

local function filepath()
  if vim.api.nvim_buf_get_name(0) == '' then
    return hl(config.dim, '[No Name]')
  end

  local fpath = vim.fn.fnamemodify(vim.fn.expand '%', ':~:.:h')

  if fpath == '' or fpath == '.' then
    return hl(config.active, '[%t]%m%r')
  end

  return hl(config.active, string.format('[%s/%%t]%%m%%r', statusline_escape(fpath)))
end

local copilot_request_methods = {
  getCompletions = true,
  getCompletionsCycling = true,
  ['textDocument/copilotInlineEdit'] = true,
}

local function copilot_status()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients { name = 'copilot', bufnr = bufnr }
  if #clients == 0 then
    return '' -- Copilot not running
  end

  -- Check if there are active inline completion requests
  for _, client in ipairs(clients) do
    for _, req in pairs(client.requests or {}) do
      if req.bufnr == bufnr and req.type == 'pending' and copilot_request_methods[req.method] then
        return 'loading' -- Currently fetching suggestions
      end
    end
  end

  return 'idle' -- Ready and attached
end

local function refresh_statusline()
  vim.cmd.redrawstatus()
  if vim.g.loaded_tpipeline then
    pcall(vim.fn['tpipeline#update'])
  end
end

-- Timer for animating spinner
Statusline = Statusline or {}
local spinner_timer = Statusline._spinner_timer
if spinner_timer then
  spinner_timer:stop()
  spinner_timer:close()
  Statusline._spinner_timer = nil
  spinner_timer = nil
end

local function start_spinner()
  if spinner_timer then
    return -- Already running
  end
  spinner_timer = vim.uv.new_timer()
  if spinner_timer == nil then
    vim.schedule(refresh_statusline)
    return
  end
  Statusline._spinner_timer = spinner_timer
  spinner_timer:start(
    0,
    120, -- Update every 120ms for smooth animation
    vim.schedule_wrap(refresh_statusline)
  )
end

local function stop_spinner()
  if spinner_timer then
    spinner_timer:stop()
    spinner_timer:close()
    spinner_timer = nil
    Statusline._spinner_timer = nil
  end
  vim.schedule(refresh_statusline)
end

local function copilot()
  local status = copilot_status()

  -- Control spinner based on status
  if status == 'loading' then
    if not spinner_timer then
      start_spinner()
    end
  else
    if spinner_timer then
      stop_spinner()
    end
  end

  -- Define status display with icons and colors
  local status_map = {
    [''] = hl(config.dim, ''), -- Not available
    idle = hl('CopilotActiveStatusLine', ''), -- Ready
    loading = function()
      local spinners = { '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷' }
      local ms = vim.uv.hrtime() / 1000000
      local frame = math.floor(ms / 120) % #spinners
      return hl('CopilotActiveStatusLine', '[' .. spinners[frame + 1] .. ']')
    end,
  }

  local output = status_map[status] or hl(config.dim, '')
  if type(output) == 'function' then
    return output()
  else
    return output
  end
end

-- Autocmd to refresh statusline when LSP requests change
vim.api.nvim_create_autocmd('LspRequest', {
  group = vim.api.nvim_create_augroup('StatuslineLspRequest', { clear = true }),
  pattern = '*',
  callback = function(args)
    local request = args.data and args.data.request
    local client = args.data and vim.lsp.get_client_by_id(args.data.client_id)
    if
      args.buf == vim.api.nvim_get_current_buf()
      and client
      and client.name == 'copilot'
      and request
      and copilot_request_methods[request.method]
    then
      vim.schedule(refresh_statusline)
    end
  end,
})

function Statusline.active()
  return table.concat {
    filepath(),
    hl(config.dim, ' '),
    hl(config.dim, '%<'),
    git(),
    hl(config.dim, '%='),
    copilot(),
    hl(config.dim, ' %y [%P %l:%c]'),
  }
end

function Statusline.inactive()
  return ' %t'
end

local group = vim.api.nvim_create_augroup('Statusline', { clear = true })

vim.api.nvim_create_autocmd('ColorScheme', {
  group = group,
  desc = 'Reapply statusline highlights',
  callback = apply_statusline_highlights,
})

vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
  group = group,
  desc = 'Activate statusline on focus',
  callback = function()
    vim.opt_local.statusline = '%!v:lua.Statusline.active()'
  end,
})

vim.api.nvim_create_autocmd({ 'WinLeave', 'BufLeave' }, {
  group = group,
  desc = 'Deactivate statusline when unfocused',
  callback = function()
    vim.opt_local.statusline = '%!v:lua.Statusline.inactive()'
  end,
})
