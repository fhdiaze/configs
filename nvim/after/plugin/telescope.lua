local telescope = require('telescope')
local builtin = require('telescope.builtin')

telescope.setup {
    defaults = {
        layout_strategy = 'vertical',
    },
}

vim.keymap.set('n', '<leader>sg', builtin.git_files, { desc = '[S]earch [G]it files' })
vim.keymap.set('n', '<leader>st', builtin.treesitter, { desc = '[S]earch [T]ree sitter symbols' })
vim.keymap.set('n', '<leader>so', builtin.oldfiles, { desc = '[S]earch recently [O]pened files' })
vim.keymap.set('n', '<leader>sb', builtin.buffers, { desc = '[S]earch existing [B]uffers' })
vim.keymap.set('n', '<leader>sp', builtin.live_grep, { desc = '[S]earch [P]roject' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>scb', builtin.current_buffer_fuzzy_find, { desc = '[S]earch [C]urrent [B]uffer' })
vim.keymap.set('n', '<leader>ss', builtin.spell_suggest, { desc = '[S]earch [S]pell suggestions' })
vim.keymap.set('n', '<leader>/', builtin.current_buffer_fuzzy_find, { desc = '[/] Fuzzily search in current buffer' })
vim.keymap.set('n', '<C-p>', builtin.find_files, {})
