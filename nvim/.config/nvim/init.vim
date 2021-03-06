" don't have keys in the plugin for moving lines around
let g:move_map_keys=0
" don't root automatically
let g:rooter_manual_only=1

" configure indent guides
let g:indent_guides_guide_size=1
let g:indent_guides_start_level=2
let g:indent_guides_enable_on_vim_startup=1

set rtp+=~/.fzf

" setup gruvbox theme
let g:gruvbox_contrast_dark='hard'
set background=dark

" add italic support to gruvbox
let g:gruvbox_italic=1

" link jsFuncCall to green
autocmd ColorScheme * highlight link jsFuncCall GruvboxGreen

autocmd ColorScheme * highlight ExtraWhitespace ctermbg=red guibg=red

" only toggle this for neovim
if has('termguicolors')
  " terminal color / italics finagling
  let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

colorscheme gruvbox

" highlight bad whitespace
augroup WhiteSpaceMatch
  autocmd!
  match ExtraWhitespace /\s\+$/
  autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
  autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
  autocmd InsertLeave * match ExtraWhitespace /\s\+$/
  autocmd BufWinLeave * call clearmatches()
augroup end

set packpath+=~/.config/nvim
packloadall

" fix annoying markdown folding
let g:vim_markdown_folding_disabled=1
autocmd FileType markdown set conceallevel=0

" PEP-8
set colorcolumn=79

" highlight line and show numbers
set cursorline number

" allow flickering of pairs
set showmatch matchtime=2

" split to the right side
set splitright
" search ignoring case if all lowercase
set ignorecase smartcase

" show whitespace characters and tabs
set list listchars=trail:•,tab:»\ |

" allow for multiple buffers
set hidden

" default to 2, but some languages do 4
set expandtab tabstop=2 shiftwidth=2 softtabstop=2
autocmd Filetype c setlocal tabstop=4 shiftwidth=4 softtabstop=4
autocmd Filetype cuda setlocal tabstop=4 shiftwidth=4 softtabstop=4
autocmd Filetype cpp setlocal tabstop=4 shiftwidth=4 softtabstop=4 | exe "EditorConfigReload"
autocmd Filetype elm setlocal tabstop=4 shiftwidth=4 softtabstop=4
autocmd Filetype go setlocal noexpandtab tabstop=4 shiftwidth=4 softtabstop=4

" allow for modeline
set modeline

" classic
nnoremap Y y$

augroup ConcealCursor
  autocmd!
  autocmd BufWinEnter * set concealcursor=cn
augroup end

let g:javascript_conceal_function="λ"
set conceallevel=2

augroup AutomaticLocationQuickFixWindow
  autocmd!
  autocmd QuickFixCmdPost [^l]* cwindow
  autocmd QuickFixCmdPost    l* lwindow
augroup end

" better wildmode
set wildmode=list:full

" `gf` suffixes
set suffixesadd+=.ts
set suffixesadd+=.vue
" `gf` opens file under cursor in a new vertical split
nnoremap gf :vertical wincmd f<CR>

" uses amazing incremental command neovim feature if available
if exists("+inccommand")
  set inccommand=nosplit
endif

" moving sanely and creating a mark if too far
nnoremap <expr> j (v:count ? (v:count > 5 ? "m'" . v:count : '') : 'g') . 'j'
nnoremap <expr> k (v:count ? (v:count > 5 ? "m'" . v:count : '') : 'g') . 'k'

let mapleader=' '

" open .vimrc or init.vim
nnoremap <leader>v :e $MYVIMRC

" open at current directory
set wildcharm=<C-z>
" set working directory to the current file
nnoremap <leader>cd :cd %:p:h<CR>

" open one or more lines lines
nnoremap <Leader>o <Cmd>call OpenLines(v:count,0)<CR>S
nnoremap <Leader>O <Cmd>call OpenLines(v:count,-1)<CR>S

" open multiple lines (insert empty lines) before or after current line,
" and position cursor in the new space, with at least one blank line
" before and after the cursor.
function! OpenLines(nrlines, dir)
    let nrlines = a:nrlines < 2 ? 2 : a:nrlines
    let start = line('.') + a:dir
    call append(start, repeat([''], nrlines))
    if a:dir < 0 | exe 'normal! 2k' | else | exe 'normal! 2j' | endif
endfunction

