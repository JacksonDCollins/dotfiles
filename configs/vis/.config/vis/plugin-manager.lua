local cache_home = os.getenv('XDG_CACHE_HOME')
if not cache_home or cache_home:sub(1, 1) ~= '/' then
	local home = assert(os.getenv('HOME'), 'HOME is not set')
	assert(home:sub(1, 1) == '/', 'HOME must be an absolute path')
	cache_home = home .. '/.cache'
end
local vis_path = cache_home .. '/vis'
local plugins_path = vis_path .. '/plugins'
package.path = plugins_path .. '/?.lua;'
	.. plugins_path .. '/?/init.lua;'
	.. package.path

if not package.searchpath('vis-plug', package.path) then
	local destination = plugins_path .. '/vis-plug'
	local quoted_destination = "'" .. destination:gsub("'", "'\\''") .. "'"
	local ok = os.execute('git clone --quiet https://github.com/erf/vis-plug ' .. quoted_destination)
	assert(ok, 'Failed to clone vis-plug into ' .. destination)
end
local plug = require('vis-plug')
plug.path(vis_path)

local plugins = {
	{ 'https://codeberg.org/muhq/vis-lspc' },
}

plug.init(plugins, true)
