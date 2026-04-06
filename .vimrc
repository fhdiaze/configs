unlet! skip_defaults_vim
source $VIMRUNTIME/defaults.vim

let mapleader = "\<space>"

syntax enable
filetype plugin indent on
:set rnu!

set hlsearch incsearch ignorecase
set encoding=UTF-8

:set clipboard=unnamedplus

:nmap "<leader>pv" vim.cmd.Ex
set guioptions-=T  "remove toolbar

nnoremap <silent> <leader>p :Files<CR>
nnoremap <silent> <leader>f :Lines<CR>
nnoremap <silent> <leader>F :Ag<CR>
nnoremap <silent> <leader>b :Buffers <CR>
nnoremap <silent> <leader>g :GFiles <CR>

"Map buffer quick switch keys"
nnoremap <silent> <leader><Tab> <C-^>

"--- LSP settings ---------------------------------------------------"
let lspOptions = #{
    \ aleSupport: v:true,
    \ autoHighlight: v:true,
    \ completionTextEdit: v:true,
    \ noNewlineInCompletion: v:true,
    \ outlineOnRight: v:true,
    \ outlineWinSize: 70,
    \ showDiagWithSign: v:false,
    \ useQuickfixForLocations: v:true,
    \ }
autocmd VimEnter * call LspOptionsSet(lspOptions)

let lspServers = [
    \ #{ name: 'gopls', filetype: ['go', 'gomod'],  path: 'gopls', args: ['serve'] },
    \ #{ name: 'clangd', filetype: ['c', 'cpp'], path: 'C:/Program Files/LLVM/bin/clangd', args: ['--background-index'] }
\ ]
autocmd VimEnter * call LspAddServer(lspServers)

"Enable auto selection of the fist autocomplete item"
augroup LspSetup
    au!
    au User LspAttached set completeopt-=noselect
augroup END
"Disable newline on selecting completion option"
inoremap <expr> <CR> pumvisible() ? "\<C-Y>" : "\<CR>"

"Mappings for most-used functions"
nnoremap <leader>i :LspHover<CR>
nnoremap <leader>d :LspGotoDefinition<CR>
nnoremap <leader>p :LspPeekDefinition<CR>
nnoremap <leader>R :LspRename<CR>
nnoremap <leader>r :LspPeekReferences<CR>
nnoremap <leader>o :LspDocumentSymbol<CR>

"--- ALE settings ------------------------------------------------------"
"Disable ALE's LSP in favour of standalone LSP plugin"
let g:ale_disable_lsp = 1

"Show linting errors with highlights"
"* Can also be viewed in the loclist with :lope"
let g:ale_set_signs = 1
let g:ale_set_highlights = 1
let g:ale_virtualtext_cursor = 1
highlight ALEError ctermbg=none cterm=underline

"Define when to lint"
let g:ale_lint_on_save = 1
let g:ale_lint_on_insert_leave = 1
let g:ale_lint_on_text_change = 'never'

"Set linters for individual filetypes"
let g:ale_linters_explicit = 1
let g:ale_linters = {
    \ 'go': ['gofmt', 'gopls', 'govet', 'gobuild'],
\ }
"Specify fixers for individual filetypes"
let g:ale_fixers = {
    \ '*': ['trim_whitespace'],
    \ 'go': ['gopls', 'goimports', 'gofmt', 'gotype', 'govet'],
\ }
"Don't warn about trailing whitespace, as it is auto-fixed by '*' above"
let g:ale_warn_about_trailing_whitespace = 0
"Show info, warnings, and errors; Write which linter produced the message"
let g:ale_lsp_show_message_severity = 'information'
let g:ale_echo_msg_format = '[%linter%] [%severity%:%code%] %s'
"Specify Containerfiles as Dockerfiles"
let g:ale_linter_aliases = {"Containerfile": "dockerfile"}

"Mapping to run fixers on file"
nnoremap <leader>L :ALEFix<CR>

call plug#begin()

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'yegappan/lsp'
Plug 'dense-analysis/ale'

call plug#end()

