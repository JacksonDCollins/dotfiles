require('vis')

local brackets = {
	["("] = "()",
	["{"] = "{}",
	["["] = "[]",
	["<"] = "<>",
	["'"] = "''",
	['"'] = '""',
	['`'] = '``',
};

local closed = {
	[")"] = "",
	["}"] = "",
	["]"] = "",
	[">"] = "",
	["'"] = "",
	['"'] = "",
	["`"] = "",
};

local remove = {
	["()"] = "",
	["{}"] = "",
	["[]"] = "",
	["<>"] = "",
	["''"] = "",
	['""'] = "",
	['``'] = "",
};

local function is_bracket_or_empty(char)
	return char == '' or
		char == ' ' or
		char == '\t' or
		char == '\n' or
		brackets[char] ~= nil or
		closed[char] ~= nil
end

vis.events.subscribe(vis.events.INPUT, function(key)
	-- Pairing is single-cursor Insert behavior; other edits stay native.
	if vis.mode ~= vis.modes.INSERT or #vis.win.selections ~= 1 then
		return false
	end
	local file = vis.win.file
	local cursor = vis.win.selection.pos
	local next = file:content(cursor, 1)
	-- closed bracket already exists, skip
	if key == next and closed[next] ~= nil then
		vis:feedkeys('<Right>')
		return true
	end

	local result = brackets[key]
	if result ~= nil and is_bracket_or_empty(next) then
		vis:insert(result)
		vis:feedkeys('<Left>')
		return true
	end
	return false
end)

vis:map(vis.modes.INSERT, "<Backspace>", function()
	local win = vis.win
	if vis.mode == vis.modes.INSERT and #win.selections == 1 then
		local cursor = win.selection.pos
		if cursor > 0 and remove[win.file:content(cursor - 1, 2)] ~= nil then
			vis:feedkeys("<vis-delete-char-next>")
		end
	end
	vis:feedkeys("<vis-delete-char-prev>")
	return 0
end, "Removes the previous character (and closed brackets, if empty)")
