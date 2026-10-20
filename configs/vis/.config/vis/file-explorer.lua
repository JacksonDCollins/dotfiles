require('vis')
local keys = require('keymaps')

local function shell_quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function open_explorer(startup)
    if not vis.modes.TERMINAL then
        vis:info('Terminal buffers require an updated vis-retained-terminal package; rebuild the fork with makepkg -fsi')
        return false
    end
    local win = vis.win
    local original = win.file
    local current = original.path or (not original.terminal and original.name) or '.'
    local ok, err = pcall(vis.terminal, vis,
        'exec "$HOME/.local/bin/nnn-dotfiles" -0 -p - -- ' .. shell_quote(current), true,
        function(status, output, terminal)
            local path = status == 0 and output:match('^[^%z]+')
            -- Do not reopen a closed split or replace a buffer the user switched to.
            for window in vis:windows() do
                if window == win and window.file == terminal then
                    local opened, open_error = pcall(function() window.file = path or original end)
                    if not opened then
                        if path then pcall(function() window.file = original end) end
                        vis:info('Could not open file: ' .. tostring(open_error))
                    elseif startup and not path and vis.win == window then
                        vis:command('q')
                    end
                    break
                end
            end
            if status > 0 then vis:info('nnn exited with status ' .. status) end
            return true -- discard the completed picker buffer once no split displays it
        end)
    if not ok then vis:info('Could not run nnn: ' .. tostring(err)) end
    return ok
end

vis:map(vis.modes.NORMAL, keys.file_explorer.open, function()
    open_explorer()
end, 'Open file explorer')

vis.events.subscribe(vis.events.START, function()
    if os.getenv('VIS_NNN_START') == '1' and not open_explorer(true) then
        vis:command('q')
    end
end)
