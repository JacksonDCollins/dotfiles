require('vis')

local function open_explorer()
    local current = vis.win.file.path or vis.win.file.name or '.'
    local quoted = "'" .. current:gsub("'", "'\\''") .. "'"
    local status, output = vis:pipe('',
        '"$HOME/.local/bin/nnn-dotfiles" -0 -p - -- ' .. quoted ..
        ' </dev/tty 2>/dev/tty', true)
    local path = output and output:match('^[^%z]+')
    if status == 0 and path then
        -- Vis sends glob-like names through a shell, so quote those twice.
        if path:find('[*?%[{$]') then
            path = "'" .. path:gsub("'", "'\\''") .. "'"
        end
        local escaped = path:gsub('\\', '\\\\'):gsub('"', '\\"')
            :gsub('\n', '\\n'):gsub('\t', '\\t')
        return vis:command('e "' .. escaped .. '"')
    end
    return false
end

vis:map(vis.modes.NORMAL, ' e', function()
    open_explorer()
end, 'Open file explorer')

vis.events.subscribe(vis.events.START, function()
    if os.getenv('VIS_NNN_START') == '1' and not open_explorer() then
        vis:command('q')
    end
end)
