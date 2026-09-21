vim.api.nvim_create_user_command('Keycourse', function()
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    if vim.t[tab].keycourse_directory then
      vim.api.nvim_set_current_tabpage(tab)
      local window = vim.t[tab].keycourse_guide_window
      if window and vim.api.nvim_win_is_valid(window) then
        vim.api.nvim_set_current_win(window)
      end
      return
    end
  end

  local tutorial = assert(vim.api.nvim_get_runtime_file('tutor/jc-nvim.tutor', false)[1], 'Course file not installed')
  local directory = vim.fn.tempname()
  vim.fn.mkdir(directory .. '/files', 'p')
  local files = {
    ['practice.lua'] = [[local M = {}

function M.greet(name, punctuation)
  local message = "hello " .. name
  return message .. punctuation
end

function M.total(first, second)
  return first + second
end

-- Edit only this temporary project during the course.
-- WORDS: red green blue
-- MOVE: one
-- MOVE: two
-- MOVE: three
-- JOIN: hello
-- world
-- REPLACE: banana banana
-- REPLACE: banana

return M]],
    ['other.lua'] = [[local practice = require("practice")

print(practice.greet("friend", "!"))
print(practice.total(2, 3))]],
    ['model.py'] = [[class Basket:
    def __init__(self, price):
        self.price = price

    def total(self, count):
        return self.price * count


class Receipt:
    def render(self, label):
        return "Receipt: " + label]],
    ['files/note.txt'] = [[This is a disposable file for netrw exercises.]],
  }
  for name, contents in pairs(files) do
    vim.fn.writefile(vim.split(contents, '\n'), directory .. '/' .. name)
  end

  -- Only initialize a local sandbox: no commits, remotes, or changes to the user's repo.
  if vim.fn.executable 'git' == 1 then
    local result = vim.system({ 'git', 'init', '--quiet', directory }, { text = true }):wait()
    if result.code ~= 0 then
      vim.notify('Course Git exercises unavailable: ' .. result.stderr, vim.log.levels.WARN)
    end
  end

  vim.cmd.tabnew()
  vim.cmd.tcd(vim.fn.fnameescape(directory))
  vim.cmd.arglocal()
  -- Tutor uses :drop, which can switch tabs and replace the global argument list.
  vim.fn['tutor#SetupVim']()
  vim.cmd.edit(vim.fn.fnameescape(tutorial))
  if not vim.b.tutor_extmarks then
    vim.fn['tutor#EnableInteractive'](true)
    vim.fn['tutor#ApplyTransform']()
  end
  local guide_window = vim.api.nvim_get_current_win()
  vim.t.keycourse_directory = directory
  vim.t.keycourse_guide_window = guide_window
  vim.cmd.vsplit(vim.fn.fnameescape(directory .. '/practice.lua'))
  vim.api.nvim_set_current_win(guide_window)
end, { desc = 'Open the keybinding course with a temporary practice project' })
