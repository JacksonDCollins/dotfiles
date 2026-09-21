local M = {}

local function is_object(value)
  if type(value) ~= 'table' or vim.islist(value) then
    return false
  end
  for key in pairs(value) do
    if type(key) ~= 'string' then
      return false
    end
  end
  return true
end

local function is_string_list(value)
  if type(value) ~= 'table' or not vim.islist(value) then
    return false
  end
  for _, item in ipairs(value) do
    if type(item) ~= 'string' or item == '' then
      return false
    end
  end
  return true
end

local function is_root_markers(value)
  if type(value) ~= 'table' or not vim.islist(value) then
    return false
  end
  for _, marker in ipairs(value) do
    if (type(marker) ~= 'string' or marker == '') and (not is_string_list(marker) or #marker == 0) then
      return false
    end
  end
  return true
end

local allowed_fields = {
  settings = { is_object, 'an object' },
  init_options = { is_object, 'an object' },
  root_markers = { is_root_markers, 'a list of markers' },
  filetypes = { is_string_list, 'a list of filetypes' },
  root_dir = {
    function(value)
      return type(value) == 'string' and value ~= ''
    end,
    'a non-empty string',
  },
  single_file_support = {
    function(value)
      return type(value) == 'boolean'
    end,
    'a boolean',
  },
  workspace_required = {
    function(value)
      return type(value) == 'boolean'
    end,
    'a boolean',
  },
  offset_encoding = {
    function(value)
      return value == 'utf-8' or value == 'utf-16' or value == 'utf-32'
    end,
    'utf-8, utf-16, or utf-32',
  },
}

local function notify_invalid(project_file, message)
  vim.notify(('Invalid project config in %s: %s'):format(project_file, message), vim.log.levels.ERROR)
end

local function validate_servers(project_file, source, servers)
  if servers == nil then
    return {}
  end
  if not is_object(servers) then
    notify_invalid(project_file, ('lsp.%s must be an object'):format(source))
    return {}
  end

  local validated = {}
  for server, config in pairs(servers) do
    if server == '' or server:find('*', 1, true) then
      notify_invalid(project_file, ('lsp.%s contains an invalid server name %q'):format(source, server))
    elseif config == false then
      validated[server] = false
    elseif not is_object(config) then
      notify_invalid(project_file, ('lsp.%s.%s must be an object or false'):format(source, server))
    else
      local safe_config = {}
      for field, value in pairs(config) do
        local field_config = allowed_fields[field]
        if not field_config then
          notify_invalid(project_file, ('ignored lsp.%s.%s.%s: field is not allowed'):format(source, server, field))
        elseif not field_config[1](value) then
          notify_invalid(
            project_file,
            ('ignored lsp.%s.%s.%s: expected %s'):format(source, server, field, field_config[2])
          )
        else
          safe_config[field] = value
        end
      end
      if next(safe_config) or not next(config) then
        validated[server] = safe_config
      end
    end
  end
  return validated
end

-- Overrides are session-scoped to the config found upward from the startup file/CWD; simultaneous projects need separate LSP configs.
---@param start_path? string
function M.read(start_path)
  start_path = start_path or vim.fn.getcwd()
  local stat = vim.uv.fs_stat(start_path)
  if stat and stat.type ~= 'directory' then
    start_path = vim.fs.dirname(start_path)
  end

  local found, project_files = pcall(vim.fs.find, '.nvim.json', {
    path = start_path,
    type = 'file',
    upward = true,
  })
  local project_file = found and project_files[1] or nil
  if not project_file then
    return {}
  end

  local read_ok, file_content = pcall(vim.secure.read, project_file)
  if not read_ok then
    vim.notify('Failed to read ' .. project_file .. ': ' .. file_content, vim.log.levels.ERROR)
    return {}
  end
  if type(file_content) ~= 'string' then
    return {}
  end

  local ok, project = pcall(vim.json.decode, file_content)
  if not ok then
    vim.notify('Failed to parse ' .. project_file .. ': ' .. project, vim.log.levels.ERROR)
    return {}
  end
  if not is_object(project) then
    notify_invalid(project_file, 'top-level value must be an object')
    return {}
  end

  if project.lsp ~= nil then
    if not is_object(project.lsp) then
      notify_invalid(project_file, 'lsp must be an object')
      project.lsp = nil
    else
      for field in pairs(project.lsp) do
        if field ~= 'mason' and field ~= 'others' then
          notify_invalid(project_file, ('ignored lsp.%s: unknown fields are not allowed'):format(field))
        end
      end
      project.lsp = {
        mason = validate_servers(project_file, 'mason', project.lsp.mason),
        others = validate_servers(project_file, 'others', project.lsp.others),
      }
    end
  end

  return project
end

return M
