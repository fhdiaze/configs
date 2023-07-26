local lsp = require('lsp-zero')

lsp.preset({})

lsp.on_attach(function(client, bufnr)
  lsp.default_keymaps({ buffer = bufnr })
  local opts = { buffer = bufnr }
  local bind = vim.keymap.set

  bind('n', '<leader>r', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
  bind('n', '<leader>.', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
  bind('n', '<leader>gr', require('telescope.builtin').lsp_references, opts)
end)

lsp.ensure_installed({
  -- Replace these with whatever servers you want to install
  'tsserver',
  'eslint',
  'rust_analyzer',
  'lua_ls',
  'omnisharp',
  'volar'
})

-- (Optional) Configure lua language server for neovim
require('lspconfig').lua_ls.setup(lsp.nvim_lua_ls())

lsp.nvim_workspace({
  library = vim.api.nvim_get_runtime_file('', true)
})

vim.diagnostic.config({
    virtual_text = false,
    unerline = true,
})

lsp.setup()

local cmp = require('cmp')

cmp.setup({
  preselect = 'item',
  completion = {
    autocomplete = false,
    completeopt = 'menu,menuone,noinsert'
  },
  sources = {
    {name = 'path'},
    {name = 'nvim_lsp'},
    {name = 'nvim_lua'},
    {name = 'buffer', keyword_length = 3},
    {name = 'luasnip', keyword_length = 2},
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  mapping = {
    -- `Enter` key to confirm completion
    ['<CR>'] = cmp.mapping.confirm({select = false}),

    -- Ctrl+Space to trigger completion menu
    ['<C-Space>'] = cmp.mapping.complete(),
  }
})

