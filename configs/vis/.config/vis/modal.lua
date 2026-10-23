require('vis')

local MODES = {
	[vis.modes.NORMAL] = ' NORMAL ',
	[vis.modes.INSERT] = ' INSERT ',
	[vis.modes.VISUAL] = ' VISUAL ',
	[vis.modes.REPLACE] = ' REPLACE ',
	[vis.modes.VISUAL_LINE] = ' VISUAL_LINE ',
	[vis.modes.OPERATOR_PENDING] = ' OPERATOR_PENDING ',
}

if vis.modes.TERMINAL then
	MODES[vis.modes.TERMINAL] = ' TERMINAL '
end

local STYLE_IDS = { UNFOCUSED = {} }
for mode in pairs(MODES) do STYLE_IDS[mode] = {} end

for _, style in pairs(STYLE_IDS) do
	style.regular_id = assert(vis.ui:style_push(), 'No style slots available for modal')
	style.inverted_id = assert(vis.ui:style_push(), 'No style slots available for modal')
end

vis.events.subscribe(vis.events.WIN_STATUS, function(win)
	local modified = ''
	if win.file.modified then modified = ' *' end
	local filename = ' [NO NAME]'..modified..' '
	if win.file.name then filename = ' '..win.file.name..modified..' ' end
	local vmode = MODES[vis.mode] or ' UNKNOWN '
	local recording = ''
	if vis.recording then recording = ' @ RECORDING ' end
	local status_left = vmode..filename..recording

	local cursors = 0
	for _ in win:selections_iterator() do cursors = cursors + 1 end
	local range = win.selection.range
	local selection_size = "SELECTION_SIZE: "..(range.finish - range.start)
	local cursor_amount = "CURSORS: "..cursors
	local cursor_pos = win.selection.line..":"..win.selection.col
	local status_right = selection_size.." | "..cursor_amount.." | "..cursor_pos

	win:status(status_left, status_right)

	local focused = win == vis.win
	local mode = focused and (MODES[vis.mode] and vis.mode or vis.modes.NORMAL) or 'UNFOCUSED'
	local style = STYLE_IDS[mode]
	local lexers = vis.lexers
	local theme = lexers.MODAL_STYLES and lexers.MODAL_STYLES[mode]
	local default = lexers.STYLE_DEFAULT or ''
	local regular = theme and theme.REGULAR or (focused and lexers.STYLE_STATUS_FOCUSED or lexers.STYLE_STATUS) or default
	local inverted = theme and theme.INVERTED or default
	vis.ui:style_define(style.regular_id, default..','..regular)
	vis.ui:style_define(style.inverted_id, default..','..inverted)

	for i = 0, win.width - 1 do
		win:style_pos(style.regular_id, i, win.height - 1)
	end
	-- shortcut: filename highlighting uses byte length; use display width when the Lua API exposes it.
	for i = #vmode, math.min(#vmode + #filename, win.width) - 1 do
		win:style_pos(style.inverted_id, i, win.height - 1)
	end

end)
