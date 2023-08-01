vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("i", "<C-c>", "<Esc>", { unique = true })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { unique = true })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { unique = true })
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, { unique = true })
vim.keymap.set("n", "n", "nzzzv", { unique = true })
vim.keymap.set("n", "N", "Nzzzv", { unique = true })
vim.keymap.set("n", "<C-s>", ":w<cr>", { unique = true })
vim.keymap.set("n", "<leader>j", "<C-w>j", { unique = true })
vim.keymap.set("n", "<leader>k", "<C-w>k", { unique = true })
vim.keymap.set("n", "<leader>h", "<C-w>h", { unique = true })
vim.keymap.set("n", "<leader>l", "<C-w>l", { unique = true })
vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format() end)
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message', unique = true })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list', unique = true})

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { unique = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { unique = true })

vim.keymap.set("x", "<leader>p", "\"_dP", { unique = true })

vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { unique = true })

vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.keymap.set({ "n", "v"}, "<leader>d", [["_d]], { unique = true })