nnoremap <leader>g :Ggrep<space>""<Left>
nnoremap <leader>*g :Ggrep<space>"<C-r>=expand('<cword>')<CR>"<CR>

" git grep
func! GitGrep(...)
  let save = &grepprg
  set grepprg=git\ grep\ -n\ $*\ --\ :/
  let s = 'grep'
  for i in a:000
    let s = s . ' ' . i
  endfor
  exe s
  let &grepprg = save
endfun
command! -nargs=? Ggrep call GitGrep(<f-args>)

nnoremap <leader><leader> :'{,'}s/\<<C-r>=expand('<cword>')<CR>\>/
nnoremap <leader>%       :%s/\<<C-r>=expand('<cword>')<CR>\>/

nnoremap gl :Tabularize /
vnoremap gl :Tabularize /
nnoremap gL :Tabularize /\zs<Left><Left><Left>
vnoremap gL :Tabularize /\zs<Left><Left><Left>

" Call depends on mode
function! MoveE(dir)
  let x = 0
  let count = v:count
  if mode() ==# "V" && count > 0
    " 14k V 4j 4[e --> (count=4 dir=1  v=99 .=103 dif=-4) => 4 - 1 = 3
    " 11k V 4k 8[e --> (count=8 dir=1  v=103 .=99 dif=4) => 8 - + 4 - 1 = 3
    " 16k V 4j 7]e --> (count=7 dir=-1 v=99 .=103 dif=-4) => 7 - + 4 = 3
    " 13k V 4k 3]e --> (count=3 dir=-1 v=103 .=99 dif=4) => 3
    let difa = line("v") - line(".")
    if (difa > 0) == (a:dir > 0)
      let count = count - abs(difa)
    endif
    if a:dir == 1
      let count = count - 1
    endif
  elseif count == 0
    let count = 1
  endif

  while x < count
    if mode() ==# "v" || mode() ==# "\<C-V>"
      " move block
      if a:dir < 0 | exe "normal \<Plug>MoveBlockLeft" | else | exe "normal \<Plug>MoveBlockRight" | endif
    elseif mode() ==# "V"
      " move line
      if a:dir < 0 | exe "normal \<Plug>MoveBlockUp" | else | exe "normal \<Plug>MoveBlockDown" | endif
    else
      " move line
      if a:dir < 0 | exe "normal \<Plug>MoveLineDown" | else | exe "normal \<Plug>MoveLineUp" | endif
    endif
    let x += 1
  endwhile
endfunction

nmap <silent> <Plug>MoveE- <Cmd>call MoveE(-1)<CR>:<C-U>call repeat#set("\<Plug>MoveE-")<CR>
nmap <silent> <Plug>MoveE+  <Cmd>call MoveE(1)<CR>:<C-U>call repeat#set("\<Plug>MoveE+")<CR>
vmap <silent> <Plug>MoveE- <Cmd>call MoveE(-1)<CR>:<C-U>call repeat#set("gv\<Plug>MoveE-")<CR>
vmap <silent> <Plug>MoveE+  <Cmd>call MoveE(1)<CR>:<C-U>call repeat#set("gv\<Plug>MoveE+")<CR>

nmap [e <Plug>MoveE+
nmap ]e <Plug>MoveE-
vmap [e <Plug>MoveE+
vmap ]e <Plug>MoveE-

" relativize only on normal mode, not on insert or out of focus
function! Relativize(v)
    let &relativenumber = a:v
endfunction

augroup Relativize
  autocmd!
  autocmd BufWinEnter,FocusGained,InsertLeave,WinEnter * call Relativize(1)
  autocmd BufWinLeave,FocusLost,InsertEnter,WinLeave * call Relativize(0)
augroup end

" go back to editing the same line as you exited in a file
augroup ReturnToLastEditPosition
    autocmd!
    autocmd BufReadPost *
\     if line("'\"") > 1 && line("'\"") <= line("$") |
\       exe "normal! g`\"" |
\     endif
augroup end

augroup GitCommitNoWhiteSpaceMatch
  autocmd!
  autocmd FileType gitcommit call clearmatches() | autocmd! WhiteSpaceMatch
augroup end

" clear trailing space
command! -range=% TR let b:wv = winsaveview() |
  \ keeppattern <line1>,<line2>s/\s\+$// |
  \ call winrestview(b:wv)
