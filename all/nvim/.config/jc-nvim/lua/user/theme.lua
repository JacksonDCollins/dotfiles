local fallback = {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    opts = {
      flavour = 'mocha',
      auto_integrations = true,
    },
  },
  {
    'LazyVim/LazyVim',
    opts = { colorscheme = 'catppuccin-mocha' },
  },
}

local function find_theme(specs)
  local plugin, selector
  for _, spec in ipairs(type(specs) == 'table' and specs or {}) do
    if type(spec) == 'table' then
      if spec[1] == 'LazyVim/LazyVim' then
        selector = spec
      elseif not plugin and (type(spec[1]) == 'string' or type(spec.dir) == 'string') then
        plugin = spec
      end
    end
  end
  return plugin, selector
end

local ok, specs = pcall(require, 'user.omarchy.neovim')
local plugin, selector = find_theme(ok and specs or nil)
local selector_opts = selector and type(selector.opts) == 'table' and selector.opts or {}
local colorscheme = selector_opts.colorscheme

if
  not plugin
  or (type(colorscheme) ~= 'string' and type(colorscheme) ~= 'function' and type(plugin.config) ~= 'function')
then
  plugin, selector = find_theme(fallback)
  selector_opts = selector.opts
  colorscheme = selector_opts.colorscheme
end

local packs, ordered = {}, {}
local function collect(value)
  local spec = type(value) == 'string' and { value } or value
  assert(type(spec) == 'table', 'invalid theme plugin specification')

  local dependencies = spec.dependencies
  if dependencies ~= nil then
    dependencies = type(dependencies) == 'table' and dependencies or { dependencies }
    for _, dependency in ipairs(dependencies) do
      collect(dependency)
    end
  end

  ordered[#ordered + 1] = spec
  if spec.dir then
    local path = vim.fs.normalize(vim.fn.expand(spec.dir))
    vim.opt.rtp:prepend(path)
    local after = vim.fs.joinpath(path, 'after')
    if vim.uv.fs_stat(after) then
      vim.opt.rtp:append(after)
    end
    return
  end

  assert(type(spec[1]) == 'string', 'theme plugin needs a repository or dir')
  local version = spec.branch
  if not version and spec.version ~= nil and spec.version ~= false then
    version = type(spec.version) == 'string' and assert(vim.version.range(spec.version)) or spec.version
  end
  packs[#packs + 1] = {
    src = 'https://github.com/' .. spec[1],
    name = spec.name,
    version = version,
  }
end

collect(plugin)
if #packs > 0 then
  vim.pack.add(packs, { load = true })
end

local function module_name(spec)
  local name = spec.main
    or spec.name
    or (spec[1] and spec[1]:match '([^/]+)$')
    or vim.fs.basename(vim.fn.expand(spec.dir))
  return name:gsub('%.git$', '')
    :gsub('%.nvim$', '')
    :gsub('%-nvim$', '')
    :gsub('^nvim%-', '')
    :gsub('%.lua$', '')
end

local function configure(spec, extra)
  local opts = vim.deepcopy(extra or {})
  opts.colorscheme = nil
  if type(spec.opts) == 'table' then
    opts = vim.tbl_deep_extend('force', opts, spec.opts)
  elseif type(spec.opts) == 'function' then
    opts = spec.opts(spec, opts) or opts
  end

  if type(spec.config) == 'function' then
    spec.config(spec, opts)
  elseif spec.config ~= false and (spec.config == true or spec.opts ~= nil or next(opts) ~= nil) then
    require(module_name(spec)).setup(opts)
  end
end

for _, spec in ipairs(ordered) do
  configure(spec, spec == plugin and selector_opts or nil)
end

if type(colorscheme) == 'function' then
  colorscheme()
elseif colorscheme then
  vim.cmd.colorscheme(colorscheme)
end
