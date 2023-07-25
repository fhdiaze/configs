local themes = require('telescope.themes')
local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>sg', builtin.git_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>st', builtin.treesitter, { desc = '[S]earch [T]ree sitter symbols' })
vim.keymap.set('n', '<leader>so', builtin.oldfiles, { desc = '[S]earch recently [O]pened files' })
vim.keymap.set('n', '<leader>sb', builtin.buffers, { desc = 'Search existing [B]uffers' })
vim.keymap.set('n', '<leader>sp', builtin.live_grep, { desc = '[S]earch [P]roject' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>/', function()
  builtin.current_buffer_fuzzy_find(themes.get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })
vim.keymap.set('n', '<C-p>', builtin.find_files, {})