nnoremap <leader>w :<C-U>TR<CR>
nnoremap ]w ?\s\+$<CR>
nnoremap [w /\s\+$<CR>

" Q is quite useless
nnoremap Q @q

" Power to the trailing comma!
let g:splitjoin_trailing_comma = 1

" change current word
nnoremap <silent> <leader>. :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \/<C-R><C-R>=substitute(
  \escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \cgn<C-R>.<esc>:call setreg('"', old_reg, old_regtype)<CR>

" recalculate the trailing whitespace warning when idle, and after saving
autocmd cursorhold,bufwritepost * unlet! b:statusline_trailing_space_warning

" return '•' if trailing white space is detected else ''
function! StatuslineTrailingSpaceWarning()
  " I don't care about trailing space in those
  if &filetype == 'gitcommit'
    return ''
  endif

  if !exists("b:statusline_trailing_space_warning")
    if search('\s\+$', 'nw') != 0
      let b:statusline_trailing_space_warning = '•'
    else
      let b:statusline_trailing_space_warning = ''
    endif
  endif
  return b:statusline_trailing_space_warning
endfunction

" configuring netrw
let g:netrw_liststyle = 3
let g:netrw_banner = 0
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_winsize = 25

set scrolloff=1
set nojoinspaces
set spelllang=en_us,pt_br
set whichwrap=b,s,h,l,s,<,>,[,],~

" Tab in search goes to the next match
set wildcharm=<C-z>
cnoremap <expr> <Tab> getcmdtype() == '/' \|\| getcmdtype() == '?' ? '<CR>/<c-r>/' : '<C-z>'
cnoremap <expr> <S-Tab> getcmdtype() == '/' \|\| getcmdtype() == '?' ? '<CR>/<c-r>/' : '<S-Tab>'

set foldtext=getline(v:foldstart)

" moving between windows with Alt+HJKL
tnoremap <A-h> <C-\><C-N><C-w>h
tnoremap <A-j> <C-\><C-N><C-w>j
tnoremap <A-k> <C-\><C-N><C-w>k
tnoremap <A-l> <C-\><C-N><C-w>l
inoremap <A-h> <C-\><C-N><C-w>h
inoremap <A-j> <C-\><C-N><C-w>j
inoremap <A-k> <C-\><C-N><C-w>k
inoremap <A-l> <C-\><C-N><C-w>l
nnoremap <A-h> <C-w>h
nnoremap <A-j> <C-w>j
nnoremap <A-k> <C-w>k
nnoremap <A-l> <C-w>l

" fix syntax highlighting issues with vue files
autocmd BufRead,BufNewFile *.vue syntax sync fromstart
nnoremap <leader>s :syntax sync fromstart<CR>

" add close hidden buffers command
command! CloseHiddenBuffers call s:CloseHiddenBuffers()
function! s:CloseHiddenBuffers()
  let open_buffers = []

  for i in range(tabpagenr('$'))
    call extend(open_buffers, tabpagebuflist(i + 1))
  endfor

  for num in range(1, bufnr("$") + 1)
    if buflisted(num) && index(open_buffers, num) == -1
      exec "bdelete ".num
    endif
  endfor
endfunction

" start of the statusline
set statusline=\ "
" tail of the filename
set statusline+=%n\ %t
" file encoding (not utf-8 or blank)
set statusline+=%{&fenc!='utf-8'&&strlen(&fenc)?'['.&fenc.']':''}
" line endings (not unix)
set statusline+=%{&ff!='unix'?'['.&ff.']':''}
" modified flag
set statusline+=%2*%{&modified?'*':''}%*
" show whitespace warning
set statusline+=%1*%{StatuslineTrailingSpaceWarning()}%*
" modifiable/read only flag
set statusline+=%3*%{&readonly?(&modifiable?'-':'!'):(&modifiable?'':'!')}%*
" left/right separator
set statusline+=%=
" line:column of the cursor
set statusline+=%l:%c
" percentage of the file
set statusline+=\ %p%%%{'\ '}

" autoexpansion
inoremap (<CR> (<CR>)<Esc>O
inoremap {<CR> {<CR>}<Esc>O
inoremap {; {<CR>};<Esc>O
inoremap {, {<CR>},<Esc>O
inoremap [<CR> [<CR>]<Esc>O
inoremap [; [<CR>];<Esc>O
inoremap [, [<CR>],<Esc>O

" close HTML tag
iabbrev </ </<C-X><C-O>

" :[range]SortGroup[!] [n|f|o|b|x] /{pattern}/
" e.g. :SortGroup /^header/
" e.g. :SortGroup n /^header/
" See :h :sort for details
function! s:sort_by_header(bang, pat) range
  let pat = a:pat
  let opts = ""
  if pat =~ '^\s*[nfxbo]\s'
    let opts = matchstr(pat, '^\s*\zs[nfxbo]')
    let pat = matchstr(pat, '^\s*[nfxbo]\s*\zs.*')
  endif
  let pat = substitute(pat, '^\s*', '', '')
  let pat = substitute(pat, '\s*$', '', '')
  let sep = '/'
  if len(pat) > 0 && pat[0] == matchstr(pat, '.$') && pat[0] =~ '\W'
    let [sep, pat] = [pat[0], pat[1:-2]]
  endif
  if pat == ''
    let pat = @/
  endif

  let ranges = []
  execute a:firstline . ',' . a:lastline . 'g' . sep . pat . sep . 'call add(ranges, line("."))'

  let converters = {
    \ 'n': {s-> str2nr(matchstr(s, '-\?\d\+.*'))},
    \ 'x': {s-> str2nr(matchstr(s, '-\?\%(0[xX]\)\?\x\+.*'), 16)},
    \ 'o': {s-> str2nr(matchstr(s, '-\?\%(0\)\?\x\+.*'), 8)},
    \ 'b': {s-> str2nr(matchstr(s, '-\?\%(0[bB]\)\?\x\+.*'), 2)},
    \ 'f': {s-> str2float(matchstr(s, '-\?\d\+.*'))},
    \ }
  let arr = []
  for i in range(len(ranges))
    let end = max([get(ranges, i+1, a:lastline+1) - 1, ranges[i]])
    let line = getline(ranges[i])
    let d = {}
    let d.key = call(get(converters, opts, {s->s}), [strpart(line, match(line, pat))])
    let d.group = getline(ranges[i], end)
    call add(arr, d)
  endfor
  call sort(arr, {a,b -> a.key == b.key ? 0 : (a.key < b.key ? -1 : 1)})
  if a:bang
    call reverse(arr)
  endif
  let lines = []
  call map(arr, 'extend(lines, v:val.group)')
  let start = max([a:firstline, get(ranges, 0, 0)])
  call setline(start, lines)
  call setpos("'[", start)
  call setpos("']", start+len(lines)-1)
endfunction
command! -range=% -bang -nargs=+ SortGroup <line1>,<line2>call <SID>sort_by_header(<bang>0, <q-args>)

let g:previm_open_cmd = 'xdg-open'

" fzf mapping
nnoremap <C-P> :execute ":FZF " . FindRootDirectory()<CR>

let g:vim_markdown_fenced_languages = ['c++=cpp', 'viml=vim', 'bash=sh', 'ini=dosini', 'js=javascript']

" magically format/minify json in the current buffer
nnoremap <leader>j :%!jq '.'<CR>
nnoremap <leader>J :%!jq -c '.'<CR>
" or just the current visual selection
vnoremap <leader>j :!jq '.'<CR>
vnoremap <leader>J :!jq -c '.'<CR>

let g:os = substitute(system('uname'), '\n', '', '')
if g:os == 'Linux'
  nnoremap <Space>y "+y
  vnoremap <Space>y "+y
  nnoremap <Space>d "+d
  vnoremap <Space>d "+d
  nnoremap <Space>p "+p
  vnoremap <Space>p "+p
  nnoremap <Space>P "+P
  vnoremap <Space>P "+P
else
  nnoremap <Space>y "*y
  vnoremap <Space>y "*y
  nnoremap <Space>d "*d
  vnoremap <Space>d "*d
  nnoremap <Space>p "*p
  vnoremap <Space>p "*p
  nnoremap <Space>P "*P
  vnoremap <Space>P "*P
endif

inoremap <C-l> <Esc>
noremap! <silent> <C-l> <Esc>
vnoremap <silent> <C-l> <Esc>
onoremap <silent> <C-l> <Esc>
cnoremap <silent> <C-l> <C-c>
tnoremap <silent> <C-l> <Esc>

set shortmess+=c

" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

nmap <silent> <leader>a :<C-u>CocCommand actions.open<CR>
