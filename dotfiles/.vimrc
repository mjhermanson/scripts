set paste
set background=dark
set ignorecase
set smarttab

" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4


""""""""""""""""""""""""""""""
" => Status line
""""""""""""""""""""""""""""""
" Always show the status line
set laststatus=2

" Format the status line
set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l

" Pressing ,ss will toggle and untoggle spell checking
map <leader>ss :setlocal spell!<cr>

function! HasPaste()
    if &paste
        return 'PASTE MODE  '
    en
    return ''
endfunction
